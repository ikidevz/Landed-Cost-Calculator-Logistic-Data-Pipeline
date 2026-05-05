\c landed_cost_db

-- =============================================================================
-- MONITORING VIEWS
-- Lightweight views for pipeline health checks and Airflow sensors.
-- Note: marts.v_kpi_summary depends on marts.fct_landed_cost which is created
-- by dbt. This script must run after dbt run completes, or be created as a
-- dbt post-hook. Included here for reference and direct SQL access (Metabase).
-- =============================================================================

CREATE OR REPLACE VIEW staging.v_pipeline_health AS
SELECT
    DATE(consumed_at)                              AS pipeline_date,
    COUNT(*)                                       AS records_ingested,
    COUNT(*) FILTER (WHERE is_anomaly = TRUE)      AS anomaly_count,
    ROUND(AVG(landed_cost_usd)::NUMERIC, 2)        AS avg_landed_cost_usd,
    MIN(consumed_at)                               AS first_record_at,
    MAX(consumed_at)                               AS last_record_at
FROM staging.raw_shipments
GROUP BY DATE(consumed_at)
ORDER BY pipeline_date DESC;


-- ⚠️  IMPORTANT: This view is commented out because it depends on marts.fct_landed_cost,
-- which is created by dbt, not by these init-scripts.
-- After running: dbt run
-- Manually execute this command or add it as a post-hook in fct_landed_cost.sql:
--
-- CREATE OR REPLACE VIEW marts.v_kpi_summary AS
-- SELECT
--     COUNT(*)                                               AS total_shipments,
--     ROUND(AVG(landed_cost_usd)::NUMERIC, 2)               AS avg_landed_cost_usd,
--     ROUND(AVG(duty_rate * 100)::NUMERIC, 2)               AS avg_duty_rate_pct,
--     ROUND(AVG(vat_pct_of_landed * 100)::NUMERIC, 2)       AS avg_vat_pct_of_landed,
--     ROUND(SUM(landed_cost_usd)::NUMERIC, 2)               AS total_landed_cost_usd,
--     ROUND(SUM(customs_duty_usd)::NUMERIC, 2)              AS total_duty_collected_usd,
--     ROUND(SUM(vat_usd)::NUMERIC, 2)                       AS total_vat_collected_usd,
--     COUNT(*) FILTER (WHERE is_anomaly = TRUE)             AS anomaly_count,
--     ROUND(
--         COUNT(*) FILTER (WHERE is_anomaly = TRUE)::NUMERIC
--         / NULLIF(COUNT(*), 0) * 100, 2
--     )                                                      AS anomaly_rate_pct
-- FROM marts.fct_landed_cost;