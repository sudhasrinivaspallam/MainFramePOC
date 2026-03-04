-- ================================================================
-- DDL: CRTTBL03.sql
-- TABLE: TB_CARD_STATUS_HISTORY
-- DATABASE: DB2 - PI (Plastic Issuance) Subsystem
-- DESCRIPTION: Status change audit trail for cards
-- ================================================================

CREATE TABLE TB_CARD_STATUS_HISTORY
(
    HISTORY_ID          INTEGER         GENERATED ALWAYS AS IDENTITY
                                        (START WITH 1 INCREMENT BY 1),
    CARD_NUMBER         CHAR(16)        NOT NULL,
    PREVIOUS_STATUS     CHAR(2)         NOT NULL,
    NEW_STATUS          CHAR(2)         NOT NULL,
    REASON_CODE         CHAR(4),
    REQUESTOR_ID        CHAR(10),
    STATUS_DATE         DATE            NOT NULL,
    CREATED_TIMESTAMP   TIMESTAMP       NOT NULL
        WITH DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (HISTORY_ID)
)
IN PIDB.PITS03
CCSID EBCDIC;

ALTER TABLE TB_CARD_STATUS_HISTORY
    ADD CONSTRAINT FK_HIST_CARD
    FOREIGN KEY (CARD_NUMBER)
    REFERENCES TB_CARD_MASTER (CARD_NUMBER)
    ON DELETE RESTRICT;

COMMENT ON TABLE TB_CARD_STATUS_HISTORY IS
    'Card Status History - Audit trail of all status changes';
