import os
import random
from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.sensors.time_delta import TimeDeltaSensor
from airflow.sdk.execution_time.xcom import XCom
from datetime import datetime, timedelta

from src.generate import generate_data
from src.producer import produce_to_kafka


DEFAULT_ARGS = {
    "owner": "iki_data_engineer",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "start_date": datetime(2026, 5, 1),
}

PIPELINE_ROOT = "/opt/airflow"
DATA_DIR = f"{PIPELINE_ROOT}/data"
DBT_DIR = f"{PIPELINE_ROOT}/dbt"

DBT_ENV = {
    **os.environ,
    "POSTGRES_HOST":     os.getenv("POSTGRES_HOST",     "postgres"),
    "POSTGRES_PORT":     os.getenv("POSTGRES_PORT",     "5432"),
    "POSTGRES_DB":       os.getenv("PIPELINE_DB_NAME",  "landed_cost_db"),
    "POSTGRES_USER":     os.getenv("POSTGRES_USER",     "landed_cost_user"),
    "POSTGRES_PASSWORD": os.getenv("POSTGRES_PASSWORD", "landed_cost_password"),
}


def task_generate_data(**context) -> str:
    record_count = random.randint(1_000, 5_000)
    context["ti"].xcom_push(key="record_count", value=record_count)
    print(f"[generate_data] record_count={record_count}")

    output_path = generate_data(records=record_count)
    context["ti"].xcom_push(key="generated_file", value=str(output_path))
    return str(output_path)


def task_produce_to_kafka(**context) -> None:
    file_path = context["ti"].xcom_pull(
        task_ids="generate_data", key="generated_file"
    )
    produce_to_kafka(file_path=file_path, delay=0.01)


def task_clear_xcom(**context):
    dag_id = context["dag"].dag_id
    run_id = context["run_id"]

    # Delete specific keys pushed by generate_data
    for key in ["generated_file", "record_count"]:
        XCom.delete(
            key=key,
            task_id="generate_data",
            dag_id=dag_id,
            run_id=run_id,
        )
    print(f"[clear_xcom] Cleared XCom for run_id={run_id}")


with DAG(
    dag_id="landed_cost_pipeline",
    description="Philippine import landed cost ELT pipeline",
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    max_active_runs=1,
    tags=["landed-cost", "portfolio", "data-engineering"],
) as dag:

    generate_data_task = PythonOperator(
        task_id="generate_data",
        python_callable=task_generate_data,
        retries=1,
        retry_delay=timedelta(seconds=10),
        doc_md=(
            "Generates a random number of synthetic Philippine import shipment "
            "records as JSONL. Record count is decided at runtime and pushed to "
            "XCom so downstream tasks see the same value."
        ),
    )

    produce_to_kafka_task = PythonOperator(
        task_id="produce_to_kafka",
        python_callable=task_produce_to_kafka,
        retries=0,  # no retries — prevents double-publishing to Kafka
        doc_md=(
            "Reads the generated JSONL file path from XCom and publishes "
            "each record to the **shipments** Kafka topic at ~100 msg/s. "
            "Retries disabled — a partial send would re-publish already-sent "
            "messages. Fix root cause and re-trigger manually if this fails. "
            "The always-on `consumer.py` process picks these up and writes "
            "them into `staging.raw_shipments`."
        ),
    )

    wait_consumer = TimeDeltaSensor(
        task_id="wait_consumer",
        delta=timedelta(seconds=60),
        deferrable=True,
        doc_md=(
            "Waits 60 seconds after the producer finishes to allow the "
            "always-on Kafka consumer to flush all messages into "
            "`staging.raw_shipments` before dbt models run."
        ),
    )

    dbt_init = BashOperator(
        task_id="dbt_init",
        bash_command=f"cd {DBT_DIR} && dbt deps --profiles-dir .",
        env=DBT_ENV,
    )

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"cd {DBT_DIR} && dbt seed --profiles-dir . --select hs_codes port_fees",
        env=DBT_ENV,
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"""
            cd {DBT_DIR} && \
            dbt run --profiles-dir . --select staging+ intermediate+ marts+ --no-partial-parse
        """,
        env=DBT_ENV,
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_DIR} && dbt test --profiles-dir .",
        env=DBT_ENV,
    )

    clear_xcom_task = PythonOperator(
        task_id="clear_xcom",
        python_callable=task_clear_xcom,
    )

    generate_data_task >> produce_to_kafka_task >> wait_consumer >> dbt_init >> dbt_seed >> dbt_run >> dbt_test >> clear_xcom_task
