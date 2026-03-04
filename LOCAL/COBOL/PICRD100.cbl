       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD100.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PICRD100 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD ISSUANCE BATCH PROGRAM  *
      *              READS NEW CARD REQUESTS FROM INPUT FILE,         *
      *              VALIDATES DATA, GENERATES CARD NUMBERS,          *
      *              AND WRITES TO INDEXED CARD MASTER FILE.          *
      * INPUT:       CARDINP  - NEW CARD REQUEST FILE                 *
      * OUTPUT:      CARDOUT  - ISSUED CARDS CONFIRMATION FILE        *
      *              CARDERR  - REJECTED RECORDS FILE                 *
      *              CARDRPT  - CARD ISSUANCE SUMMARY REPORT          *
      *              CARDMAST - CARD MASTER INDEXED FILE              *
      * NOTE:        DB2 OPERATIONS REPLACED WITH INDEXED FILE I/O    *
      * FREQUENCY:   DAILY BATCH                                      *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CARD-INPUT-FILE
               ASSIGN TO "DATA/CARDINP.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT CARD-OUTPUT-FILE
               ASSIGN TO "DATA/CARDOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT CARD-ERROR-FILE
               ASSIGN TO "DATA/CARDERR.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERROUT-STATUS.

           SELECT CARD-REPORT-FILE
               ASSIGN TO "OUTPUT/CARDRPT.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

           SELECT CARD-MASTER-FILE
               ASSIGN TO "DATA/CARDMAST.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-INPUT-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  CARD-INPUT-RECORD              PIC X(300).

       FD  CARD-OUTPUT-FILE
           RECORD CONTAINS 350 CHARACTERS.
       01  CARD-OUTPUT-RECORD             PIC X(350).

       FD  CARD-ERROR-FILE
           RECORD CONTAINS 380 CHARACTERS.
       01  CARD-ERROR-RECORD              PIC X(380).

       FD  CARD-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  CARD-REPORT-RECORD             PIC X(133).

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD100'.

      * FILE STATUS CODES
       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-ERROUT-STATUS               PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).
       01  WS-CM-FILE-STATUS              PIC X(02).

      * INCLUDE COPYBOOKS
           COPY CPYCRD01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * INPUT RECORD LAYOUT (300 BYTES - DISPLAY NUMERIC)
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
           05  WS-INP-DAILY-LIMIT         PIC 9(09)V99.
           05  WS-INP-BRANCH-CODE         PIC X(06).
           05  FILLER                     PIC X(90).

      * CARD NUMBER GENERATION
       01  WS-CARD-GEN-AREA.
           05  WS-BIN-PREFIX              PIC X(06) VALUE '400012'.
           05  WS-CARD-SEQ-NUM            PIC 9(09) VALUE 100.
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
           05  FILLER                    PIC X(16) VALUE
               'CARD NUMBER     '.
           05  FILLER                    PIC X(14) VALUE
               'ACCOUNT       '.
           05  FILLER                    PIC X(30) VALUE
               'CUSTOMER NAME                 '.
           05  FILLER                    PIC X(06) VALUE 'TYPE  '.
           05  FILLER                    PIC X(08) VALUE 'STATUS  '.
           05  FILLER                    PIC X(12) VALUE
               'ISSUE DATE  '.
           05  FILLER                    PIC X(12) VALUE
               'EXPIRY DATE '.
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
           IF WS-INP-FILE-STATUS NOT = '00'
               MOVE WS-INP-FILE-STATUS TO WS-ERR-FILE-STATUS
               MOVE 'OPEN CARD-INPUT-FILE FAILED'
                   TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF

           OPEN OUTPUT CARD-OUTPUT-FILE
           IF WS-OUT-FILE-STATUS NOT = '00'
               MOVE WS-OUT-FILE-STATUS TO WS-ERR-FILE-STATUS
               MOVE 'OPEN CARD-OUTPUT-FILE FAILED'
                   TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF

           OPEN OUTPUT CARD-ERROR-FILE
           IF WS-ERROUT-STATUS NOT = '00'
               MOVE WS-ERROUT-STATUS TO WS-ERR-FILE-STATUS
               MOVE 'OPEN CARD-ERROR-FILE FAILED'
                   TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF

           OPEN OUTPUT CARD-REPORT-FILE
           IF WS-RPT-FILE-STATUS NOT = '00'
               MOVE WS-RPT-FILE-STATUS TO WS-ERR-FILE-STATUS
               MOVE 'OPEN CARD-REPORT-FILE FAILED'
                   TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF

      *    OPEN CARD MASTER - TRY I-O FIRST, OUTPUT IF NOT FOUND
           OPEN I-O CARD-MASTER-FILE
           IF WS-CM-FILE-STATUS = '35'
               OPEN OUTPUT CARD-MASTER-FILE
           END-IF
           IF WS-CM-FILE-STATUS NOT = '00'
               MOVE WS-CM-FILE-STATUS TO WS-ERR-FILE-STATUS
               MOVE 'OPEN CARD-MASTER-FILE FAILED'
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
               PERFORM 2400-WRITE-CARD-MASTER
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
                   WS-GENERATED-CARD-NUM(WS-LUHN-IDX:1))
                   - 48
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
               FUNCTION MOD(
               (10 - FUNCTION MOD(WS-LUHN-SUM, 10))
               , 10)
           MOVE WS-CHECK-DIGIT TO
               WS-GENERATED-CARD-NUM(16:1)
           .

      ******************************************************************
      * 2400-WRITE-CARD-MASTER: WRITE NEW CARD TO INDEXED FILE        *
      *        REPLACES DB2 INSERT INTO TB_CARD_MASTER                *
      ******************************************************************
       2400-WRITE-CARD-MASTER.
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-GENERATED-CARD-NUM  TO WS-CM-CARD-NUMBER
           MOVE WS-INP-CARD-TYPE       TO WS-CM-CARD-TYPE
           MOVE WS-INP-ACCOUNT-NUMBER  TO WS-CM-ACCOUNT-NUMBER
           MOVE WS-INP-CUSTOMER-ID     TO WS-CM-CUSTOMER-ID
           MOVE WS-INP-FIRST-NAME      TO WS-CM-FIRST-NAME
           MOVE WS-INP-LAST-NAME       TO WS-CM-LAST-NAME
           MOVE WS-INP-ADDR-LINE1      TO WS-CM-ADDR-LINE1
           MOVE WS-INP-ADDR-LINE2      TO WS-CM-ADDR-LINE2
           MOVE WS-INP-CITY            TO WS-CM-CITY
           MOVE WS-INP-STATE           TO WS-CM-STATE
           MOVE WS-INP-ZIP-CODE        TO WS-CM-ZIP-CODE
           MOVE 'NW'                   TO WS-CM-CARD-STATUS
           MOVE WS-FORMATTED-DATE      TO WS-CM-ISSUE-DATE
           MOVE WS-INP-DAILY-LIMIT     TO WS-CM-DAILY-LIMIT
           MOVE ZEROS                  TO WS-CM-AVAILABLE-BALANCE
           MOVE WS-INP-BRANCH-CODE     TO WS-CM-BRANCH-CODE

      *    CALCULATE EXPIRY DATE (3 YEARS FROM ISSUE)
           MOVE WS-CURRENT-YEAR TO WS-EXP-YEAR
           ADD WS-CARD-VALIDITY-YEARS TO WS-EXP-YEAR
           MOVE WS-CURRENT-MONTH TO WS-EXP-MONTH
           STRING WS-EXP-YEAR '-'
                  WS-EXP-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-CM-EXPIRY-DATE
           END-STRING

      *    BUILD CREATED TIMESTAMP (YYYY-MM-DD-HH.MM.SS.000000)
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY '-'
                  WS-CURRENT-HOUR '.'
                  WS-CURRENT-MIN '.'
                  WS-CURRENT-SEC '.000000'
               DELIMITED BY SIZE
               INTO WS-CM-CREATED-TIMESTAMP
           END-STRING
           MOVE WS-CM-CREATED-TIMESTAMP
               TO WS-CM-UPDATED-TIMESTAMP

      *    WRITE RECORD TO INDEXED FILE
           WRITE CARD-MASTER-RECORD
               FROM WS-CARD-MASTER-REC

           EVALUATE WS-CM-FILE-STATUS
               WHEN '00'
                   ADD 1 TO WS-RECORDS-WRITTEN
               WHEN '22'
                   MOVE 'DUPLICATE CARD - WRITE FAILED'
                       TO WS-ERR-MESSAGE
                   PERFORM 2700-WRITE-ERROR
                   ADD 1 TO WS-RECORDS-REJECTED
               WHEN OTHER
                   MOVE WS-CM-FILE-STATUS
                       TO WS-ERR-FILE-STATUS
                   STRING 'CARD MASTER WRITE FAILED FS='
                          WS-CM-FILE-STATUS
                       DELIMITED BY SIZE
                       INTO WS-ERR-MESSAGE
                   END-STRING
                   MOVE 'S' TO WS-ERR-SEVERITY
                   PERFORM 8000-ERROR-HANDLER
           END-EVALUATE
           .

      ******************************************************************
      * 2500-WRITE-OUTPUT: WRITE CONFIRMED CARD TO OUTPUT FILE         *
      ******************************************************************
       2500-WRITE-OUTPUT.
           INITIALIZE CARD-OUTPUT-RECORD
           MOVE WS-GENERATED-CARD-NUM
               TO CARD-OUTPUT-RECORD(1:16)
           MOVE WS-INP-ACCOUNT-NUMBER
               TO CARD-OUTPUT-RECORD(17:12)
           MOVE WS-INP-CUSTOMER-ID
               TO CARD-OUTPUT-RECORD(29:10)
           MOVE WS-INP-FIRST-NAME
               TO CARD-OUTPUT-RECORD(39:25)
           MOVE WS-INP-LAST-NAME
               TO CARD-OUTPUT-RECORD(64:25)
           MOVE WS-CM-CARD-STATUS
               TO CARD-OUTPUT-RECORD(89:02)
           MOVE WS-CM-ISSUE-DATE
               TO CARD-OUTPUT-RECORD(91:10)
           MOVE WS-CM-EXPIRY-DATE
               TO CARD-OUTPUT-RECORD(101:10)

           WRITE CARD-OUTPUT-RECORD
           .

      ******************************************************************
      * 2600-WRITE-REPORT-DETAIL: WRITE DETAIL LINE TO REPORT         *
      ******************************************************************
       2600-WRITE-REPORT-DETAIL.
           INITIALIZE WS-RPT-DETAIL
           MOVE WS-GENERATED-CARD-NUM
               TO WS-RPT-CARD-NUM
           MOVE WS-INP-ACCOUNT-NUMBER
               TO WS-RPT-ACCT
           STRING WS-INP-FIRST-NAME DELIMITED BY '  '
                  ' ' DELIMITED BY SIZE
                  WS-INP-LAST-NAME DELIMITED BY '  '
               INTO WS-RPT-CUST-NAME
           END-STRING
           MOVE WS-INP-CARD-TYPE
               TO WS-RPT-TYPE
           MOVE WS-CM-CARD-STATUS
               TO WS-RPT-STATUS
           MOVE WS-CM-ISSUE-DATE
               TO WS-RPT-ISSUE-DT
           MOVE WS-CM-EXPIRY-DATE
               TO WS-RPT-EXPIRY-DT

           WRITE CARD-REPORT-RECORD FROM WS-RPT-DETAIL
           .

      ******************************************************************
      * 2700-WRITE-ERROR: WRITE REJECTED RECORD TO ERROR FILE         *
      ******************************************************************
       2700-WRITE-ERROR.
           INITIALIZE CARD-ERROR-RECORD
           MOVE CARD-INPUT-RECORD
               TO CARD-ERROR-RECORD(1:300)
           MOVE WS-ERR-MESSAGE
               TO CARD-ERROR-RECORD(301:80)
           WRITE CARD-ERROR-RECORD
           .

      ******************************************************************
      * 3000-WRITE-SUMMARY: WRITE PROCESSING SUMMARY TO REPORT        *
      ******************************************************************
       3000-WRITE-SUMMARY.
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUMMARY

           MOVE 'TOTAL RECORDS READ:     '
               TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ
               TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS ISSUED:     '
               TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-WRITTEN
               TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL RECORDS REJECTED: '
               TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-REJECTED
               TO WS-RPT-SUM-COUNT
           WRITE CARD-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

      ******************************************************************
      * 8000-ERROR-HANDLER: CENTRALIZED ERROR HANDLING                 *
      ******************************************************************
       8000-ERROR-HANDLER.
           MOVE WS-PROGRAM-ID TO WS-ERR-PROGRAM-ID
           ADD 1 TO WS-ERR-COUNT

           DISPLAY '*** ERROR IN PROGRAM: '
               WS-ERR-PROGRAM-ID
           DISPLAY '*** MESSAGE: '
               WS-ERR-MESSAGE
           DISPLAY '*** FILE STATUS: '
               WS-ERR-FILE-STATUS

           IF WS-ERR-SEVERE OR WS-ERR-CRITICAL
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF
           .

      ******************************************************************
      * 9000-TERMINATE: CLOSE ALL FILES AND CLEANUP                    *
      ******************************************************************
       9000-TERMINATE.
           CLOSE CARD-INPUT-FILE
                 CARD-OUTPUT-FILE
                 CARD-ERROR-FILE
                 CARD-REPORT-FILE
                 CARD-MASTER-FILE

           DISPLAY 'PICRD100 PROCESSING COMPLETE'
           DISPLAY 'RECORDS READ:     '
               WS-RECORDS-READ
           DISPLAY 'RECORDS WRITTEN:  '
               WS-RECORDS-WRITTEN
           DISPLAY 'RECORDS REJECTED: '
               WS-RECORDS-REJECTED

           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
