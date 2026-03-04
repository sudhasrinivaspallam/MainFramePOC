       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD200.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PICRD200 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD ACTIVATION BATCH         *
      *              READS ACTIVATION REQUESTS, VALIDATES CARD EXISTS, *
      *              UPDATES STATUS FROM 'NW' TO 'AC'.                *
      * INPUT:       ACTVINP  - ACTIVATION REQUEST FILE                *
      * OUTPUT:      ACTVOUT  - ACTIVATION CONFIRMATION FILE           *
      *              ACTVERR  - REJECTED ACTIVATIONS FILE              *
      *              ACTVRPT  - ACTIVATION SUMMARY REPORT              *
      *              CARDMAST - CARD MASTER INDEXED FILE (I-O)         *
      * NOTE:        DB2 SELECT/UPDATE REPLACED WITH INDEXED READ/     *
      *              REWRITE ON CARD MASTER FILE.                      *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACTV-INPUT-FILE
               ASSIGN TO "DATA/ACTVINP.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT ACTV-OUTPUT-FILE
               ASSIGN TO "OUTPUT/ACTVOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT ACTV-ERROR-FILE
               ASSIGN TO "OUTPUT/ACTVERR.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERROUT-STATUS.

           SELECT ACTV-REPORT-FILE
               ASSIGN TO "OUTPUT/ACTVRPT.txt"
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

       FD  ACTV-INPUT-FILE
           RECORD CONTAINS 80 CHARACTERS.
       01  ACTV-INPUT-RECORD              PIC X(80).

       FD  ACTV-OUTPUT-FILE
           RECORD CONTAINS 120 CHARACTERS.
       01  ACTV-OUTPUT-RECORD             PIC X(120).

       FD  ACTV-ERROR-FILE
           RECORD CONTAINS 160 CHARACTERS.
       01  ACTV-ERROR-RECORD              PIC X(160).

       FD  ACTV-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  ACTV-REPORT-RECORD             PIC X(133).

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD200'.

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

      * INPUT RECORD LAYOUT
       01  WS-ACTV-INPUT-REC.
           05  WS-ACTV-CARD-NUMBER        PIC X(16).
           05  WS-ACTV-CUSTOMER-ID        PIC X(10).
           05  WS-ACTV-PIN-OFFSET         PIC X(04).
           05  WS-ACTV-CHANNEL            PIC X(02).
               88  WS-ACTV-CHAN-BRANCH    VALUE 'BR'.
               88  WS-ACTV-CHAN-PHONE     VALUE 'PH'.
               88  WS-ACTV-CHAN-ONLINE    VALUE 'OL'.
           05  FILLER                     PIC X(48).

      * REPORT LINES
       01  WS-RPT-HEADER.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               'PLASTIC ISSUANCE - CARD ACTIVATION REPORT'.
           05  FILLER                    PIC X(30) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-DETAIL-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-CARD-NUM          PIC X(18).
           05  WS-RPT-CUST-ID           PIC X(12).
           05  WS-RPT-STATUS-FROM       PIC X(04).
           05  FILLER                    PIC X(04) VALUE ' -> '.
           05  WS-RPT-STATUS-TO         PIC X(04).
           05  WS-RPT-CHANNEL           PIC X(10).
           05  WS-RPT-ACTV-DATE         PIC X(12).
           05  FILLER                    PIC X(68) VALUE SPACES.

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
      * 1000-INITIALIZE: OPEN FILES, WRITE HEADERS                    *
      ******************************************************************
       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING

           OPEN INPUT  ACTV-INPUT-FILE
           OPEN OUTPUT ACTV-OUTPUT-FILE
                       ACTV-ERROR-FILE
                       ACTV-REPORT-FILE
           OPEN I-O    CARD-MASTER-FILE

           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               STOP RUN
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE ACTV-REPORT-RECORD FROM WS-RPT-HEADER

           PERFORM 2100-READ-INPUT
           .

      ******************************************************************
      * 2000-PROCESS-RECORDS: MAIN PROCESSING LOOP                    *
      ******************************************************************
       2000-PROCESS-RECORDS.
           MOVE ACTV-INPUT-RECORD TO WS-ACTV-INPUT-REC
           ADD 1 TO WS-RECORDS-READ

           PERFORM 2200-VALIDATE-AND-FETCH

           IF WS-CONTINUE-PROCESS
               PERFORM 2300-ACTIVATE-CARD
               PERFORM 2400-WRITE-OUTPUT
               PERFORM 2500-WRITE-REPORT
           ELSE
               PERFORM 2600-WRITE-ERROR
               ADD 1 TO WS-RECORDS-REJECTED
               SET WS-CONTINUE-PROCESS TO TRUE
           END-IF

           PERFORM 2100-READ-INPUT
           .

      ******************************************************************
      * 2100-READ-INPUT: READ NEXT ACTIVATION REQUEST                 *
      ******************************************************************
       2100-READ-INPUT.
           READ ACTV-INPUT-FILE
               INTO ACTV-INPUT-RECORD
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

      ******************************************************************
      * 2200-VALIDATE-AND-FETCH: VALIDATE AND READ CARD FROM FILE     *
      *   BUSINESS RULES:                                              *
      *   - Card number must not be blank                              *
      *   - Card must exist in master file                             *
      *   - Card must be in 'NW' (New) status                         *
      *   - Customer ID must match card record                        *
      *   - Channel must be BR/PH/OL                                  *
      ******************************************************************
       2200-VALIDATE-AND-FETCH.
           SET WS-CONTINUE-PROCESS TO TRUE

           IF WS-ACTV-CARD-NUMBER = SPACES
               MOVE 'CARD NUMBER IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           ELSE
      *        VALIDATE CHANNEL
               IF NOT (WS-ACTV-CHAN-BRANCH
                  OR WS-ACTV-CHAN-PHONE
                  OR WS-ACTV-CHAN-ONLINE)
                   MOVE 'INVALID ACTIVATION CHANNEL'
                       TO WS-ERR-MESSAGE
                   SET WS-STOP-PROCESS TO TRUE
               ELSE
      *            READ CARD FROM INDEXED FILE
                   MOVE WS-ACTV-CARD-NUMBER TO CM-CARD-NUMBER
                   READ CARD-MASTER-FILE
                       INTO WS-CARD-MASTER-REC
                       KEY IS CM-CARD-NUMBER
                       INVALID KEY
                           MOVE 'CARD NOT FOUND IN MASTER FILE'
                               TO WS-ERR-MESSAGE
                           SET WS-STOP-PROCESS TO TRUE
                       NOT INVALID KEY
                           IF WS-CM-CARD-STATUS NOT = 'NW'
                               STRING
                                   'CARD NOT IN NEW STATUS: '
                                   WS-CM-CARD-STATUS
                                   DELIMITED BY SIZE
                                   INTO WS-ERR-MESSAGE
                               END-STRING
                               SET WS-STOP-PROCESS TO TRUE
                           END-IF
                           IF WS-CM-CUSTOMER-ID NOT =
                              WS-ACTV-CUSTOMER-ID
                               MOVE 'CUSTOMER ID MISMATCH'
                                   TO WS-ERR-MESSAGE
                               SET WS-STOP-PROCESS TO TRUE
                           END-IF
                   END-READ
               END-IF
           END-IF
           .

      ******************************************************************
      * 2300-ACTIVATE-CARD: UPDATE CARD STATUS VIA REWRITE            *
      *   BUSINESS RULES: NW -> AC only                                *
      ******************************************************************
       2300-ACTIVATE-CARD.
           MOVE 'AC'                   TO WS-CM-CARD-STATUS
           MOVE WS-FORMATTED-DATE     TO WS-CM-ACTIVATION-DATE
           MOVE WS-ACTV-PIN-OFFSET    TO WS-CM-PIN-OFFSET

           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY '-'
                  WS-CURRENT-HOUR '.'
                  WS-CURRENT-MIN '.'
                  WS-CURRENT-SEC
               DELIMITED BY SIZE
               INTO WS-CM-UPDATED-TIMESTAMP
           END-STRING

           MOVE WS-CARD-MASTER-REC TO CARD-MASTER-RECORD
           REWRITE CARD-MASTER-RECORD

           IF WS-CM-FILE-STATUS = '00'
               ADD 1 TO WS-RECORDS-UPDATED
           ELSE
               DISPLAY '*** REWRITE ERROR: ' WS-CM-FILE-STATUS
                   ' CARD=' WS-ACTV-CARD-NUMBER
               MOVE 'CARD UPDATE FAILED'
                   TO WS-ERR-MESSAGE
               PERFORM 2600-WRITE-ERROR
               ADD 1 TO WS-RECORDS-REJECTED
           END-IF
           .

      ******************************************************************
      * 2400-WRITE-OUTPUT: WRITE ACTIVATION CONFIRMATION               *
      ******************************************************************
       2400-WRITE-OUTPUT.
           INITIALIZE ACTV-OUTPUT-RECORD
           MOVE WS-ACTV-CARD-NUMBER   TO ACTV-OUTPUT-RECORD(1:16)
           MOVE WS-ACTV-CUSTOMER-ID   TO ACTV-OUTPUT-RECORD(17:10)
           MOVE 'AC'                   TO ACTV-OUTPUT-RECORD(27:02)
           MOVE WS-FORMATTED-DATE     TO ACTV-OUTPUT-RECORD(29:10)
           MOVE WS-ACTV-CHANNEL       TO ACTV-OUTPUT-RECORD(39:02)
           WRITE ACTV-OUTPUT-RECORD
           .

      ******************************************************************
      * 2500-WRITE-REPORT: WRITE REPORT DETAIL LINE                   *
      ******************************************************************
       2500-WRITE-REPORT.
           INITIALIZE WS-RPT-DETAIL-LINE
           MOVE WS-ACTV-CARD-NUMBER   TO WS-RPT-CARD-NUM
           MOVE WS-ACTV-CUSTOMER-ID   TO WS-RPT-CUST-ID
           MOVE 'NW'                   TO WS-RPT-STATUS-FROM
           MOVE 'AC'                   TO WS-RPT-STATUS-TO
           MOVE WS-ACTV-CHANNEL       TO WS-RPT-CHANNEL
           MOVE WS-FORMATTED-DATE     TO WS-RPT-ACTV-DATE
           WRITE ACTV-REPORT-RECORD FROM WS-RPT-DETAIL-LINE
           .

      ******************************************************************
      * 2600-WRITE-ERROR: WRITE REJECTED RECORD                       *
      ******************************************************************
       2600-WRITE-ERROR.
           INITIALIZE ACTV-ERROR-RECORD
           MOVE ACTV-INPUT-RECORD TO ACTV-ERROR-RECORD(1:80)
           MOVE WS-ERR-MESSAGE    TO ACTV-ERROR-RECORD(81:80)
           WRITE ACTV-ERROR-RECORD
           .

      ******************************************************************
      * 3000-WRITE-SUMMARY: WRITE SUMMARY LINES                       *
      ******************************************************************
       3000-WRITE-SUMMARY.
           MOVE 'TOTAL RECORDS READ:     '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ              TO WS-RPT-SUM-COUNT
           WRITE ACTV-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS ACTIVATED:  '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-UPDATED           TO WS-RPT-SUM-COUNT
           WRITE ACTV-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL RECORDS REJECTED: '  TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-REJECTED          TO WS-RPT-SUM-COUNT
           WRITE ACTV-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

      ******************************************************************
      * 8000-ERROR-HANDLER: CENTRALIZED ERROR HANDLING                 *
      ******************************************************************
       8000-ERROR-HANDLER.
           MOVE WS-PROGRAM-ID TO WS-ERR-PROGRAM-ID
           DISPLAY '*** ERROR IN PROGRAM: ' WS-ERR-PROGRAM-ID
           DISPLAY '*** MESSAGE: ' WS-ERR-MESSAGE
           DISPLAY '*** FILE STATUS: ' WS-CM-FILE-STATUS

           IF WS-ERR-SEVERE OR WS-ERR-CRITICAL
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF
           .

      ******************************************************************
      * 9000-TERMINATE: CLOSE FILES AND CLEANUP                        *
      ******************************************************************
       9000-TERMINATE.
           CLOSE ACTV-INPUT-FILE
                 ACTV-OUTPUT-FILE
                 ACTV-ERROR-FILE
                 ACTV-REPORT-FILE
                 CARD-MASTER-FILE

           DISPLAY 'PICRD200 PROCESSING COMPLETE'
           DISPLAY 'RECORDS READ:    ' WS-RECORDS-READ
           DISPLAY 'CARDS ACTIVATED: ' WS-RECORDS-UPDATED
           DISPLAY 'RECORDS REJECTED:' WS-RECORDS-REJECTED

           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
