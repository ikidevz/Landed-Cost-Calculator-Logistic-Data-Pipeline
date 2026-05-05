-- analyses/landed_cost_breakdown.sql
--
-- Ad-hoc analysis: landed cost component breakdown by HS category and port.
-- This file is compiled by dbt (dbt compile) but NOT run against the database.
-- Use it as a reference for building Metabase dashboard cards.
--
-- Run compiled SQL from: target/compiled/landed_cost/analyses/landed_cost_breakdown.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Overall KPI Summary
-- ─────────────────────────────────────────────────────────────────────────────
WITH kpis AS (
    SELECT
        COUNT(*)                                                AS total_shipments,
        ROUND(AVG(landed_cost_usd)::NUMERIC, 2)                AS avg_landed_cost_usd,
        ROUND(AVG(duty_rate * 100)::NUMERIC, 2)                AS avg_duty_rate_pct,
        ROUND(AVG(vat_pct_of_landed * 100)::NUMERIC, 2)        AS avg_vat_pct,
        ROUND(SUM(landed_cost_usd)::NUMERIC, 2)                AS total_landed_cost_usd,
        ROUND(SUM(customs_duty_usd)::NUMERIC, 2)               AS total_duty_usd,
        ROUND(SUM(vat_usd)::NUMERIC, 2)                        AS total_vat_usd,
        COUNT(*) FILTER (WHERE is_anomaly = TRUE)              AS anomaly_count
    FROM {{ ref('fct_landed_cost') }}
)

SELECT * FROM kpis;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Cost Component Breakdown (for stacked bar chart in Metabase)
-- ─────────────────────────────────────────────────────────────────────────────
/*
SELECT
    hs_category,
    ROUND(AVG(item_cost_usd), 2)         AS avg_item_cost,
    ROUND(AVG(freight_cost_usd), 2)      AS avg_freight,
    ROUND(AVG(insurance_usd), 2)         AS avg_insurance,
    ROUND(AVG(customs_duty_usd), 2)      AS avg_customs_duty,
    ROUND(AVG(vat_usd), 2)              AS avg_vat,
    ROUND(AVG(arrastre_usd), 2)         AS avg_arrastre,
    ROUND(AVG(wharfage_usd), 2)         AS avg_wharfage,
    ROUND(AVG(other_fees_usd), 2)       AS avg_other_fees,
    ROUND(AVG(landed_cost_usd), 2)      AS avg_total_landed_cost
FROM {{ ref('fct_landed_cost') }}
GROUP BY hs_category
ORDER BY avg_total_landed_cost DESC;
*/


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Monthly Shipment Volume Trend
-- ─────────────────────────────────────────────────────────────────────────────
/*
SELECT
    shipment_month,
    COUNT(*)                                  AS shipment_count,
    ROUND(SUM(landed_cost_usd)::NUMERIC, 2)   AS total_landed_cost_usd,
    ROUND(AVG(landed_cost_usd)::NUMERIC, 2)   AS avg_landed_cost_usd
FROM {{ ref('fct_landed_cost') }}
GROUP BY shipment_month
ORDER BY shipment_month;
*/


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Landed Cost by Port of Discharge
-- ─────────────────────────────────────────────────────────────────────────────
/*
SELECT
    port_of_discharge,
    port_operator,
    COUNT(*)                                          AS shipment_count,
    ROUND(AVG(landed_cost_usd)::NUMERIC, 2)           AS avg_landed_cost_usd,
    ROUND(AVG(arrastre_usd + wharfage_usd)::NUMERIC, 2) AS avg_port_fees_usd
FROM {{ ref('fct_landed_cost') }}
GROUP BY port_of_discharge, port_operator
ORDER BY avg_landed_cost_usd DESC;
*/


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Top 10 Origin Countries by Average Landed Cost
-- ─────────────────────────────────────────────────────────────────────────────
/*
SELECT
    origin_country,
    COUNT(*)                                          AS shipment_count,
    ROUND(AVG(landed_cost_usd)::NUMERIC, 2)           AS avg_landed_cost_usd,
    ROUND(AVG(duty_rate * 100)::NUMERIC, 2)           AS avg_duty_rate_pct
FROM {{ ref('fct_landed_cost') }}
GROUP BY origin_country
ORDER BY avg_landed_cost_usd DESC
LIMIT 10;
*/


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Anomaly Detection: Shipments where duty > 30% of landed cost
-- ─────────────────────────────────────────────────────────────────────────────
/*
SELECT
    shipment_id,
    shipment_date,
    importer_name,
    hs_code,
    commodity_description,
    origin_country,
    port_of_discharge,
    customs_duty_usd,
    landed_cost_usd,
    ROUND(duty_pct_of_landed * 100, 2)   AS duty_pct_of_landed,
    cost_ratio,
    is_anomaly
FROM {{ ref('fct_landed_cost') }}
WHERE duty_pct_of_landed > 0.30
ORDER BY duty_pct_of_landed DESC;
*/
