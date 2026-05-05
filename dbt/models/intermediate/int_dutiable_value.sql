{{ config(materialized='table') }}

SELECT
    shipment_id,
    cif_value_usd,
    ROUND(cif_value_usd * 0.008, 4)                        AS insurance_usd,        -- 0.8% flat insurance assumption
    ROUND(cif_value_usd + (cif_value_usd * 0.008), 4)      AS dutiable_value_usd    -- CIF + insurance
FROM {{ ref('stg_shipments') }}
