       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD100.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PICRD100                                          *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD ISSUANCE BATCH PROGRAM   *
      *              READS NEW CARD REQUESTS FROM INPUT FILE,          *
      *              VALIDATES DATA, GENERATES CARD NUMBERS,           *
      *              AND INSERTS INTO DB2 CARD MASTER TABLE.           *
      * INPUT:       CARDINP  - NEW CARD REQUEST FILE                  *
      * OUTPUT:      CARDOUT  - ISSUED CARDS CONFIRMATION FILE         *
      *              CARDERR  - REJECTED RECORDS FILE                  *
      *              CARDRPT  - CARD ISSUANCE SUMMARY REPORT           *
      * DATABASE:    TB_CARD_MASTER (INSERT)                           *
      *              TB_CARD_TRANSACTION (INSERT - ISSUANCE TXN)       *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CARD-INPUT-FILE
               ASSIGN TO CARDINP
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT CARD-OUTPUT-FILE
               ASSIGN TO CARDOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT CARD-ERROR-FILE
               ASSIGN TO CARDERR
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERR-FILE-STATUS.

           SELECT CARD-REPORT-FILE
               ASSIGN TO CARDRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-INPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 300 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  CARD-INPUT-RECORD              PIC X(300).

       FD  CARD-OUTPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 350 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  CARD-OUTPUT-RECORD             PIC X(350).

       FD  CARD-ERROR-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 380 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  CARD-ERROR-RECORD              PIC X(380).

       FD  CARD-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  CARD-REPORT-RECORD             PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD100'.

      * FILE STATUS CODES
       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-ERR-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

      * INCLUDE COPYBOOKS
           COPY CPYCRD01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * INPUT RECORD LAYOUT
       01  WS-INPUT-REC.
           05  WS-INP-REQUEST-TYPE        PIC X(02).
               88  WS-INP-NEW-CARD        VALUE 'NC'.
               88  WS-INP-REPLACE-CARD    VALUE 'RC'.
           05  WS-INP-ACCOUNT-NUMBER      PIC X(12).
           05  WS-INP-CUSTOMER-ID         PIC X(10).
           05  WS-INP-FIRST-NAME          PIC X(25).
           05  WS-INP-LAST-NAME           PIC X(25).
           05  WS-INP-ADDR-LINE1          PIC X(40).
           05  WS-INP-ADDR-LINE2          PIC X(40).
           05  WS-INP-CITY                PIC X(25).
           05  WS-INP-STATE               PIC X(02).
           05  WS-INP-ZIP-CODE            PIC X(10).
           05  WS-INP-CARD-TYPE           PIC X(02).
           05  WS-INP-DAILY-LIMIT         PIC S9(09)V99 COMP-3.
           05  WS-INP-BRANCH-CODE         PIC X(06).
           05  FILLER                     PIC X(95).

      * CARD NUMBER GENERATION
       01  WS-CARD-GEN-AREA.
           05  WS-BIN-PREFIX              PIC X(06) VALUE '400012'.
           05  WS-CARD-SEQ-NUM            PIC 9(09) VALUE ZEROS.
           05  WS-CHECK-DIGIT             PIC 9(01) VALUE ZEROS.
           05  WS-GENERATED-CARD-NUM      PIC X(16).

      * LUHN ALGORITHM WORK AREAS
       01  WS-LUHN-WORK.
           05  WS-LUHN-SUM               PIC 9(03) VALUE ZEROS.
           05  WS-LUHN-DIGIT             PIC 9(02) VALUE ZEROS.
           05  WS-LUHN-IDX               PIC 9(02) VALUE ZEROS.
           05  WS-LUHN-TEMP              PIC 9(02) VALUE ZEROS.

      * EXPIRY DATE CALCULATION
       01  WS-EXPIRY-WORK.
           05  WS-EXP-YEAR               PIC 9(04).
           05  WS-EXP-MONTH              PIC 9(02).
           05  WS-CARD-VALIDITY-YEARS     PIC 9(02) VALUE 03.

      * DB2 HOST VARIABLES
           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HV-CARD-MASTER.
           05  HV-CARD-NUMBER            PIC X(16).
           05  HV-CARD-TYPE              PIC X(02).
           05  HV-ACCOUNT-NUMBER         PIC X(12).
           05  HV-CUSTOMER-ID            PIC X(10).
           05  HV-FIRST-NAME             PIC X(25).
           05  HV-LAST-NAME              PIC X(25).
           05  HV-ADDR-LINE1             PIC X(40).
           05  HV-ADDR-LINE2             PIC X(40).
           05  HV-CITY                   PIC X(25).
           05  HV-STATE                  PIC X(02).
           05  HV-ZIP-CODE               PIC X(10).
           05  HV-CARD-STATUS            PIC X(02).
           05  HV-ISSUE-DATE             PIC X(10).
           05  HV-EXPIRY-DATE            PIC X(10).
           05  HV-DAILY-LIMIT            PIC S9(09)V99 COMP-3.
           05  HV-BRANCH-CODE            PIC X(06).

      * REPORT WORK AREAS
       01  WS-RPT-HEADER-1.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               'PLASTIC ISSUANCE - DAILY CARD ISSUANCE REPORT'.
           05  FILLER                    PIC X(30) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-HEADER-2.
           05  FILLER                    PIC X(01) VALUE '0'.
           05  FILLER                    PIC X(16) VALUE 'CARD NUMBER     '.
           05  FILLER                    PIC X(14) VALUE 'ACCOUNT       '.
           05  FILLER                    PIC X(30) VALUE
               'CUSTOMER NAME                 '.
           05  FILLER                    PIC X(06) VALUE 'TYPE  '.
           05  FILLER                    PIC X(08) VALUE 'STATUS  '.
           05  FILLER                    PIC X(12) VALUE 'ISSUE DATE  '.
           05  FILLER                    PIC X(12) VALUE 'EXPIRY DATE '.
           05  FILLER                    PIC X(34) VALUE SPACES.

       01  WS-RPT-DETAIL.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-CARD-NUM          PIC X(16).
           05  WS-RPT-ACCT              PIC X(14).
           05  WS-RPT-CUST-NAME         PIC X(30).
           05  WS-RPT-TYPE              PIC X(06).
           05  WS-RPT-STATUS            PIC X(08).
           05  WS-RPT-ISSUE-DT          PIC X(12).
           05  WS-RPT-EXPIRY-DT         PIC X(12).
           05  FILLER                    PIC X(34) VALUE SPACES.

       01  WS-RPT-SUMMARY.
           05  FILLER                    PIC X(01) VALUE '0'.
           05  FILLER                    PIC X(30) VALUE
               'PROCESSING SUMMARY            '.
           05  FILLER                    PIC X(102) VALUE SPACES.

       01  WS-RPT-SUM-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-SUM-LABEL         PIC X(40).
           05  WS-RPT-SUM-COUNT         PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(81) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-RECORDS
               UNTIL WS-EOF
           PERFORM 3000-WRITE-SUMMARY
           PERFORM 9000-TERMINATE
           STOP RUN.

      ******************************************************************
      * 1000-INITIALIZE: OPEN FILES, INITIALIZE WORK AREAS            *
      ******************************************************************
       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING

           OPEN INPUT  CARD-INPUT-FILE
           OPEN OUTPUT CARD-OUTPUT-FILE
                       CARD-ERROR-FILE
                       CARD-REPORT-FILE

           IF WS-INP-FILE-STATUS NOT = '00'
               MOVE 'OPEN CARD-INPUT-FILE FAILED'
                   TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE CARD-REPORT-RECORD FROM WS-RPT-HEADER-1
           WRITE CARD-REPORT-RECORD FROM WS-RPT-HEADER-2

           PERFORM 2100-READ-INPUT
           .

      ******************************************************************
      * 2000-PROCESS-RECORDS: MAIN PROCESSING LOOP                    *
      ******************************************************************
       2000-PROCESS-RECORDS.
           MOVE CARD-INPUT-RECORD TO WS-INPUT-REC
           ADD 1 TO WS-RECORDS-READ

           PERFORM 2200-VALIDATE-INPUT

           IF WS-CONTINUE-PROCESS
               PERFORM 2300-GENERATE-CARD-NUMBER
               PERFORM 2400-INSERT-DB2
               PERFORM 2500-WRITE-OUTPUT
               PERFORM 2600-WRITE-REPORT-DETAIL
           ELSE
               PERFORM 2700-WRITE-ERROR
               ADD 1 TO WS-RECORDS-REJECTED
               SET WS-CONTINUE-PROCESS TO TRUE
           END-IF

           PERFORM 2100-READ-INPUT
           .

      ******************************************************************
      * 2100-READ-INPUT: READ NEXT INPUT RECORD                       *
      ******************************************************************
       2100-READ-INPUT.
           READ CARD-INPUT-FILE
               INTO CARD-INPUT-RECORD
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

      ******************************************************************
      * 2200-VALIDATE-INPUT: VALIDATE INPUT RECORD FIELDS             *
      ******************************************************************
       2200-VALIDATE-INPUT.
           SET WS-CONTINUE-PROCESS TO TRUE

           IF WS-INP-REQUEST-TYPE NOT = 'NC'
              AND WS-INP-REQUEST-TYPE NOT = 'RC'
               MOVE 'INVALID REQUEST TYPE'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-INP-ACCOUNT-NUMBER = SPACES
               MOVE 'ACCOUNT NUMBER IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-INP-CUSTOMER-ID = SPACES
               MOVE 'CUSTOMER ID IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-INP-FIRST-NAME = SPACES
              OR WS-INP-LAST-NAME = SPACES
               MOVE 'CUSTOMER NAME IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-INP-CARD-TYPE NOT = 'DB'
              AND WS-INP-CARD-TYPE NOT = 'PP'
               MOVE 'INVALID CARD TYPE'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF
           .

      ******************************************************************
      * 2300-GENERATE-CARD-NUMBER: GENERATE 16-DIGIT CARD NUMBER      *
      *        USING BIN PREFIX + SEQUENCE + LUHN CHECK DIGIT         *
      ******************************************************************
       2300-GENERATE-CARD-NUMBER.
           ADD 1 TO WS-CARD-SEQ-NUM

           STRING WS-BIN-PREFIX
                  WS-CARD-SEQ-NUM
               DELIMITED BY SIZE
               INTO WS-GENERATED-CARD-NUM
           END-STRING

      *    CALCULATE LUHN CHECK DIGIT
           MOVE ZEROS TO WS-LUHN-SUM
           PERFORM VARYING WS-LUHN-IDX FROM 1 BY 1
               UNTIL WS-LUHN-IDX > 15
               COMPUTE WS-LUHN-DIGIT =
                   FUNCTION ORD(
                       WS-GENERATED-CARD-NUM(WS-LUHN-IDX:1)) - 48
               IF FUNCTION MOD(WS-LUHN-IDX, 2) = 1
                   COMPUTE WS-LUHN-TEMP = WS-LUHN-DIGIT * 2
                   IF WS-LUHN-TEMP > 9
                       SUBTRACT 9 FROM WS-LUHN-TEMP
                   END-IF
                   ADD WS-LUHN-TEMP TO WS-LUHN-SUM
               ELSE
                   ADD WS-LUHN-DIGIT TO WS-LUHN-SUM
               END-IF
           END-PERFORM

           COMPUTE WS-CHECK-DIGIT =
               FUNCTION MOD((10 - FUNCTION MOD(WS-LUHN-SUM, 10)), 10)
           MOVE WS-CHECK-DIGIT TO
               WS-GENERATED-CARD-NUM(16:1)
           .

      ******************************************************************
      * 2400-INSERT-DB2: INSERT NEW CARD INTO DB2 CARD MASTER         *
      ******************************************************************
       2400-INSERT-DB2.
           MOVE WS-GENERATED-CARD-NUM  TO HV-CARD-NUMBER
           MOVE WS-INP-CARD-TYPE       TO HV-CARD-TYPE
           MOVE WS-INP-ACCOUNT-NUMBER  TO HV-ACCOUNT-NUMBER
           MOVE WS-INP-CUSTOMER-ID     TO HV-CUSTOMER-ID
           MOVE WS-INP-FIRST-NAME      TO HV-FIRST-NAME
           MOVE WS-INP-LAST-NAME       TO HV-LAST-NAME
           MOVE WS-INP-ADDR-LINE1      TO HV-ADDR-LINE1
           MOVE WS-INP-ADDR-LINE2      TO HV-ADDR-LINE2
           MOVE WS-INP-CITY            TO HV-CITY
           MOVE WS-INP-STATE           TO HV-STATE
           MOVE WS-INP-ZIP-CODE        TO HV-ZIP-CODE
           MOVE 'NW'                   TO HV-CARD-STATUS
           MOVE WS-FORMATTED-DATE      TO HV-ISSUE-DATE
           MOVE WS-INP-DAILY-LIMIT     TO HV-DAILY-LIMIT
           MOVE WS-INP-BRANCH-CODE     TO HV-BRANCH-CODE

      *    CALCULATE EXPIRY DATE (3 YEARS FROM ISSUE)
           MOVE WS-CURRENT-YEAR TO WS-EXP-YEAR
           ADD WS-CARD-VALIDITY-YEARS TO WS-EXP-YEAR
           MOVE WS-CURRENT-MONTH TO WS-EXP-MONTH
           STRING WS-EXP-YEAR '-'
                  WS-EXP-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO HV-EXPIRY-DATE
           END-STRING

           EXEC SQL
               INSERT INTO TB_CARD_MASTER
               (CARD_NUMBER, CARD_TYPE, ACCOUNT_NUMBER,
                CUSTOMER_ID, FIRST_NAME, LAST_NAME,
                ADDR_LINE1, ADDR_LINE2, CITY, STATE, ZIP_CODE,
                CARD_STATUS, ISSUE_DATE, EXPIRY_DATE,
                DAILY_LIMIT, BRANCH_CODE, CREATED_TIMESTAMP)
               VALUES
               (:HV-CARD-NUMBER, :HV-CARD-TYPE,
                :HV-ACCOUNT-NUMBER, :HV-CUSTOMER-ID,
                :HV-FIRST-NAME, :HV-LAST-NAME,
                :HV-ADDR-LINE1, :HV-ADDR-LINE2,
                :HV-CITY, :HV-STATE, :HV-ZIP-CODE,
                :HV-CARD-STATUS, :HV-ISSUE-DATE,
                :HV-EXPIRY-DATE, :HV-DAILY-LIMIT,
                :HV-BRANCH-CODE, CURRENT TIMESTAMP)
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-RECORDS-WRITTEN
               WHEN -803
                   MOVE 'DUPLICATE CARD - DB2 INSERT FAILED'
                       TO WS-ERR-MESSAGE
                   PERFORM 2700-WRITE-ERROR
                   ADD 1 TO WS-RECORDS-REJECTED
               WHEN OTHER
                   MOVE SQLCODE TO WS-ERR-SQLCODE
                   MOVE 'DB2 INSERT FAILED'
                       TO WS-ERR-MESSAGE
                   MOVE 'S' TO WS-ERR-SEVERITY
                   PERFORM 8000-ERROR-HANDLER
           END-EVALUATE
           .

      ******************************************************************
      * 2500-WRITE-OUTPUT: WRITE CONFIRMED CARD TO OUTPUT FILE         *
      ******************************************************************
       2500-WRITE-OUTPUT.
           INITIALIZE CARD-OUTPUT-RECORD
           MOVE WS-GENERATED-CARD-NUM TO CARD-OUTPUT-RECORD(1:16)
           MOVE WS-INP-ACCOUNT-NUMBER TO CARD-OUTPUT-RECORD(17:12)
           MOVE WS-INP-CUSTOMER-ID    TO CARD-OUTPUT-RECORD(29:10)
           MOVE WS-INP-FIRST-NAME     TO CARD-OUTPUT-RECORD(39:25)
           MOVE WS-INP-LAST-NAME      TO CARD-OUTPUT-RECORD(64:25)
           MOVE HV-CARD-STATUS        TO CARD-OUTPUT-RECORD(89:02)
           MOVE HV-ISSUE-DATE         TO CARD-OUTPUT-RECORD(91:10)
           MOVE HV-EXPIRY-DATE        TO CARD-OUTPUT-RECORD(101:10)

           WRITE CARD-OUTPUT-RECORD
           .

      ******************************************************************
      * 2600-WRITE-REPORT-DETAIL: WRITE DETAIL LINE TO REPORT         *
      ******************************************************************
       2600-WRITE-REPORT-DETAIL.
           INITIALIZE WS-RPT-DETAIL
           MOVE WS-GENERATED-CARD-NUM       TO WS-RPT-CARD-NUM
           MOVE WS-INP-ACCOUNT-NUMBER       TO WS-RPT-ACCT
           STRING WS-INP-FIRST-NAME DELIMITED BY '  '
                  ' ' DELIMITED BY SIZE
                  WS-INP-LAST-NAME DELIMITED BY '  '
               INTO WS-RPT-CUST-NAME
           END-STRING
           MOVE WS-INP-CARD-TYPE            TO WS-RPT-TYPE
           MOVE HV-CARD-STATUS              TO WS-RPT-STATUS
           MOVE HV-ISSUE-DATE               TO WS-RPT-ISSUE-DT
           MOVE HV-EXPIRY-DATE              TO WS-RPT-EXPIRY-DT

           WRITE CARD-REPORT-RECORD FROM WS-RPT-DETAIL
           .

      ******************************************************************
      * 2700-WRITE-ERROR: WRITE REJECTED RECORD TO ERROR FILE         *
      ******************************************************************
       2700-WRITE-ERROR.
           INITIALIZE CARD-ERROR-RECORD
           MOVE CARD-INPUT-RECORD TO CARD-ERROR-RECORD(1:300)
           MOVE WS-ERR-MESSAGE    TO CARD-ERROR-RECORD(301:80)
           WRITE CARD-ERROR-RECORD
           .

      ******************************************************************
      * 3000-WRITE-SUMMARY: WRITE PROCESSING SUMMARY TO REPORT        *
      ******************************************************************
       3000-WRITE-SUMMARY.
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUMMARY

           MOVE 'TOTAL RECORDS READ:     '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ              TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS ISSUED:     '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-WRITTEN           TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL RECORDS REJECTED: '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-REJECTED          TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

      ******************************************************************
      * 8000-ERROR-HANDLER: CENTRALIZED ERROR HANDLING                 *
      ******************************************************************
       8000-ERROR-HANDLER.
           MOVE WS-PROGRAM-ID TO WS-ERR-PROGRAM-ID

           DISPLAY '*** ERROR IN PROGRAM: ' WS-ERR-PROGRAM-ID
           DISPLAY '*** MESSAGE: ' WS-ERR-MESSAGE
           DISPLAY '*** SQLCODE: ' WS-ERR-SQLCODE

           IF WS-ERR-SEVERE OR WS-ERR-CRITICAL
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF
           .

      ******************************************************************
      * 9000-TERMINATE: CLOSE FILES, COMMIT AND CLEANUP                *
      ******************************************************************
       9000-TERMINATE.
           IF WS-RETURN-CODE > 0
               EXEC SQL ROLLBACK END-EXEC
               DISPLAY 'PICRD100 DB2 ROLLBACK PERFORMED'
           ELSE
               EXEC SQL COMMIT END-EXEC
           END-IF

           CLOSE CARD-INPUT-FILE
                 CARD-OUTPUT-FILE
                 CARD-ERROR-FILE
                 CARD-REPORT-FILE

           DISPLAY 'PICRD100 PROCESSING COMPLETE'
           DISPLAY 'RECORDS READ:    ' WS-RECORDS-READ
           DISPLAY 'RECORDS WRITTEN: ' WS-RECORDS-WRITTEN
           DISPLAY 'RECORDS REJECTED:' WS-RECORDS-REJECTED

           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
