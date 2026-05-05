\c landed_cost_db

-- =============================================================================
-- INDEXES
-- Indexes on staging.raw_shipments created here.
-- Indexes on dbt-managed fact table (marts.fct_landed_cost) created after
-- dbt run completes (can be added as post-hook or run this section again).
-- =============================================================================

-- staging.raw_shipments — Kafka consumer target, created in 03_staging_tables.sql
CREATE INDEX IF NOT EXISTS idx_raw_shipments_date
    ON staging.raw_shipments (shipment_date);

CREATE INDEX IF NOT EXISTS idx_raw_shipments_hs_code
    ON staging.raw_shipments (hs_code);

CREATE INDEX IF NOT EXISTS idx_raw_shipments_port
    ON staging.raw_shipments (port_of_discharge);

CREATE INDEX IF NOT EXISTS idx_raw_shipments_consumed
    ON staging.raw_shipments (consumed_at);


-- =============================================================================
-- FACT TABLE INDEXES
-- These indexes on marts.fct_landed_cost are created after dbt run.
-- If fct_landed_cost doesn't exist yet, these will be created on next run.
-- =============================================================================

-- CREATE INDEX IF NOT EXISTS idx_fct_date
--     ON marts.fct_landed_cost (shipment_date);

-- CREATE INDEX IF NOT EXISTS idx_fct_month
--     ON marts.fct_landed_cost (shipment_month);

-- CREATE INDEX IF NOT EXISTS idx_fct_port
--     ON marts.fct_landed_cost (port_of_discharge);

-- CREATE INDEX IF NOT EXISTS idx_fct_hs_category
--     ON marts.fct_landed_cost (hs_category);

-- CREATE INDEX IF NOT EXISTS idx_fct_origin
--     ON marts.fct_landed_cost (origin_country);

-- CREATE INDEX IF NOT EXISTS idx_fct_anomaly
--     ON marts.fct_landed_cost (is_anomaly)
--     WHERE is_anomaly = TRUE;