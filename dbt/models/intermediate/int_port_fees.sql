{{ config(materialized='table') }}

SELECT
    s.shipment_id,
    s.port_of_discharge,
    p.port_operator,
    s.gross_weight_mt,
    p.arrastre_rate_php,
    p.wharfage_rate_php,
    ROUND((s.gross_weight_mt * p.arrastre_rate_php) / p.reference_rate_usd, 4)                 AS arrastre_usd,
    ROUND((s.gross_weight_mt * p.wharfage_rate_php) / p.reference_rate_usd, 4)                 AS wharfage_usd,
    ROUND((s.gross_weight_mt * (p.arrastre_rate_php + p.wharfage_rate_php)) 
          / p.reference_rate_usd, 4)                                                           AS port_fees_total_usd
FROM {{ ref('stg_shipments') }} s
LEFT JOIN {{ ref('port_fees') }} p
    ON s.port_of_discharge = p.port_name

