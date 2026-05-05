\c landed_cost_db

-- =============================================================================
-- SCHEMA: seeds
-- Reference tables loaded once, updated manually when rates change.
-- In dbt, these are loaded via: dbt seed
-- =============================================================================

-- HS Code → Duty Rate lookup (mirrors seeds/hs_codes.csv)
CREATE TABLE IF NOT EXISTS seeds.hs_codes (
    hs_code               CHAR(8)         NOT NULL,
    description           VARCHAR(200)    NOT NULL,
    category              VARCHAR(100)    NOT NULL,
    duty_rate             NUMERIC(5, 4)   NOT NULL,  -- e.g. 0.2000 = 20%
    cmta_chapter          VARCHAR(10),               -- CMTA 2016 chapter reference
    unit_of_quantity      VARCHAR(20),               -- UoQ per BOC
    is_active             BOOLEAN         NOT NULL DEFAULT TRUE,
    effective_date        DATE            NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_hs_codes PRIMARY KEY (hs_code)
);


-- Port Fee Schedule (mirrors seeds/port_fees.csv)
CREATE TABLE IF NOT EXISTS seeds.port_fees (
    port_name             VARCHAR(50)     NOT NULL,
    port_operator         VARCHAR(150)    NOT NULL,
    arrastre_rate_php     NUMERIC(10, 4)  NOT NULL,  -- PHP per metric ton
    wharfage_rate_php     NUMERIC(10, 4)  NOT NULL,  -- PHP per metric ton (PPA-approved)
    reference_rate_usd    NUMERIC(8, 4)   NOT NULL DEFAULT 55.0,  -- USD/PHP for rate conversion
    effective_date        DATE            NOT NULL DEFAULT CURRENT_DATE,
    is_active             BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_port_fees PRIMARY KEY (port_name)
);