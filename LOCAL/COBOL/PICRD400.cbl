       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD400.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PICRD400 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD RENEWAL BATCH PROGRAM    *
      *              READS CARD MASTER INDEXED FILE SEQUENTIALLY,      *
      *              IDENTIFIES CARDS EXPIRING WITHIN 60 DAYS,         *
      *              GENERATES REPLACEMENT CARDS WITH NEW EXPIRY.      *
      * INPUT:       CARDMAST - CARD MASTER INDEXED FILE (I-O)        *
      * OUTPUT:      RENWOUT  - RENEWAL CARDS OUTPUT FILE              *
      *              RENWRPT  - RENEWAL SUMMARY REPORT                 *
      * NOTE:        DB2 CURSOR REPLACED WITH SEQUENTIAL READ ON       *
      *              INDEXED FILE + IN-MEMORY FILTERING                *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CARD-MASTER-FILE
               ASSIGN TO "DATA/CARDMAST.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

           SELECT RENEWAL-OUTPUT-FILE
               ASSIGN TO "OUTPUT/RENWOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT RENEWAL-REPORT-FILE
               ASSIGN TO "OUTPUT/RENWRPT.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       FD  RENEWAL-OUTPUT-FILE
           RECORD CONTAINS 200 CHARACTERS.
       01  RENEWAL-OUTPUT-RECORD          PIC X(200).

       FD  RENEWAL-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  RENEWAL-REPORT-RECORD          PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD400'.

       01  WS-CM-FILE-STATUS              PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYCRD01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * RENEWAL PARAMETERS
       01  WS-RENEWAL-PARAMS.
           05  WS-LOOK-AHEAD-DAYS        PIC 9(03) VALUE 060.
           05  WS-RENEWAL-YEARS          PIC 9(02) VALUE 03.
           05  WS-CUTOFF-DATE            PIC X(10).

      * DATE CALCULATION WORK AREAS
       01  WS-DATE-CALC.
           05  WS-CALC-YEAR              PIC 9(04).
           05  WS-CALC-MONTH             PIC 9(02).
           05  WS-CALC-DAY               PIC 9(02).
           05  WS-CALC-INTEGER-DATE      PIC 9(07).
           05  WS-CALC-YYYYMMDD          PIC 9(08).
           05  WS-CALC-YYYYMMDD-X REDEFINES WS-CALC-YYYYMMDD.
               10  WS-CALC-YYYY          PIC X(04).
               10  WS-CALC-MM            PIC X(02).
               10  WS-CALC-DD            PIC X(02).
           05  WS-EXPIRY-YEAR            PIC 9(04).

      * NEW CARD WORK AREAS
       01  WS-NEW-CARD-NUMBER            PIC X(16).
       01  WS-NEW-EXPIRY-DATE            PIC X(10).
       01  WS-OLD-CARD-NUMBER            PIC X(16).
       01  WS-OLD-EXPIRY-DATE            PIC X(10).

      * LUHN WORK AREAS
       01  WS-LUHN-SUM                   PIC 9(03) VALUE 0.
       01  WS-LUHN-DIGIT                 PIC 9(02) VALUE 0.
       01  WS-LUHN-IDX                   PIC 9(02) VALUE 0.
       01  WS-LUHN-TEMP                  PIC 9(02) VALUE 0.
       01  WS-CHECK-DIGIT                PIC 9(01) VALUE 0.

      * CARD SEQUENCE FOR RENEWALS
       01  WS-RENEW-SEQ                   PIC 9(09) VALUE 500.
       01  WS-SCANNED-COUNT               PIC 9(09) VALUE ZEROS.

      * RENEWAL CARD RECORD (TEMP STORAGE)
       01  WS-RENEWAL-CARD               PIC X(400).

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
      *    USE INTEGER-OF-DATE / DATE-OF-INTEGER FOR PROPER
      *    CALENDAR ARITHMETIC (HANDLES MONTH/YEAR ROLLOVER)
           COMPUTE WS-CALC-YYYYMMDD =
               (WS-CURRENT-YEAR * 10000) +
               (WS-CURRENT-MONTH * 100) +
               WS-CURRENT-DAY
           COMPUTE WS-CALC-INTEGER-DATE =
               FUNCTION INTEGER-OF-DATE(WS-CALC-YYYYMMDD)
           ADD WS-LOOK-AHEAD-DAYS TO WS-CALC-INTEGER-DATE
           COMPUTE WS-CALC-YYYYMMDD =
               FUNCTION DATE-OF-INTEGER(WS-CALC-INTEGER-DATE)
           STRING WS-CALC-YYYY '-'
                  WS-CALC-MM '-'
                  WS-CALC-DD
               DELIMITED BY SIZE
               INTO WS-CUTOFF-DATE
           END-STRING

           DISPLAY 'PICRD400 - RENEWAL CUTOFF DATE: '
               WS-CUTOFF-DATE

           OPEN I-O    CARD-MASTER-FILE
           OPEN OUTPUT RENEWAL-OUTPUT-FILE
                       RENEWAL-REPORT-FILE

           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               STOP RUN
           END-IF
           .

      ******************************************************************
      * 2000-PROCESS-RENEWALS: SCAN ALL CARDS SEQUENTIALLY            *
      *   FOR EACH ACTIVE CARD EXPIRING BEFORE CUTOFF DATE:           *
      *     - GENERATE NEW CARD NUMBER WITH LUHN CHECK                *
      *     - CALCULATE NEW EXPIRY (3 YEARS FROM TODAY)               *
      *     - WRITE NEW CARD TO MASTER FILE                           *
      *     - UPDATE OLD CARD STATUS TO EXPIRED                       *
      *     - WRITE RENEWAL OUTPUT RECORD                             *
      ******************************************************************
       2000-PROCESS-RENEWALS.
      *    START SEQUENTIAL READ FROM BEGINNING
           MOVE LOW-VALUES TO CM-CARD-NUMBER
           START CARD-MASTER-FILE
               KEY IS NOT LESS THAN CM-CARD-NUMBER
               INVALID KEY
                   DISPLAY 'CARD MASTER FILE IS EMPTY'
                   SET WS-EOF TO TRUE
               NOT INVALID KEY
                   CONTINUE
           END-START

           PERFORM UNTIL WS-EOF
               READ CARD-MASTER-FILE NEXT
                   INTO WS-CARD-MASTER-REC
                   AT END
                       SET WS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-SCANNED-COUNT
                       PERFORM 2100-CHECK-RENEWAL
               END-READ
           END-PERFORM
           .

      ******************************************************************
      * 2100-CHECK-RENEWAL: FILTER FOR RENEWAL CANDIDATES             *
      *   CRITERIA: STATUS = 'AC' AND EXPIRY <= CUTOFF DATE           *
      ******************************************************************
       2100-CHECK-RENEWAL.
           IF WS-CM-CARD-STATUS = 'AC'
              AND WS-CM-EXPIRY-DATE <= WS-CUTOFF-DATE
               ADD 1 TO WS-RECORDS-READ
               PERFORM 2200-GENERATE-RENEWAL
               PERFORM 2300-WRITE-NEW-CARD
               PERFORM 2400-EXPIRE-OLD-CARD
               PERFORM 2500-WRITE-OUTPUT
           END-IF
           .

      ******************************************************************
      * 2200-GENERATE-RENEWAL: BUILD NEW CARD NUMBER + EXPIRY         *
      ******************************************************************
       2200-GENERATE-RENEWAL.
           MOVE WS-CM-CARD-NUMBER TO WS-OLD-CARD-NUMBER
           MOVE WS-CM-EXPIRY-DATE TO WS-OLD-EXPIRY-DATE
           ADD 1 TO WS-RENEW-SEQ

      *    BUILD 15-DIGIT BASE NUMBER
           INITIALIZE WS-NEW-CARD-NUMBER
           STRING '400012'
                  WS-RENEW-SEQ
               DELIMITED BY SIZE
               INTO WS-NEW-CARD-NUMBER
           END-STRING

      *    COMPUTE LUHN CHECK DIGIT FOR POSITION 16
           MOVE 0 TO WS-LUHN-SUM
           PERFORM VARYING WS-LUHN-IDX FROM 1 BY 1
               UNTIL WS-LUHN-IDX > 15
               COMPUTE WS-LUHN-DIGIT =
                   FUNCTION ORD(
                       WS-NEW-CARD-NUMBER(WS-LUHN-IDX:1)) - 48
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
                   (10 - FUNCTION MOD(WS-LUHN-SUM, 10)), 10)
           MOVE WS-CHECK-DIGIT TO WS-NEW-CARD-NUMBER(16:1)

      *    CALCULATE NEW EXPIRY (RENEWAL-YEARS FROM NOW)
           COMPUTE WS-EXPIRY-YEAR = WS-CURRENT-YEAR
                                  + WS-RENEWAL-YEARS
           STRING WS-EXPIRY-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-NEW-EXPIRY-DATE
           END-STRING
           .

      ******************************************************************
      * 2300-WRITE-NEW-CARD: INSERT RENEWAL CARD INTO MASTER FILE     *
      ******************************************************************
       2300-WRITE-NEW-CARD.
      *    BUILD NEW CARD RECORD BASED ON OLD CARD DATA
           MOVE WS-NEW-CARD-NUMBER    TO WS-CM-CARD-NUMBER
           MOVE 'NW'                   TO WS-CM-CARD-STATUS
           MOVE WS-FORMATTED-DATE     TO WS-CM-ISSUE-DATE
           MOVE WS-NEW-EXPIRY-DATE    TO WS-CM-EXPIRY-DATE
           MOVE SPACES                 TO WS-CM-ACTIVATION-DATE
           MOVE SPACES                 TO WS-CM-LAST-USED-DATE
           MOVE SPACES                 TO WS-CM-PIN-OFFSET

           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY '-'
                  WS-CURRENT-HOUR '.'
                  WS-CURRENT-MIN '.'
                  WS-CURRENT-SEC
               DELIMITED BY SIZE
               INTO WS-CM-CREATED-TIMESTAMP
           END-STRING

      *    SAVE THE RENEWAL CARD RECORD
           MOVE WS-CARD-MASTER-REC TO WS-RENEWAL-CARD

      *    WRITE NEW CARD
           MOVE WS-RENEWAL-CARD TO CARD-MASTER-RECORD
           WRITE CARD-MASTER-RECORD

           IF WS-CM-FILE-STATUS = '00'
               ADD 1 TO WS-RECORDS-WRITTEN
               DISPLAY '  RENEWAL: ' WS-OLD-CARD-NUMBER
                   ' -> ' WS-NEW-CARD-NUMBER
           ELSE
               DISPLAY '*** NEW CARD WRITE ERROR: '
                   WS-CM-FILE-STATUS
                   ' CARD=' WS-NEW-CARD-NUMBER
               MOVE 'RENEWAL INSERT FAILED' TO WS-ERR-MESSAGE
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

      ******************************************************************
      * 2400-EXPIRE-OLD-CARD: MARK OLD CARD AS EXPIRED VIA REWRITE   *
      ******************************************************************
       2400-EXPIRE-OLD-CARD.
      *    RE-READ THE OLD CARD FOR REWRITE
           MOVE WS-OLD-CARD-NUMBER TO CM-CARD-NUMBER
           READ CARD-MASTER-FILE
               INTO WS-CARD-MASTER-REC
               KEY IS CM-CARD-NUMBER
               INVALID KEY
                   DISPLAY '*** CANNOT RE-READ OLD CARD: '
                       WS-OLD-CARD-NUMBER
               NOT INVALID KEY
                   MOVE 'EX' TO WS-CM-CARD-STATUS
                   MOVE WS-CARD-MASTER-REC TO CARD-MASTER-RECORD
                   REWRITE CARD-MASTER-RECORD
                   IF WS-CM-FILE-STATUS NOT = '00'
                       DISPLAY '*** OLD CARD REWRITE ERROR: '
                           WS-CM-FILE-STATUS
                   END-IF
           END-READ
           .

       2500-WRITE-OUTPUT.
           INITIALIZE RENEWAL-OUTPUT-RECORD
           MOVE WS-OLD-CARD-NUMBER    TO RENEWAL-OUTPUT-RECORD(1:16)
           MOVE WS-NEW-CARD-NUMBER    TO RENEWAL-OUTPUT-RECORD(17:16)
           MOVE WS-CM-ACCOUNT-NUMBER  TO RENEWAL-OUTPUT-RECORD(33:12)
           MOVE WS-CM-CUSTOMER-ID     TO RENEWAL-OUTPUT-RECORD(45:10)
           MOVE WS-OLD-EXPIRY-DATE    TO RENEWAL-OUTPUT-RECORD(55:10)
           MOVE WS-NEW-EXPIRY-DATE    TO RENEWAL-OUTPUT-RECORD(65:10)
           WRITE RENEWAL-OUTPUT-RECORD
           .

       3000-WRITE-SUMMARY.
           MOVE 'TOTAL CARDS SCANNED:       ' TO WS-RPT-SUM-LABEL
           MOVE WS-SCANNED-COUNT               TO WS-RPT-SUM-COUNT
           WRITE RENEWAL-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'CARDS DUE FOR RENEWAL:     ' TO WS-RPT-SUM-LABEL
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
           CLOSE CARD-MASTER-FILE
                 RENEWAL-OUTPUT-FILE
                 RENEWAL-REPORT-FILE
           DISPLAY 'PICRD400 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
