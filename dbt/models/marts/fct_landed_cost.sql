{{ config(
    materialized='table',
    post_hook=[
        """
        CREATE OR REPLACE VIEW marts.v_kpi_summary AS
        SELECT
            COUNT(*) AS total_shipments,
            ROUND(AVG(landed_cost_usd)::NUMERIC, 2) AS avg_landed_cost_usd,
            ROUND(AVG(duty_rate * 100)::NUMERIC, 2) AS avg_duty_rate_pct,
            ROUND(AVG(vat_pct_of_landed * 100)::NUMERIC, 2) AS avg_vat_pct_of_landed,
            ROUND(SUM(landed_cost_usd)::NUMERIC, 2) AS total_landed_cost_usd,
            ROUND(SUM(customs_duty_usd)::NUMERIC, 2) AS total_duty_collected_usd,
            ROUND(SUM(vat_usd)::NUMERIC, 2) AS total_vat_collected_usd,
            COUNT(*) FILTER (WHERE is_anomaly = TRUE) AS anomaly_count,
            ROUND(
                COUNT(*) FILTER (WHERE is_anomaly = TRUE)::NUMERIC
                / NULLIF(COUNT(*), 0) * 100, 2
            ) AS anomaly_rate_pct
        FROM marts.fct_landed_cost
        """,
        "COMMENT ON VIEW marts.v_kpi_summary IS 'Aggregate KPI summary — top-level dashboard card source'"
    ]
) }}

WITH shipments AS (
    SELECT * FROM {{ ref('stg_shipments') }}
),
dutiable AS (
    SELECT * FROM {{ ref('int_dutiable_value') }}
),
customs AS (
    SELECT * FROM {{ ref('int_customs_fees') }}
),
port AS (
    SELECT * FROM {{ ref('int_port_fees') }}
),
joined AS (
    SELECT
        s.shipment_id,
        s.shipment_date,
        s.shipment_month,
        s.shipment_year,
        s.origin_country,
        s.port_of_discharge,
        p.port_operator,
        s.incoterm,
        s.importer_name,
        s.hs_code,
        s.commodity_description,
        s.hs_category,
        s.quantity,
        s.unit_of_measure,
        s.gross_weight_mt,
        s.item_cost_usd,
        s.freight_cost_usd,
        d.insurance_usd,
        s.cif_value_usd,
        d.dutiable_value_usd,
        c.duty_rate,
        c.customs_duty_usd,
        c.vat_usd,
        p.arrastre_usd,
        p.wharfage_usd,
        ROUND(s.cif_value_usd * 0.015, 4)                                    AS other_fees_usd,
        s.exchange_rate_php
    FROM shipments s
    JOIN dutiable  d USING (shipment_id)
    JOIN customs   c USING (shipment_id)
    JOIN port      p USING (shipment_id)
),
calculated AS (
    SELECT
        *,
        ROUND(
            customs_duty_usd + vat_usd + arrastre_usd + wharfage_usd + other_fees_usd,
            4
        )                                                                      AS total_tax_and_fees_usd,
        ROUND(
            cif_value_usd + insurance_usd + customs_duty_usd + vat_usd
            + arrastre_usd + wharfage_usd + other_fees_usd,
            4
        )                                                                      AS landed_cost_usd
    FROM joined
)

SELECT
    -- Keys
    shipment_id,
    shipment_date,
    shipment_month,
    shipment_year,

    -- Dimensions
    origin_country,
    port_of_discharge,
    port_operator,
    incoterm,
    importer_name,
    hs_code,
    commodity_description,
    hs_category,
    quantity,
    unit_of_measure,
    gross_weight_mt,

    -- Cost components (USD)
    item_cost_usd,
    freight_cost_usd,
    insurance_usd,
    cif_value_usd,
    dutiable_value_usd,
    duty_rate,
    customs_duty_usd,
    vat_usd,
    arrastre_usd,
    wharfage_usd,
    other_fees_usd,

    -- Totals
    total_tax_and_fees_usd,
    landed_cost_usd,
    exchange_rate_php,
    ROUND(landed_cost_usd * exchange_rate_php, 2)                          AS landed_cost_php,

    -- Derived ratios
    ROUND(
        customs_duty_usd / NULLIF(landed_cost_usd, 0),
        4
    )                                                                        AS duty_pct_of_landed,
    ROUND(
        vat_usd / NULLIF(landed_cost_usd, 0),
        4
    )                                                                        AS vat_pct_of_landed,
    ROUND(
        freight_cost_usd / NULLIF(landed_cost_usd, 0),
        4
    )                                                                        AS freight_pct_of_landed,
    ROUND(
        (arrastre_usd + wharfage_usd) / NULLIF(landed_cost_usd, 0),
        4
    )                                                                        AS port_fees_pct_of_landed,
    ROUND(
        landed_cost_usd / NULLIF(item_cost_usd, 0),
        4
    )                                                                        AS cost_ratio,

    -- Quality flags
    CASE WHEN (landed_cost_usd / NULLIF(item_cost_usd, 0)) >= 2.0 
         THEN TRUE ELSE FALSE END                                           AS is_anomaly,

    NOW()                                                                    AS dbt_loaded_at

FROM calculated

