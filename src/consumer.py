"""
consumer.py — Kafka Consumer for Landed Cost Pipeline
Subscribes to the 'shipments' Kafka topic and inserts each message
into staging.raw_shipments in PostgreSQL.

Runs until manually stopped (Ctrl+C). Designed for at-least-once delivery.

Usage:
    python ingestion/consumer.py
    python ingestion/consumer.py --group my-group --reset earliest
"""

import argparse
import json
import os
import signal

from dotenv import load_dotenv
from kafka import KafkaConsumer
from kafka.errors import KafkaError

# Re-use the shared DB helpers — no raw psycopg2 here
from src.utils.db import get_connection

load_dotenv()

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "shipments")

# Columns in staging.raw_shipments that map to JSON keys
INSERT_COLUMNS = [
    "kafka_offset", "kafka_partition",
    "shipment_id", "shipment_date", "ingestion_timestamp",
    "origin_country", "port_of_discharge", "port_operator",
    "incoterm", "importer_name", "importer_tin",
    "hs_code", "commodity_description", "hs_category",
    "quantity", "unit_of_measure", "unit_price_usd", "item_cost_usd",
    "gross_weight_mt", "freight_cost_usd", "cif_value_usd",
    "insurance_usd", "dutiable_value_usd", "duty_rate",
    "customs_duty_usd", "vat_usd", "arrastre_usd", "wharfage_usd",
    "other_fees_usd", "landed_cost_usd", "exchange_rate_php",
    "landed_cost_php", "cost_ratio", "is_anomaly", "data_source",
]

INSERT_SQL = f"""
    INSERT INTO staging.raw_shipments ({", ".join(INSERT_COLUMNS)})
    VALUES ({", ".join(["%s"] * len(INSERT_COLUMNS))})
    ON CONFLICT (shipment_id) DO NOTHING
"""

running = True


def signal_handler(sig, frame):
    global running
    print("\n[consumer] Shutdown signal received — draining and closing...")
    running = False


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


def build_consumer(group_id: str, auto_offset_reset: str) -> KafkaConsumer:
    return KafkaConsumer(
        TOPIC,
        bootstrap_servers=BOOTSTRAP_SERVERS,
        group_id=group_id,
        auto_offset_reset=auto_offset_reset,
        enable_auto_commit=False,
        value_deserializer=lambda m: json.loads(m.decode("utf-8")),
        consumer_timeout_ms=5000,
        max_poll_records=100,
    )


def record_to_row(msg) -> tuple:
    data = msg.value
    return tuple(
        [msg.offset, msg.partition]
        + [data.get(col) for col in INSERT_COLUMNS[2:]]
    )


def consume(group_id: str, auto_offset_reset: str) -> None:
    global running

    consumer = build_consumer(group_id, auto_offset_reset)

    print(f"Connected to Kafka at {BOOTSTRAP_SERVERS}")
    print(f"Subscribed to topic  : {TOPIC}")
    print(f"Consumer group       : {group_id}")
    print(f"Offset reset policy  : {auto_offset_reset}")
    print(f"Writing to           : staging.raw_shipments")
    print("-" * 55)
    print("Listening for messages... (Ctrl+C to stop)")

    total = 0
    errors = 0

    while running:
        try:
            for msg in consumer:
                if not running:
                    break

                try:
                    row = record_to_row(msg)

                    # ── use db.py's context manager; auto-commits on exit ──
                    with get_connection() as conn:
                        with conn.cursor() as cursor:
                            cursor.execute(INSERT_SQL, row)
                    # ── Kafka offset committed only after a successful DB write ──
                    consumer.commit()

                    total += 1
                    if total % 500 == 0:
                        print(
                            f"  Consumed {total:,} records "
                            f"(offset={msg.offset}, partition={msg.partition})"
                        )

                except Exception as exc:
                    # get_connection() already rolls back on error
                    errors += 1
                    print(f"  [ERROR] offset={msg.offset}: {exc}")

        except KafkaError as ke:
            if running:
                print(f"  [KAFKA ERROR] {ke}")

    consumer.close()
    print("-" * 55)
    print(f"Consumer stopped. Total consumed: {total:,}  |  Errors: {errors}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Kafka consumer — writes shipment messages to PostgreSQL staging."
    )
    parser.add_argument(
        "--group",
        type=str,
        default="landed-cost-consumer-group",
        help="Kafka consumer group ID.",
    )
    parser.add_argument(
        "--reset",
        type=str,
        default="earliest",
        choices=["earliest", "latest"],
        help="Auto offset reset policy (default: earliest).",
    )
    args = parser.parse_args()
    consume(args.group, args.reset)


if __name__ == "__main__":
    main()
