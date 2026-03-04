-- ================================================================
-- DDL: CRTTBL01.sql
-- TABLE: TB_CARD_MASTER
-- DATABASE: DB2 - PI (Plastic Issuance) Subsystem
-- DESCRIPTION: Card Master table storing all debit card details
-- ================================================================

CREATE TABLE TB_CARD_MASTER
(
    CARD_NUMBER         CHAR(16)        NOT NULL,
    CARD_TYPE           CHAR(2)         NOT NULL,
    ACCOUNT_NUMBER      CHAR(12)        NOT NULL,
    CUSTOMER_ID         CHAR(10)        NOT NULL,
    FIRST_NAME          VARCHAR(25)     NOT NULL,
    LAST_NAME           VARCHAR(25)     NOT NULL,
    ADDR_LINE1          VARCHAR(40),
    ADDR_LINE2          VARCHAR(40),
    CITY                VARCHAR(25),
    STATE               CHAR(2),
    ZIP_CODE            CHAR(10),
    CARD_STATUS         CHAR(2)         NOT NULL
        WITH DEFAULT 'NW',
    ISSUE_DATE          DATE            NOT NULL,
    EXPIRY_DATE         DATE            NOT NULL,
    ACTIVATION_DATE     DATE,
    LAST_USED_DATE      DATE,
    DAILY_LIMIT         DECIMAL(11,2)   NOT NULL
        WITH DEFAULT 1000.00,
    AVAILABLE_BALANCE   DECIMAL(13,2)   NOT NULL
        WITH DEFAULT 0.00,
    PIN_OFFSET          CHAR(4),
    CVV_VALUE           CHAR(3),
    BRANCH_CODE         CHAR(6),
    CREATED_TIMESTAMP   TIMESTAMP       NOT NULL
        WITH DEFAULT CURRENT TIMESTAMP,
    UPDATED_TIMESTAMP   TIMESTAMP       NOT NULL
        WITH DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (CARD_NUMBER)
)
IN PIDB.PITS01
CCSID EBCDIC;

-- Add check constraints
ALTER TABLE TB_CARD_MASTER
    ADD CONSTRAINT CK_CARD_STATUS
    CHECK (CARD_STATUS IN ('NW','AC','IN','BL','EX','CL'));

ALTER TABLE TB_CARD_MASTER
    ADD CONSTRAINT CK_CARD_TYPE
    CHECK (CARD_TYPE IN ('DB','PP'));

COMMENT ON TABLE TB_CARD_MASTER IS
    'Card Master - Stores all debit and prepaid card information';
