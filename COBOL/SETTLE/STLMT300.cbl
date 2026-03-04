       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT300.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     STLMT300                                          *
      * DESCRIPTION: SETTLEMENT - RECONCILIATION PROGRAM               *
      *              READS MATCHED OUTPUT, BUILDS SUMMARY BY NETWORK,  *
      *              CALCULATES NET SETTLEMENT, WRITES SUMMARY VSAM.   *
      * INPUT:       STLMTCH  - MATCHED TRANSACTIONS FILE              *
      * OUTPUT:      SUMVSAM  - SETTLEMENT SUMMARY VSAM KSDS          *
      *              RECONRPT - RECONCILIATION REPORT                  *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MATCH-INPUT-FILE
               ASSIGN TO STLMTCH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT SUMMARY-VSAM-FILE
               ASSIGN TO SUMVSAM
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS SUM-VSAM-KEY
               FILE STATUS IS WS-VSAM-FILE-STATUS.

           SELECT RECON-REPORT-FILE
               ASSIGN TO RECONRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  MATCH-INPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 300 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  MATCH-INPUT-RECORD             PIC X(300).

       FD  SUMMARY-VSAM-FILE.
       01  SUMMARY-VSAM-RECORD.
           05  SUM-VSAM-KEY.
               10  SUM-VSAM-DATE          PIC X(10).
               10  SUM-VSAM-NETWORK       PIC X(04).
           05  SUM-VSAM-DATA              PIC X(200).

       FD  RECON-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  RECON-REPORT-RECORD            PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT300'.

       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-VSAM-FILE-STATUS            PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYSTL02.
           COPY CPYCOM01.
           COPY CPYERR01.

      * MATCHED RECORD LAYOUT
       01  WS-MATCH-REC.
           05  WS-MR-STATUS              PIC X(10).
           05  WS-MR-SETTLE-ID           PIC X(20).
           05  WS-MR-TXN-ID             PIC X(20).
           05  WS-MR-CARD-NUMBER         PIC X(16).
           05  WS-MR-TXN-AMOUNT         PIC S9(11)V99 COMP-3.
           05  WS-MR-NETWORK-ID         PIC X(04).
           05  WS-MR-AUTH-CODE          PIC X(06).
           05  FILLER                   PIC X(217).

      * NETWORK SUMMARY ACCUMULATORS (VISA, MC, STAR)
       01  WS-NET-SUMMARY-TABLE.
           05  WS-NET-ENTRY OCCURS 3.
               10  WS-NS-NETWORK-ID     PIC X(04).
               10  WS-NS-TXN-COUNT      PIC 9(09) VALUE ZEROS.
               10  WS-NS-TXN-AMOUNT     PIC S9(13)V99 COMP-3
                                         VALUE ZEROS.
               10  WS-NS-FEE-AMOUNT     PIC S9(11)V99 COMP-3
                                         VALUE ZEROS.

       01  WS-NET-IDX                    PIC 9(01).
       01  WS-SETTLE-DATE               PIC X(10).
       01  WS-GRAND-TOTAL-COUNT         PIC 9(09) VALUE ZEROS.
       01  WS-GRAND-TOTAL-AMT           PIC S9(13)V99 COMP-3
                                        VALUE ZEROS.

      * REPORT FORMATTING
       01  WS-RPT-HEADER-1.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               'SETTLEMENT RECONCILIATION REPORT'.
           05  FILLER                    PIC X(30) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-HEADER-2.
           05  FILLER                    PIC X(01) VALUE '-'.
           05  FILLER                    PIC X(10) VALUE 'NETWORK   '.
           05  FILLER                    PIC X(15) VALUE 'TXN COUNT      '.
           05  FILLER                    PIC X(20) VALUE
               'TOTAL AMOUNT        '.
           05  FILLER                    PIC X(20) VALUE
               'NET SETTLEMENT      '.
           05  FILLER                    PIC X(10) VALUE 'STATUS    '.
           05  FILLER                    PIC X(57) VALUE SPACES.

       01  WS-RPT-DETAIL.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-NET-ID            PIC X(10).
           05  WS-RPT-TXN-CT            PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(03) VALUE SPACES.
           05  WS-RPT-TXN-AMT           PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-NET-AMT           PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-RECON-STS         PIC X(10).
           05  FILLER                    PIC X(45) VALUE SPACES.

       01  WS-RPT-TOTAL.
           05  FILLER                    PIC X(01) VALUE '-'.
           05  FILLER                    PIC X(10) VALUE 'TOTAL     '.
           05  WS-RPT-TOT-CT            PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(03) VALUE SPACES.
           05  WS-RPT-TOT-AMT           PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(74) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-MATCHED
               UNTIL WS-EOF
           PERFORM 3000-BUILD-SUMMARIES
           PERFORM 4000-WRITE-REPORT
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
           MOVE WS-FORMATTED-DATE TO WS-SETTLE-DATE

           OPEN INPUT  MATCH-INPUT-FILE
           OPEN OUTPUT SUMMARY-VSAM-FILE
                       RECON-REPORT-FILE

      *    INITIALIZE NETWORK SUMMARY TABLE
           MOVE 'VISA' TO WS-NS-NETWORK-ID(1)
           MOVE 'MC  ' TO WS-NS-NETWORK-ID(2)
           MOVE 'STAR' TO WS-NS-NETWORK-ID(3)

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE RECON-REPORT-RECORD FROM WS-RPT-HEADER-1
           WRITE RECON-REPORT-RECORD FROM WS-RPT-HEADER-2

           PERFORM 2100-READ-MATCHED
           .

      ******************************************************************
      * 2000-PROCESS-MATCHED: ACCUMULATE BY NETWORK                   *
      ******************************************************************
       2000-PROCESS-MATCHED.
           MOVE MATCH-INPUT-RECORD TO WS-MATCH-REC
           ADD 1 TO WS-RECORDS-READ

           EVALUATE WS-MR-NETWORK-ID
               WHEN 'VISA'
                   MOVE 1 TO WS-NET-IDX
               WHEN 'MC  '
                   MOVE 2 TO WS-NET-IDX
               WHEN 'STAR'
                   MOVE 3 TO WS-NET-IDX
               WHEN OTHER
                   MOVE 1 TO WS-NET-IDX
           END-EVALUATE

           ADD 1 TO WS-NS-TXN-COUNT(WS-NET-IDX)
           ADD WS-MR-TXN-AMOUNT TO
               WS-NS-TXN-AMOUNT(WS-NET-IDX)
           ADD 1 TO WS-GRAND-TOTAL-COUNT
           ADD WS-MR-TXN-AMOUNT TO WS-GRAND-TOTAL-AMT

           PERFORM 2100-READ-MATCHED
           .

       2100-READ-MATCHED.
           READ MATCH-INPUT-FILE
               INTO MATCH-INPUT-RECORD
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

      ******************************************************************
      * 3000-BUILD-SUMMARIES: WRITE SUMMARY RECORDS TO VSAM           *
      ******************************************************************
       3000-BUILD-SUMMARIES.
           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3

               IF WS-NS-TXN-COUNT(WS-NET-IDX) > 0
                   INITIALIZE WS-SETTLE-SUMMARY-REC
                   MOVE WS-SETTLE-DATE
                       TO WS-SS-SETTLE-DATE
                   MOVE WS-NS-NETWORK-ID(WS-NET-IDX)
                       TO WS-SS-NETWORK-ID
                   MOVE WS-NS-TXN-COUNT(WS-NET-IDX)
                       TO WS-SS-TOTAL-TXN-COUNT
                   MOVE WS-NS-TXN-AMOUNT(WS-NET-IDX)
                       TO WS-SS-TOTAL-TXN-AMOUNT
                   MOVE WS-NS-TXN-COUNT(WS-NET-IDX)
                       TO WS-SS-MATCHED-COUNT
                   MOVE WS-NS-TXN-AMOUNT(WS-NET-IDX)
                       TO WS-SS-MATCHED-AMOUNT
                   MOVE ZEROS TO WS-SS-UNMATCHED-COUNT
                   MOVE ZEROS TO WS-SS-UNMATCHED-AMOUNT
                   MOVE WS-NS-FEE-AMOUNT(WS-NET-IDX)
                       TO WS-SS-TOTAL-FEES

                   COMPUTE WS-SS-NET-SETTLE-AMOUNT =
                       WS-NS-TXN-AMOUNT(WS-NET-IDX) -
                       WS-NS-FEE-AMOUNT(WS-NET-IDX)

                   MOVE 'BL' TO WS-SS-RECON-STATUS

      *            WRITE TO VSAM
                   MOVE WS-SS-SETTLE-DATE TO SUM-VSAM-DATE
                   MOVE WS-SS-NETWORK-ID  TO SUM-VSAM-NETWORK
                   MOVE WS-SETTLE-SUMMARY-REC
                       TO SUMMARY-VSAM-RECORD

                   WRITE SUMMARY-VSAM-RECORD
                   IF WS-VSAM-FILE-STATUS = '00'
                       ADD 1 TO WS-RECORDS-WRITTEN
                   ELSE
                       DISPLAY 'VSAM WRITE ERROR: '
                           WS-VSAM-FILE-STATUS
                   END-IF
               END-IF
           END-PERFORM
           .

      ******************************************************************
      * 4000-WRITE-REPORT: GENERATE RECONCILIATION REPORT             *
      ******************************************************************
       4000-WRITE-REPORT.
           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3
               IF WS-NS-TXN-COUNT(WS-NET-IDX) > 0
                   INITIALIZE WS-RPT-DETAIL
                   MOVE WS-NS-NETWORK-ID(WS-NET-IDX)
                       TO WS-RPT-NET-ID
                   MOVE WS-NS-TXN-COUNT(WS-NET-IDX)
                       TO WS-RPT-TXN-CT
                   MOVE WS-NS-TXN-AMOUNT(WS-NET-IDX)
                       TO WS-RPT-TXN-AMT
                   COMPUTE WS-RPT-NET-AMT =
                       WS-NS-TXN-AMOUNT(WS-NET-IDX) -
                       WS-NS-FEE-AMOUNT(WS-NET-IDX)
                   MOVE 'BALANCED'  TO WS-RPT-RECON-STS
                   WRITE RECON-REPORT-RECORD
                       FROM WS-RPT-DETAIL
               END-IF
           END-PERFORM

           INITIALIZE WS-RPT-TOTAL
           MOVE WS-GRAND-TOTAL-COUNT TO WS-RPT-TOT-CT
           MOVE WS-GRAND-TOTAL-AMT   TO WS-RPT-TOT-AMT
           WRITE RECON-REPORT-RECORD FROM WS-RPT-TOTAL
           .

       9000-TERMINATE.
           CLOSE MATCH-INPUT-FILE
                 SUMMARY-VSAM-FILE
                 RECON-REPORT-FILE
           DISPLAY 'STLMT300 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
