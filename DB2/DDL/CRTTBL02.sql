-- ================================================================
-- DDL: CRTTBL02.sql
-- TABLE: TB_CARD_TRANSACTION
-- DATABASE: DB2 - PI (Plastic Issuance) Subsystem
-- DESCRIPTION: Card Transaction table storing all card transactions
-- ================================================================

CREATE TABLE TB_CARD_TRANSACTION
(
    TXN_ID              CHAR(20)        NOT NULL,
    CARD_NUMBER         CHAR(16)        NOT NULL,
    TXN_TYPE            CHAR(2)         NOT NULL,
    TXN_AMOUNT          DECIMAL(13,2)   NOT NULL,
    TXN_DATE            DATE            NOT NULL,
    TXN_TIME            TIME            NOT NULL,
    MERCHANT_ID         CHAR(15),
    MERCHANT_NAME       VARCHAR(40),
    MERCHANT_CATG       CHAR(4),
    AUTH_CODE           CHAR(6),
    RESPONSE_CODE       CHAR(3)         NOT NULL,
    TERMINAL_ID         CHAR(8),
    BATCH_NUMBER        CHAR(8),
    SETTLE_FLAG         CHAR(1)         NOT NULL
        WITH DEFAULT 'N',
    SETTLE_DATE         DATE,
    CREATED_TIMESTAMP   TIMESTAMP       NOT NULL
        WITH DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (TXN_ID)
)
IN PIDB.PITS02
CCSID EBCDIC;

-- Foreign key to Card Master
ALTER TABLE TB_CARD_TRANSACTION
    ADD CONSTRAINT FK_TXN_CARD
    FOREIGN KEY (CARD_NUMBER)
    REFERENCES TB_CARD_MASTER (CARD_NUMBER)
    ON DELETE RESTRICT;

-- Check constraints
ALTER TABLE TB_CARD_TRANSACTION
    ADD CONSTRAINT CK_TXN_TYPE
    CHECK (TXN_TYPE IN ('PU','AW','RF','RV','FE'));

ALTER TABLE TB_CARD_TRANSACTION
    ADD CONSTRAINT CK_SETTLE_FLAG
    CHECK (SETTLE_FLAG IN ('N','Y','P'));

COMMENT ON TABLE TB_CARD_TRANSACTION IS
    'Card Transactions - All debit card transaction records';
