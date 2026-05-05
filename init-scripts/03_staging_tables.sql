\c landed_cost_db

-- =============================================================================
-- SCHEMA: staging
-- Raw records inserted by the Kafka consumer.
-- Column names match exactly the JSON keys from generate.py.
-- No transformations applied — this is the source of truth for re-processing.
-- =============================================================================

CREATE TABLE IF NOT EXISTS staging.raw_shipments (
    -- Kafka metadata
    kafka_offset          BIGINT,
    kafka_partition       SMALLINT,
    kafka_topic           VARCHAR(100)    DEFAULT 'shipments',
    consumed_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Record identifiers
    shipment_id           UUID            NOT NULL,
    shipment_date         TIMESTAMP       NOT NULL,
    ingestion_timestamp   TIMESTAMP,

    -- Shipment metadata
    origin_country        VARCHAR(100),
    port_of_discharge     VARCHAR(50),
    port_operator         VARCHAR(200),
    incoterm              CHAR(3),
    importer_name         VARCHAR(200),
    importer_tin          VARCHAR(30),

    -- Commodity fields
    hs_code               CHAR(8),
    commodity_description VARCHAR(200),
    hs_category           VARCHAR(100),
    quantity              INTEGER,
    unit_of_measure       VARCHAR(10),
    unit_price_usd        NUMERIC(14, 4),
    item_cost_usd         NUMERIC(14, 4),
    gross_weight_mt       NUMERIC(12, 4),

    -- Freight & CIF
    freight_cost_usd      NUMERIC(14, 4),
    cif_value_usd         NUMERIC(14, 4),

    -- Landed cost components (as computed by generator / source system)
    insurance_usd         NUMERIC(14, 4),
    dutiable_value_usd    NUMERIC(14, 4),
    duty_rate             NUMERIC(6, 4),
    customs_duty_usd      NUMERIC(14, 4),
    vat_usd               NUMERIC(14, 4),
    arrastre_usd          NUMERIC(14, 4),
    wharfage_usd          NUMERIC(14, 4),
    other_fees_usd        NUMERIC(14, 4),

    -- Final totals
    landed_cost_usd       NUMERIC(14, 4),
    exchange_rate_php     NUMERIC(8, 4),
    landed_cost_php       NUMERIC(18, 2),

    -- Quality flags (from generator)
    cost_ratio            NUMERIC(8, 4),
    is_anomaly            BOOLEAN,
    data_source           VARCHAR(50),

    -- Deduplication
    CONSTRAINT pk_raw_shipments PRIMARY KEY (shipment_id)
);