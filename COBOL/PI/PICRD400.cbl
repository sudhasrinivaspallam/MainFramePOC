       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD400.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PICRD400                                          *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD RENEWAL BATCH PROGRAM    *
      *              IDENTIFIES CARDS EXPIRING WITHIN 60 DAYS,         *
      *              GENERATES REPLACEMENT CARDS WITH NEW EXPIRY.      *
      * INPUT:       DB2 TB_CARD_MASTER (CURSOR - EXPIRING CARDS)      *
      * OUTPUT:      RENWOUT  - RENEWAL CARDS OUTPUT FILE              *
      *              RENWRPT  - RENEWAL SUMMARY REPORT                 *
      * DATABASE:    TB_CARD_MASTER (SELECT, INSERT, UPDATE)           *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RENEWAL-OUTPUT-FILE
               ASSIGN TO RENWOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT RENEWAL-REPORT-FILE
               ASSIGN TO RENWRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  RENEWAL-OUTPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 200 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  RENEWAL-OUTPUT-RECORD          PIC X(200).

       FD  RENEWAL-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  RENEWAL-REPORT-RECORD          PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD400'.

       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYCRD01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * RENEWAL PARAMETERS
       01  WS-RENEWAL-PARAMS.
           05  WS-LOOK-AHEAD-DAYS        PIC 9(03) VALUE 060.
           05  WS-RENEWAL-YEARS          PIC 9(02) VALUE 003.
           05  WS-CUTOFF-DATE            PIC X(10).

      * DB2 HOST VARIABLES
           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HV-OLD-CARD-NUMBER             PIC X(16).
       01  HV-NEW-CARD-NUMBER             PIC X(16).
       01  HV-CARD-TYPE                   PIC X(02).
       01  HV-ACCOUNT-NUMBER              PIC X(12).
       01  HV-CUSTOMER-ID                 PIC X(10).
       01  HV-FIRST-NAME                  PIC X(25).
       01  HV-LAST-NAME                   PIC X(25).
       01  HV-EXPIRY-DATE                 PIC X(10).
       01  HV-NEW-EXPIRY-DATE             PIC X(10).
       01  HV-CARD-STATUS                 PIC X(02).
       01  HV-DAILY-LIMIT                 PIC S9(09)V99 COMP-3.
       01  HV-BRANCH-CODE                 PIC X(06).
       01  HV-CUTOFF-DATE                 PIC X(10).

      * CURSOR FOR EXPIRING CARDS
           EXEC SQL
               DECLARE CSR_EXPIRING_CARDS CURSOR FOR
               SELECT CARD_NUMBER, CARD_TYPE, ACCOUNT_NUMBER,
                      CUSTOMER_ID, FIRST_NAME, LAST_NAME,
                      EXPIRY_DATE, CARD_STATUS,
                      DAILY_LIMIT, BRANCH_CODE
               FROM TB_CARD_MASTER
               WHERE EXPIRY_DATE <= :HV-CUTOFF-DATE
                 AND CARD_STATUS = 'AC'
               ORDER BY EXPIRY_DATE, CARD_NUMBER
           END-EXEC

      * CARD SEQUENCE FOR RENEWALS
       01  WS-RENEW-SEQ                   PIC 9(09) VALUE ZEROS.

       01  WS-RPT-SUM-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-SUM-LABEL         PIC X(40).
           05  WS-RPT-SUM-COUNT         PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(81) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-RENEWALS
           PERFORM 3000-WRITE-SUMMARY
           PERFORM 9000-TERMINATE
           STOP RUN.

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING

      *    CALCULATE CUTOFF DATE (CURRENT + 60 DAYS)
           COMPUTE WS-DATE-WORK-1 =
               (WS-CURRENT-YEAR * 10000) +
               (WS-CURRENT-MONTH * 100) +
               WS-CURRENT-DAY
           ADD WS-LOOK-AHEAD-DAYS TO WS-CURRENT-DAY
           MOVE WS-FORMATTED-DATE TO WS-CUTOFF-DATE
           MOVE WS-CUTOFF-DATE TO HV-CUTOFF-DATE

           OPEN OUTPUT RENEWAL-OUTPUT-FILE
                       RENEWAL-REPORT-FILE

           EXEC SQL
               OPEN CSR_EXPIRING_CARDS
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE 'CURSOR OPEN FAILED' TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

       2000-PROCESS-RENEWALS.
           PERFORM UNTIL WS-EOF
               EXEC SQL
                   FETCH CSR_EXPIRING_CARDS
                   INTO :HV-OLD-CARD-NUMBER, :HV-CARD-TYPE,
                        :HV-ACCOUNT-NUMBER, :HV-CUSTOMER-ID,
                        :HV-FIRST-NAME, :HV-LAST-NAME,
                        :HV-EXPIRY-DATE, :HV-CARD-STATUS,
                        :HV-DAILY-LIMIT, :HV-BRANCH-CODE
               END-EXEC

               EVALUATE SQLCODE
                   WHEN 0
                       ADD 1 TO WS-RECORDS-READ
                       PERFORM 2100-GENERATE-RENEWAL
                       PERFORM 2200-INSERT-NEW-CARD
                       PERFORM 2300-UPDATE-OLD-CARD
                       PERFORM 2400-WRITE-OUTPUT
                   WHEN 100
                       SET WS-EOF TO TRUE
                   WHEN OTHER
                       MOVE SQLCODE TO WS-ERR-SQLCODE
                       MOVE 'CURSOR FETCH FAILED'
                           TO WS-ERR-MESSAGE
                       MOVE 'S' TO WS-ERR-SEVERITY
                       PERFORM 8000-ERROR-HANDLER
               END-EVALUATE
           END-PERFORM

           EXEC SQL
               CLOSE CSR_EXPIRING_CARDS
           END-EXEC
           .

      ******************************************************************
      * 2100-GENERATE-RENEWAL: GENERATE NEW CARD NUMBER                *
      ******************************************************************
       2100-GENERATE-RENEWAL.
           ADD 1 TO WS-RENEW-SEQ
           STRING '400012'
                  WS-RENEW-SEQ
               DELIMITED BY SIZE
               INTO HV-NEW-CARD-NUMBER
           END-STRING

      *    CALCULATE NEW EXPIRY (3 YEARS FROM NOW)
           COMPUTE WS-DATE-WORK-1 = WS-CURRENT-YEAR
                                  + WS-RENEWAL-YEARS
           STRING WS-DATE-WORK-1(1:4) '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO HV-NEW-EXPIRY-DATE
           END-STRING
           .

       2200-INSERT-NEW-CARD.
           EXEC SQL
               INSERT INTO TB_CARD_MASTER
               (CARD_NUMBER, CARD_TYPE, ACCOUNT_NUMBER,
                CUSTOMER_ID, FIRST_NAME, LAST_NAME,
                CARD_STATUS, ISSUE_DATE, EXPIRY_DATE,
                DAILY_LIMIT, BRANCH_CODE, CREATED_TIMESTAMP)
               VALUES
               (:HV-NEW-CARD-NUMBER, :HV-CARD-TYPE,
                :HV-ACCOUNT-NUMBER, :HV-CUSTOMER-ID,
                :HV-FIRST-NAME, :HV-LAST-NAME,
                'NW', CURRENT DATE,
                :HV-NEW-EXPIRY-DATE,
                :HV-DAILY-LIMIT, :HV-BRANCH-CODE,
                CURRENT TIMESTAMP)
           END-EXEC

           IF SQLCODE = 0
               ADD 1 TO WS-RECORDS-WRITTEN
           ELSE
               MOVE SQLCODE TO WS-ERR-SQLCODE
               MOVE 'RENEWAL INSERT FAILED' TO WS-ERR-MESSAGE
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

       2300-UPDATE-OLD-CARD.
           EXEC SQL
               UPDATE TB_CARD_MASTER
               SET CARD_STATUS = 'EX',
                   UPDATED_TIMESTAMP = CURRENT TIMESTAMP
               WHERE CARD_NUMBER = :HV-OLD-CARD-NUMBER
           END-EXEC
           .

       2400-WRITE-OUTPUT.
           INITIALIZE RENEWAL-OUTPUT-RECORD
           MOVE HV-OLD-CARD-NUMBER    TO RENEWAL-OUTPUT-RECORD(1:16)
           MOVE HV-NEW-CARD-NUMBER    TO RENEWAL-OUTPUT-RECORD(17:16)
           MOVE HV-ACCOUNT-NUMBER     TO RENEWAL-OUTPUT-RECORD(33:12)
           MOVE HV-CUSTOMER-ID        TO RENEWAL-OUTPUT-RECORD(45:10)
           MOVE HV-EXPIRY-DATE        TO RENEWAL-OUTPUT-RECORD(55:10)
           MOVE HV-NEW-EXPIRY-DATE    TO RENEWAL-OUTPUT-RECORD(65:10)
           WRITE RENEWAL-OUTPUT-RECORD
           .

       3000-WRITE-SUMMARY.
           MOVE 'CARDS SCANNED FOR RENEWAL: ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ                TO WS-RPT-SUM-COUNT
           WRITE RENEWAL-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'RENEWAL CARDS ISSUED:      ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-WRITTEN             TO WS-RPT-SUM-COUNT
           WRITE RENEWAL-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

       8000-ERROR-HANDLER.
           MOVE WS-PROGRAM-ID TO WS-ERR-PROGRAM-ID
           DISPLAY '*** ERROR IN PROGRAM: ' WS-ERR-PROGRAM-ID
           DISPLAY '*** MESSAGE: ' WS-ERR-MESSAGE
           IF WS-ERR-SEVERE OR WS-ERR-CRITICAL
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF
           .

       9000-TERMINATE.
           EXEC SQL COMMIT END-EXEC
           CLOSE RENEWAL-OUTPUT-FILE
                 RENEWAL-REPORT-FILE
           DISPLAY 'PICRD400 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
