\c landed_cost_db

COMMENT ON SCHEMA staging IS 'Raw records from Kafka consumer — never query directly for analytics';
COMMENT ON SCHEMA seeds   IS 'Static lookup tables: HS codes, port fee schedules';
COMMENT ON SCHEMA marts   IS 'dbt-managed models: staging tables, intermediate calculations, and fact tables';

COMMENT ON TABLE  seeds.hs_codes           IS 'AHTN/HS code to duty rate mapping (CMTA 2016)';
COMMENT ON COLUMN seeds.hs_codes.duty_rate IS 'MFN duty rate as decimal (0.20 = 20%)';

COMMENT ON TABLE  seeds.port_fees                   IS 'Port authority fee schedule — ICTSI, SPIA, APMC';
COMMENT ON COLUMN seeds.port_fees.arrastre_rate_php IS 'Charged per gross metric ton by port operator';
COMMENT ON COLUMN seeds.port_fees.wharfage_rate_php IS 'Charged per gross metric ton, set by PPA';

COMMENT ON TABLE staging.raw_shipments IS 'Raw Kafka consumer output — one row per shipment event';

COMMENT ON VIEW staging.v_pipeline_health IS 'Daily pipeline health summary — used by Airflow and monitoring';

-- ⚠️  NOTE: Comment on marts.v_kpi_summary is applied after dbt run via post_hook
-- COMMENT ON VIEW marts.v_kpi_summary IS 'Aggregate KPI summary — top-level dashboard card source';