{{ config(materialized='table') }}

SELECT
    shipment_id::UUID                              AS shipment_id,
    shipment_date::DATE                            AS shipment_date,
    DATE_TRUNC('month', shipment_date::DATE)::DATE AS shipment_month,
    EXTRACT(YEAR FROM shipment_date::DATE)::SMALLINT AS shipment_year,
    TRIM(origin_country)                           AS origin_country,
    TRIM(port_of_discharge)                        AS port_of_discharge,
    UPPER(TRIM(incoterm))                          AS incoterm,
    TRIM(importer_name)                            AS importer_name,
    TRIM(hs_code)                                  AS hs_code,
    TRIM(commodity_description)                    AS commodity_description,
    TRIM(hs_category)                              AS hs_category,
    quantity::INTEGER                              AS quantity,
    UPPER(TRIM(unit_of_measure))                   AS unit_of_measure,
    unit_price_usd::NUMERIC(14,4)                  AS unit_price_usd,
    item_cost_usd::NUMERIC(14,4)                   AS item_cost_usd,
    gross_weight_mt::NUMERIC(12,4)                 AS gross_weight_mt,
    freight_cost_usd::NUMERIC(14,4)                AS freight_cost_usd,
    cif_value_usd::NUMERIC(14,4)                   AS cif_value_usd,
    exchange_rate_php::NUMERIC(8,4)                AS exchange_rate_php,
    data_source,
    NOW()                                          AS dbt_loaded_at
FROM staging.raw_shipments
WHERE shipment_id IS NOT NULL
  AND shipment_date IS NOT NULL
  AND cif_value_usd > 0
