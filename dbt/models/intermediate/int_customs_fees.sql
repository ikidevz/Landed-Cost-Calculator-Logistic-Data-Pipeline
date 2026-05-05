{{ config(materialized='table') }}

WITH base AS (
    SELECT
        s.shipment_id,
        s.hs_code,
        s.hs_category,
        d.dutiable_value_usd,
        COALESCE(h.duty_rate, 0) AS duty_rate   -- default 0% for unrecognised HS codes
    FROM {{ ref('stg_shipments') }}       s
    JOIN {{ ref('int_dutiable_value') }}  d USING (shipment_id)
    LEFT JOIN {{ ref('hs_codes') }}       h USING (hs_code)
),

calculated AS (
    SELECT
        shipment_id,
        hs_code,
        hs_category,
        duty_rate,
        dutiable_value_usd,
        ROUND(dutiable_value_usd * duty_rate, 4)                             AS customs_duty_usd,
        ROUND(dutiable_value_usd + (dutiable_value_usd * duty_rate), 4)       AS vat_base_usd
    FROM base
)

SELECT
    shipment_id,
    hs_code,
    hs_category,
    duty_rate,
    dutiable_value_usd,
    customs_duty_usd,
    vat_base_usd,
    ROUND(vat_base_usd * 0.12, 4)                                            AS vat_usd
FROM calculated

