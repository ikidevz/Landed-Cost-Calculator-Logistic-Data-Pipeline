# Landed Cost Calculator — Philippine Import Logistics Data Pipeline

A production-grade data engineering pipeline that orchestrates the collection, transformation, and analysis of Philippine import shipment data, calculating landed costs including tariffs, duties, VAT, and port fees using Apache Airflow, Kafka, PostgreSQL, and dbt.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Technologies Stack](#technologies-stack)
- [System Components](#system-components)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup & Installation](#setup--installation)
- [Running the Pipeline](#running-the-pipeline)
- [Data Model](#data-model)
- [Analytics & Dashboard](#analytics--dashboard)
- [Monitoring & Health Checks](#monitoring--health-checks)
- [Database Connections](#database-connections)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## 📊 Overview

The **Landed Cost Calculator** is a comprehensive data pipeline designed to support import logistics operations in the Philippines. It simulates real-world import scenarios, calculates landed costs with proper tariff codes (HS codes), and provides analytics via Metabase dashboards.

### Business Context

**Landed Cost** = Item Cost + Freight + Insurance + Customs Duty + VAT + Port Fees (Arrastre + Wharfage + Other)

This pipeline automates:

- **Synthetic data generation** of Philippine import shipments
- **Real-time streaming** via Kafka
- **Data transformation** using dbt (data build tool)
- **Analytics query layer** for cost breakdowns, anomaly detection, and performance monitoring
- **Visual dashboards** for stakeholders (Metabase)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      LANDING ZONE (Kafka)                          │
│  Raw shipment events from broker → Consumer writes staging tables  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    TRANSFORMATION LAYER (dbt)                       │
│  Staging → Intermediate → Marts (dimensional & fact tables)        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   ANALYTICS & REPORTING (Metabase)                 │
│  KPI cards, time series, cost breakdowns, anomaly detection        │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Airflow DAG** (`orchestrator_dag.py`) triggers daily
2. **Generate** synthetic shipment records (1,000–5,000 per run) → JSONL
3. **Produce** to Kafka topic `shipments`
4. **Consumer** (`consumer.py`) consumes messages → `staging.raw_shipments`
5. **dbt** transforms raw → staging → intermediate → marts
6. **Metabase** queries mart tables for visualization

---

## ✨ Key Features

- **Synthetic Data Generation**: Realistic Philippine import scenarios with randomized volumes
- **Real-Time Streaming**: Kafka-based event ingestion at ~100 messages/second
- **Cost Calculation**: Automatic computation of duties, VAT, and port fees based on HS code and origin
- **Anomaly Detection**: Flags shipments where landed cost ≥ 2× item cost
- **Multi-Currency**: Handles USD and PHP conversions
- **dbt Lineage**: Full documentation of data transformations
- **Dashboard-Ready Analytics**: Pre-built SQL queries for KPIs and trends
- **Docker Orchestration**: Complete containerized environment

---

## 🛠️ Technologies Stack

| Component            | Technology             | Version | Purpose                                |
| -------------------- | ---------------------- | ------- | -------------------------------------- |
| **Orchestration**    | Apache Airflow         | 3.2.1   | DAG scheduling & task management       |
| **Execution**        | CeleryExecutor + Redis | 7.2     | Distributed task execution             |
| **Message Broker**   | Apache Kafka           | 7.4.0   | Real-time event streaming              |
| **Data Warehouse**   | PostgreSQL             | 16      | Primary data repository                |
| **Transformation**   | dbt (data build tool)  | Latest  | SQL-based transformation orchestration |
| **Visualization**    | Metabase               | Latest  | Self-service analytics & dashboards    |
| **Database Admin**   | pgAdmin 4              | Latest  | PostgreSQL management UI               |
| **Runtime**          | Python                 | 3.12    | Data generation & ingestion            |
| **Containerization** | Docker Compose         | Latest  | Infrastructure as code                 |

---

## 🔧 System Components

### 1. **Airflow**

- **API Server** (port 8080): REST API + execution server
- **Scheduler**: Processes DAGs and queues tasks
- **Worker**: Executes tasks (Celery)
- **Triggerer**: Manages async operators
- **DAG Processor**: Parses DAG definitions

### 2. **Kafka Ecosystem**

- **Broker**: `kafka:9092` (internal), `localhost:9092` (external)
- **Zookeeper**: Coordination & leader election
- **Topics**: `shipments` (1 partition, 1 replication factor)

### 3. **PostgreSQL Databases**

- **airflow**: Airflow metadata (DAGs, runs, logs)
- **landed_cost_db**: Analytics warehouse (schemas: staging, seeds, marts)
- **metabase_db**: Metabase configuration

### 4. **dbt Project** (`/dbt`)

- **Seeds**: Reference data (HS codes, port fees)
- **Staging Models**: Raw data cleaning (`stg_shipments`)
- **Marts**: Fact tables (`fct_landed_cost`)
- **Tests & Documentation**: Data quality validation

### 5. **Python Services**

- **generate.py**: Creates synthetic shipment records
- **producer.py**: Publishes records to Kafka
- **consumer.py**: Consumes & writes to PostgreSQL
- **utilities**: DB helpers, logging

### 6. **Metabase**

- **Configuration**: Via docker-compose + setup script
- **Dashboards**: Pre-configured or user-defined

---

## 📁 Project Structure

```
Landed Cost Calculator/
├── docker-compose.yml           # Full stack orchestration
├── Dockerfile.airflow           # Custom Airflow image
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables (sensitive data)
├── Analytics.txt                # Reference SQL queries for dashboards
│
├── dags/
│   ├── orchestrator_dag.py      # Main ELT pipeline DAG
│   └── src/                     # Shared Airflow code
│
├── src/                         # Core Python modules
│   ├── generate.py              # Synthetic data generator
│   ├── producer.py              # Kafka producer
│   ├── consumer.py              # Kafka consumer + DB writer
│   └── utils/
│       ├── db.py                # Database connection pooling
│       └── logger.py            # Logging utilities
│
├── dbt/                         # Data transformation project
│   ├── dbt_project.yml          # dbt configuration
│   ├── profiles.yml             # Database connection profile
│   ├── packages.yml             # dbt dependencies
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_shipments.sql
│   │   │   └── src_staging.yml  # Data source documentation
│   │   ├── intermediate/        # Conformed dimensions
│   │   └── marts/
│   │       └── fct_landed_cost.sql  # Core fact table
│   ├── seeds/                   # Reference data
│   │   ├── hs_codes.csv
│   │   └── port_fees.csv
│   ├── macros/                  # Custom dbt functions
│   ├── analyses/                # Ad-hoc analytical queries
│   └── tests/                   # dbt tests
│
├── config/
│   ├── airflow.cfg              # Airflow configuration
│   ├── setup_conn.py            # Airflow connection setup
│   ├── pgadmin/
│   │   ├── servers.json         # pgAdmin server config
│   │   └── pgpass               # PostgreSQL credentials
│   └── metabase/
│       └── setup.sh             # Metabase initialization script
│
├── init-scripts/                # Database initialization
│   ├── 00_create_all_databases.sql
│   ├── 01_create_schemas.sql
│   ├── 02_seeds_tables.sql
│   ├── 03_staging_tables.sql
│   ├── 04_views_tables.sql
│   ├── 05_indexes.sql
│   └── 06_comments.sql
│
├── plugins/                     # Airflow plugins (custom operators)
├── logs/                        # Airflow task logs
├── data/                        # Generated shipment data (JSONL)
│
└── README.md                    # This file
```

---

## 📦 Prerequisites

- **Docker & Docker Compose** (v20.10+)
- **Python 3.9+** (for local development)
- **Git**
- **At least 4GB RAM** and **10GB disk space**
- **PostgreSQL client tools** (optional, for direct queries)

### Supported Operating Systems

- Linux (recommended)
- macOS
- Windows (WSL2 recommended)

---

## 🚀 Setup & Installation

### Step 1: Clone & Navigate

```bash
cd "Data Engineering/Landed Cost Calculator"
```

### Step 2: Configure Environment

Copy and customize the `.env` file:

```bash
cp .env .env.local  # Optional: for local overrides
```

Key environment variables:

```env
POSTGRES_USER=landed_cost_user
POSTGRES_PASSWORD=landed_cost_password
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
PIPELINE_DB_NAME=landed_cost_db

KAFKA_BOOTSTRAP_SERVERS=kafka:9092
KAFKA_TOPIC=shipments

METABASE_PORT=3000

AIRFLOW_UID=50000
_AIRFLOW_WWW_USER_USERNAME=airflow
_AIRFLOW_WWW_USER_PASSWORD=airflow
```

### Step 3: Initialize Docker Volumes (First Time Only)

```bash
# Create necessary directories
mkdir -p logs data config/pgadmin

# Build custom Airflow image
docker-compose build
```

### Step 4: Start All Services

```bash
docker-compose up -d
```

This starts (in order):

1. PostgreSQL database
2. Redis cache
3. Zookeeper & Kafka
4. Airflow components (scheduler, worker, API server)
5. Kafka consumer service
6. Metabase analytics

### Step 5: Initialize Airflow

```bash
# Wait ~30 seconds for containers to stabilize
sleep 30

# Trigger airflow initialization (already run automatically via airflow-init service)
docker-compose exec airflow-scheduler airflow db init
```

### Step 6: Access Services

| Service        | URL                   | Credentials                |
| -------------- | --------------------- | -------------------------- |
| **Airflow UI** | http://localhost:8080 | airflow / airflow          |
| **pgAdmin**    | http://localhost:5050 | admin@admin.com / admin123 |
| **Metabase**   | http://localhost:3000 | Setup on first visit       |
| **Kafka UI**   | _(Optional)_          | —                          |

---

## ▶️ Running the Pipeline

### Manual Trigger (Airflow UI)

1. Open **Airflow UI** → http://localhost:8080
2. Locate DAG: `landed_cost_pipeline`
3. Click **Trigger DAG** button
4. Monitor task execution in the DAG view

### Manual Trigger (CLI)

```bash
# From host machine
docker-compose exec airflow-scheduler \
  airflow dags trigger landed_cost_pipeline
```

### Automated Scheduling

By default, the DAG is scheduled to run based on `schedule=None` (manual only). To enable daily runs:

```bash
# Edit dags/orchestrator_dag.py and change:
# schedule=None  →  schedule="@daily"
# Then restart Airflow
docker-compose restart airflow-scheduler
```

### Monitor Data Flow

```bash
# View raw shipments in PostgreSQL
docker-compose exec postgres psql -U landed_cost_user -d landed_cost_db \
  -c "SELECT COUNT(*) FROM staging.raw_shipments;"

# Check Kafka topic
docker-compose exec kafka kafka-topics --list --bootstrap-server kafka:9092

# View consumer lag
docker-compose exec kafka kafka-consumer-groups \
  --bootstrap-server kafka:9092 --group shipments-consumer --describe
```

### dbt Transformations

```bash
# Build all models
docker-compose exec airflow-scheduler \
  dbt build -d --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt

# Run specific model
docker-compose exec airflow-scheduler \
  dbt run -d -s stg_shipments --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt

# Test data quality
docker-compose exec airflow-scheduler \
  dbt test --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt
```

---

## 📊 Data Model

### Schemas

| Schema      | Purpose                                 | Type        |
| ----------- | --------------------------------------- | ----------- |
| **staging** | Raw & lightly cleaned data              | Transient   |
| **seeds**   | Reference tables (lookups)              | Static      |
| **marts**   | Analytics-ready fact & dimension tables | Star schema |

### Key Tables

#### `staging.raw_shipments` (Source)

Real-time ingestion point from Kafka. Columns:

- `shipment_id`, `shipment_date`, `ingestion_timestamp`
- Importer details: `importer_name`, `importer_tin`
- Route: `origin_country`, `port_of_discharge`, `port_operator`, `incoterm`
- HS Classification: `hs_code`, `commodity_description`, `hs_category`
- Quantities: `quantity`, `unit_of_measure`, `gross_weight_mt`
- Pricing: `unit_price_usd`, `item_cost_usd`, `freight_cost_usd`, `cif_value_usd`
- Regulatory: `duty_rate`, `customs_duty_usd`, `vat_usd`
- Port Charges: `arrastre_usd`, `wharfage_usd`, `other_fees_usd`
- Calculations: `landed_cost_usd`, `landed_cost_php`, `cost_ratio`, `is_anomaly`

#### `staging.stg_shipments` (Transformed)

Cleaned & deduplicated version with lookups applied.

#### `marts.fct_landed_cost` (Analytics)

Fact table optimized for analysis:

- Pre-calculated cost components and percentages
- Currency conversion applied
- Anomaly flags for outlier detection
- Indexed on `shipment_date`, `hs_category`, `port_of_discharge`

#### `seeds.hs_codes` (Reference)

HS code reference data:

- `hs_code`, `description`, `category`, `duty_rate`, `cmta_chapter`
- ~100+ codes covering Electronics, Apparel, Automotive, Food, Chemicals, Steel, etc.

#### `seeds.port_fees` (Reference)

Philippine port fees by operator:

- `port_name`, `port_operator`
- Rates: `arrastre_rate_php`, `wharfage_rate_php`, `reference_rate_usd`

### Relationships

```
fct_landed_cost (fact)
├── hs_codes (reference via hs_code)
├── port_fees (reference via port_operator)
└── shipment_dates (implicit)
```

---

## 📈 Analytics & Dashboard

### Pre-Built KPI Queries (See `Analytics.txt`)

#### KPI Cards (Summary Metrics)

- **KPI-01**: Total Shipments Processed
- **KPI-02**: Average Landed Cost (USD)
- **KPI-03**: Total Landed Cost Portfolio Value
- **KPI-04**: Average Duty Rate (%)
- **KPI-05**: Total Customs Duty Collected
- **KPI-06**: Total VAT Collected
- **KPI-07**: Anomaly Rate (shipments with unusual cost ratios)
- **KPI-08**: Avg Freight as % of Landed Cost

#### Time Series Analysis

- Monthly shipment volume & trend
- Duty & VAT collection over time
- Duty rate by HS category
- Gross weight trends

#### Cost Breakdown Analysis

- Pie chart: Cost components (Item → Landed Cost)
- Bar chart: Average cost by HS category
- Stacked area: Duty + VAT + Port fees trends

### Metabase Dashboard Setup

1. **Login** to Metabase (http://localhost:3000)
2. **Add Database Connection**:
   - Type: PostgreSQL
   - Host: `postgres`
   - Port: `5432`
   - Database: `landed_cost_db`
   - User: `landed_cost_user`
   - Password: `landed_cost_password`
3. **Create Questions** using SQL from `Analytics.txt`
4. **Build Dashboard** by combining questions

### Example Query: Top Import Categories by Volume

```sql
SELECT
    hs_category,
    COUNT(*) AS shipment_count,
    ROUND(AVG(landed_cost_usd)::NUMERIC, 2) AS avg_landed_cost_usd,
    ROUND(SUM(quantity)::NUMERIC, 0) AS total_quantity,
    ROUND(SUM(gross_weight_mt)::NUMERIC, 2) AS total_weight_mt
FROM marts.fct_landed_cost
GROUP BY hs_category
ORDER BY shipment_count DESC
LIMIT 10;
```

---

## 🔍 Monitoring & Health Checks

### Service Health

```bash
# Check all services
docker-compose ps

# View service logs
docker-compose logs -f airflow-scheduler   # Airflow
docker-compose logs -f kafka-consumer      # Kafka Consumer
docker-compose logs -f postgres            # PostgreSQL
```

### Common Health Checks

**Airflow Scheduler Health**

```bash
curl http://localhost:8974/health
```

**API Server Health**

```bash
curl http://localhost:8080/api/v2/monitor/health
```

**PostgreSQL Connectivity**

```bash
docker-compose exec postgres psql -U landed_cost_user -d landed_cost_db \
  -c "SELECT version();"
```

**Kafka Broker**

```bash
docker-compose exec kafka kafka-broker-api-versions --bootstrap-server kafka:9092
```

### Performance Metrics

**Database Query Performance**

```sql
-- Slow query log
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 5;
```

**DAG Execution Time**
Monitor in Airflow UI → Graph/Tree view → task duration

**Kafka Consumer Lag**

```bash
docker-compose exec kafka kafka-consumer-groups \
  --bootstrap-server kafka:9092 --group shipments-consumer --describe
```

---

## 🔌 Database Connections

### Connection String Format

**PostgreSQL (URI)**

```
postgresql+psycopg2://landed_cost_user:landed_cost_password@postgres:5432/landed_cost_db
```

**Airflow Connections** (configured in `config/setup_conn.py`)

- `postgres_connection`: Main warehouse
- `kafka_default`: Kafka broker (if using Airflow Kafka operators)

### pgAdmin Access

1. Navigate to http://localhost:5050
2. Login: `admin@admin.com` / `admin123`
3. Servers → (Pre-configured) → Right-click → Connect
4. Database credentials auto-filled from `config/pgadmin/servers.json`

### Direct psql Access

```bash
# From host (requires psql client)
PGPASSWORD=landed_cost_password psql -h localhost -U landed_cost_user \
  -d landed_cost_db -c "SELECT * FROM marts.fct_landed_cost LIMIT 5;"

# From container
docker-compose exec postgres psql -U landed_cost_user -d landed_cost_db
```

---

## 🐛 Troubleshooting

### Issue: Containers fail to start

**Solution:**

```bash
# Clean and rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Issue: Airflow workers not picking up tasks

**Cause:** CeleryExecutor not properly initialized

**Solution:**

```bash
# Restart Redis and workers
docker-compose restart redis airflow-worker airflow-scheduler
docker-compose logs airflow-worker  # Check for errors
```

### Issue: Kafka consumer not consuming messages

**Cause:** Consumer group offset issue or broker misconfiguration

**Solution:**

```bash
# Reset consumer group offset
docker-compose exec kafka kafka-consumer-groups \
  --bootstrap-server kafka:9092 --group shipments-consumer --reset-offsets \
  --to-earliest --execute --topic shipments

# Restart consumer
docker-compose restart kafka-consumer
```

### Issue: dbt models fail to run

**Cause:** Missing environment variables or incorrect database connection

**Solution:**

```bash
# Verify dbt profiles
docker-compose exec airflow-scheduler \
  dbt debug --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt

# Check .env file
cat .env | grep POSTGRES
```

### Issue: Out of memory / Disk space

**Solution:**

```bash
# Prune unused Docker data
docker system prune -a --volumes

# Check logs volume
du -sh logs/

# Clear old logs
rm -rf logs/dag_processor_manager/* logs/scheduler/*
```

### Issue: Metabase cannot connect to database

**Cause:** Firewall or network connectivity

**Solution:**

1. Verify container network: `docker network ls`
2. Test from Metabase container:
   ```bash
   docker-compose exec metabase pg_isready -h postgres -p 5432
   ```
3. Check PostgreSQL is listening:
   ```bash
   docker-compose exec postgres netstat -tlnp | grep 5432
   ```

---

## 📝 Development Guide

### Adding a New Data Source

1. **Update `src/generate.py`**:
   - Add new HS codes or modify seed data
   - Update `generate_data()` to include new fields

2. **Update Kafka consumer** (`src/consumer.py`):
   - Add new columns to `INSERT_COLUMNS`
   - Update `record_to_row()` mapping

3. **Add staging table** (`dbt/models/staging/stg_shipments.sql`):
   - Include new column transformations
   - Add tests in `src_staging.yml`

4. **Trigger pipeline**:
   ```bash
   docker-compose exec airflow-scheduler airflow dags trigger landed_cost_pipeline
   ```

### Adding a New Dimension Table

1. Create model in `dbt/models/marts/dim_*.sql`
2. Reference in `fct_landed_cost.sql`
3. Test & document:
   ```bash
   dbt test -s dim_*
   dbt docs generate
   ```

### Running dbt Locally

```bash
# Install dbt
pip install dbt-postgres

# Configure profiles
cd dbt
cp profiles.yml ~/.dbt/profiles.yml
# Edit profiles.yml with local credentials

# Run
dbt run
```

---

## 📊 Key Metrics & SLAs

| Metric                 | Target         | Purpose                                |
| ---------------------- | -------------- | -------------------------------------- |
| **Pipeline Latency**   | < 5 min        | End-to-end (generate → Metabase ready) |
| **Kafka Consumer Lag** | < 100 messages | Real-time responsiveness               |
| **Data Quality**       | 99.5%          | Validated by dbt tests                 |
| **Availability**       | 99%            | Uptime SLA                             |
| **Query P95 Latency**  | < 2s           | Analytics responsiveness               |

---

## 🔒 Security Notes

⚠️ **Important:** This setup is for **development/demo only**.

For production:

1. **Secrets Management**: Use HashiCorp Vault or AWS Secrets Manager
2. **Network Segmentation**: Place databases in private VPC
3. **Authentication**: Enable Kerberos or LDAP for Airflow
4. **Encryption**: Enable SSL/TLS for all connections
5. **Access Control**: Implement RBAC via Airflow's FAB auth manager
6. **Audit Logging**: Enable and monitor all database & application logs
7. **Data Masking**: Implement PII masking in dev/test environments

---

## 🤝 Contributing

### Code Style

- **Python**: PEP 8 (use `black` or `flake8`)
- **SQL**: Uppercase keywords, lowercase identifiers
- **dbt**: Follow dbt best practices (naming, tests, documentation)

### Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes & test locally
3. Commit with descriptive messages: `git commit -m "Add new transformation for X"`
4. Push & create pull request
5. Merge after review

### Testing

```bash
# Python unit tests
pytest src/tests/

# dbt data quality tests
dbt test

# Integration tests
docker-compose exec airflow-scheduler airflow dags test landed_cost_pipeline
```

---

## 📚 References & Documentation

- **Apache Airflow**: https://airflow.apache.org/docs/
- **dbt Docs**: https://docs.getdbt.com/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Kafka**: https://kafka.apache.org/documentation/
- **Metabase**: https://www.metabase.com/docs/
- **Philippine HS Code Reference**: http://www.bureau-of-customs.gov.ph/

---

## 📞 Support

For issues or questions:

1. Check **Troubleshooting** section above
2. Review **Airflow Logs**: `docker-compose logs -f airflow-scheduler`
3. Check **Database Logs**: `docker-compose logs -f postgres`
4. Review **Kafka Consumer Logs**: `docker-compose logs -f kafka-consumer`

---

## 📄 License

This project is part of a portfolio data engineering collection.

---

## ✅ Checklist for First-Time Setup

- [ ] Docker & Docker Compose installed
- [ ] 4+ GB RAM available
- [ ] 10+ GB disk space available
- [ ] Cloned repository
- [ ] `.env` file configured
- [ ] `docker-compose build` completed
- [ ] `docker-compose up -d` started successfully
- [ ] Airflow UI accessible (http://localhost:8080)
- [ ] DAG `landed_cost_pipeline` visible
- [ ] Triggered first run
- [ ] Checked consumer logs for message ingestion
- [ ] Connected Metabase to PostgreSQL
- [ ] Created first dashboard/KPI card

---

**Last Updated**: May 6, 2026  
**Version**: 1.0.0  
**Status**: Production-ready (demo data)
