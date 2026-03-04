       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT300.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     STLMT300 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: SETTLEMENT - NET SETTLEMENT CALCULATION           *
      *              READS MATCHED OUTPUT FROM STLMT200, AGGREGATES   *
      *              BY NETWORK, CALCULATES NET SETTLEMENT AMOUNTS,   *
      *              WRITES SUMMARY RECORDS TO INDEXED VSAM FILE.     *
      * INPUT:       STLOUT  - MATCHED TRANSACTIONS FROM STLMT200     *
      *              STLERR  - EXCEPTION RECORDS FROM STLMT200        *
      * OUTPUT:      SUMVSAM - SETTLEMENT SUMMARY INDEXED FILE        *
      *              STLRPT3 - RECONCILIATION REPORT                  *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MATCH-INPUT-FILE
               ASSIGN TO "OUTPUT/STLOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT ERROR-INPUT-FILE
               ASSIGN TO "OUTPUT/STLERR2.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERROUT-STATUS.

           SELECT SUMMARY-VSAM-FILE
               ASSIGN TO "DATA/SUMVSAM.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS SUM-VSAM-KEY
               FILE STATUS IS WS-SUM-FILE-STATUS.

           SELECT RECON-REPORT-FILE
               ASSIGN TO "OUTPUT/STLRPT3.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  MATCH-INPUT-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  MATCH-INPUT-RECORD             PIC X(300).

       FD  ERROR-INPUT-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  ERROR-INPUT-RECORD             PIC X(300).

       FD  SUMMARY-VSAM-FILE
           RECORD CONTAINS 214 CHARACTERS.
       01  SUMMARY-VSAM-RECORD.
           05  SUM-VSAM-KEY.
               10  SUM-VSAM-DATE         PIC X(10).
               10  SUM-VSAM-NETWORK      PIC X(04).
           05  SUM-VSAM-DATA             PIC X(200).

       FD  RECON-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  RECON-REPORT-RECORD            PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT300'.

       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-ERROUT-STATUS               PIC X(02).
       01  WS-SUM-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYSTL01.
           COPY CPYSTL02.
           COPY CPYCOM01.
           COPY CPYERR01.

      * PARSED MATCH RECORD FIELDS
       01  WS-MATCH-TYPE                  PIC X(10).
       01  WS-MATCH-SETTLE-ID            PIC X(20).
       01  WS-MATCH-TXN-ID              PIC X(20).
       01  WS-MATCH-CARD-NUM            PIC X(16).
       01  WS-MATCH-AMOUNT              PIC 9(11)V99.
       01  WS-MATCH-NETWORK             PIC X(04).
       01  WS-MATCH-AUTH-CODE           PIC X(06).

      * PARSED ERROR RECORD FIELDS
       01  WS-ERR-TYPE                   PIC X(10).
       01  WS-ERR-ID                     PIC X(20).
       01  WS-ERR-TXN-ID                PIC X(20).
       01  WS-ERR-CARD-NUM              PIC X(16).
       01  WS-ERR-AMOUNT                PIC 9(11)V99.

      * NETWORK ACCUMULATORS (3 NETWORKS: VISA, MC, STAR)
       01  WS-NET-TABLE.
           05  WS-NET-ENTRY OCCURS 3 TIMES.
               10  WS-NET-ID            PIC X(04).
               10  WS-NET-TXN-COUNT     PIC 9(09).
               10  WS-NET-TXN-AMOUNT    PIC 9(13)V99.
               10  WS-NET-MATCH-COUNT   PIC 9(09).
               10  WS-NET-MATCH-AMOUNT  PIC 9(13)V99.
               10  WS-NET-UNMATCH-COUNT PIC 9(09).
               10  WS-NET-UNMATCH-AMT   PIC 9(13)V99.
               10  WS-NET-DISPUTE-COUNT PIC 9(09).
               10  WS-NET-DISPUTE-AMT   PIC 9(13)V99.
               10  WS-NET-FEES          PIC 9(11)V99.

       01  WS-NET-IDX                    PIC 9(01).

       01  WS-INP-EOF-FLAG               PIC X(01) VALUE 'N'.
           88  WS-INP-EOF                VALUE 'Y'.
       01  WS-ERR-EOF-FLAG               PIC X(01) VALUE 'N'.
           88  WS-ERR-EOF                VALUE 'Y'.

       01  WS-INP-READ-COUNT             PIC 9(09) VALUE ZEROS.
       01  WS-ERR-READ-COUNT             PIC 9(09) VALUE ZEROS.
       01  WS-SUM-WRITE-COUNT            PIC 9(09) VALUE ZEROS.
       01  WS-GRAND-TXN-COUNT            PIC 9(09) VALUE ZEROS.
       01  WS-GRAND-TXN-AMOUNT           PIC 9(13)V99 VALUE ZEROS.

       01  WS-INTERCHANGE-RATE           PIC 9V9999 VALUE 0.0175.
       01  WS-CALC-FEE                   PIC 9(11)V99.
       01  WS-NET-SETTLE-CALC            PIC 9(13)V99.

       01  WS-RPT-HEADER.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(55) VALUE
               'SETTLEMENT SYSTEM - NET SETTLEMENT / RECONCILIATION'.
           05  FILLER                    PIC X(25) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-NET-HDR.
           05  FILLER        PIC X(01) VALUE ' '.
           05  FILLER        PIC X(10) VALUE 'NETWORK   '.
           05  FILLER        PIC X(12) VALUE 'TOTAL COUNT '.
           05  FILLER        PIC X(17)
               VALUE '  TOTAL AMOUNT   '.
           05  FILLER        PIC X(12) VALUE 'MATCH COUNT '.
           05  FILLER        PIC X(17)
               VALUE '  MATCH AMOUNT   '.
           05  FILLER        PIC X(12) VALUE 'FEES        '.
           05  FILLER        PIC X(17)
               VALUE '  NET SETTLE     '.
           05  FILLER        PIC X(35) VALUE SPACES.

       01  WS-RPT-NET-DTL.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-NET-ID            PIC X(10).
           05  WS-RPT-TOT-CNT           PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-TOT-AMT           PIC $$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-MAT-CNT           PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-MAT-AMT           PIC $$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-FEES              PIC $$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-NET-AMT           PIC $$$,$$$,$$9.99.
           05  FILLER                    PIC X(10) VALUE SPACES.

       01  WS-RPT-SUM-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-SUM-LABEL         PIC X(40).
           05  WS-RPT-SUM-VALUE         PIC X(20).
           05  FILLER                    PIC X(72) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-MATCHED
           PERFORM 2500-PROCESS-ERRORS
           PERFORM 3000-CALCULATE-NET-SETTLE
           PERFORM 4000-WRITE-SUMMARY-VSAM
           PERFORM 5000-WRITE-REPORT
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

      * INITIALIZE NETWORK TABLE
           MOVE 'VISA' TO WS-NET-ID(1)
           MOVE 'MC  ' TO WS-NET-ID(2)
           MOVE 'STAR' TO WS-NET-ID(3)
           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3
               MOVE ZEROS TO WS-NET-TXN-COUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-TXN-AMOUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-MATCH-COUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-MATCH-AMOUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-UNMATCH-COUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-UNMATCH-AMT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-DISPUTE-COUNT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-DISPUTE-AMT(WS-NET-IDX)
               MOVE ZEROS TO WS-NET-FEES(WS-NET-IDX)
           END-PERFORM

           OPEN INPUT  MATCH-INPUT-FILE
                       ERROR-INPUT-FILE
           OPEN OUTPUT SUMMARY-VSAM-FILE
                       RECON-REPORT-FILE

           IF WS-INP-FILE-STATUS NOT = '00'
               DISPLAY 'MATCH INPUT FILE OPEN ERROR: '
                   WS-INP-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF

           IF WS-SUM-FILE-STATUS NOT = '00'
               DISPLAY 'SUMMARY VSAM FILE OPEN ERROR: '
                   WS-SUM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF
           .

      ******************************************************************
      * 2000-PROCESS-MATCHED: READ MATCHED TRANSACTIONS AND AGGREGATE *
      ******************************************************************
       2000-PROCESS-MATCHED.
           PERFORM UNTIL WS-INP-EOF
               READ MATCH-INPUT-FILE INTO MATCH-INPUT-RECORD
                   AT END
                       SET WS-INP-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-INP-READ-COUNT
                       PERFORM 2100-PARSE-MATCH-RECORD
                       PERFORM 2200-ACCUMULATE-MATCH
               END-READ
           END-PERFORM
           .

       2100-PARSE-MATCH-RECORD.
           MOVE MATCH-INPUT-RECORD(1:10) TO WS-MATCH-TYPE
           MOVE MATCH-INPUT-RECORD(11:20) TO WS-MATCH-SETTLE-ID
           MOVE MATCH-INPUT-RECORD(31:20) TO WS-MATCH-TXN-ID
           MOVE MATCH-INPUT-RECORD(51:16) TO WS-MATCH-CARD-NUM
           MOVE MATCH-INPUT-RECORD(67:13) TO WS-MATCH-AMOUNT
           MOVE MATCH-INPUT-RECORD(80:04) TO WS-MATCH-NETWORK
           MOVE MATCH-INPUT-RECORD(84:06) TO WS-MATCH-AUTH-CODE
           .

       2200-ACCUMULATE-MATCH.
           PERFORM 2210-FIND-NETWORK
           IF WS-NET-IDX > 0 AND WS-NET-IDX < 4
               ADD 1 TO WS-NET-TXN-COUNT(WS-NET-IDX)
               ADD WS-MATCH-AMOUNT
                   TO WS-NET-TXN-AMOUNT(WS-NET-IDX)
               ADD 1 TO WS-NET-MATCH-COUNT(WS-NET-IDX)
               ADD WS-MATCH-AMOUNT
                   TO WS-NET-MATCH-AMOUNT(WS-NET-IDX)
           END-IF
           .

       2210-FIND-NETWORK.
           MOVE 0 TO WS-NET-IDX
           IF WS-MATCH-NETWORK = 'VISA'
               MOVE 1 TO WS-NET-IDX
           ELSE IF WS-MATCH-NETWORK = 'MC  '
               MOVE 2 TO WS-NET-IDX
           ELSE IF WS-MATCH-NETWORK = 'STAR'
               MOVE 3 TO WS-NET-IDX
           END-IF
           .

      ******************************************************************
      * 2500-PROCESS-ERRORS: READ EXCEPTION RECORDS (UNMATCHED/DISP)  *
      ******************************************************************
       2500-PROCESS-ERRORS.
           PERFORM UNTIL WS-ERR-EOF
               READ ERROR-INPUT-FILE INTO ERROR-INPUT-RECORD
                   AT END
                       SET WS-ERR-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-ERR-READ-COUNT
                       PERFORM 2510-PARSE-ERROR-RECORD
                       PERFORM 2520-ACCUMULATE-ERROR
               END-READ
           END-PERFORM
           .

       2510-PARSE-ERROR-RECORD.
           MOVE ERROR-INPUT-RECORD(1:10) TO WS-ERR-TYPE
           MOVE ERROR-INPUT-RECORD(11:20) TO WS-ERR-ID
           .

       2520-ACCUMULATE-ERROR.
      * ERRORS DON'T HAVE NETWORK - COUNT AS GENERAL UNMATCHED
           EVALUATE TRUE
               WHEN WS-ERR-TYPE = 'UNMT-STL '
                   ADD 1 TO WS-GRAND-TXN-COUNT
               WHEN WS-ERR-TYPE = 'UNMT-ACQ '
                   ADD 1 TO WS-GRAND-TXN-COUNT
               WHEN WS-ERR-TYPE = 'AMT-DIFF '
                   ADD 1 TO WS-GRAND-TXN-COUNT
           END-EVALUATE
           .

      ******************************************************************
      * 3000-CALCULATE-NET-SETTLE: COMPUTE FEES AND NET AMOUNTS       *
      ******************************************************************
       3000-CALCULATE-NET-SETTLE.
           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3
               COMPUTE WS-NET-FEES(WS-NET-IDX) =
                   WS-NET-MATCH-AMOUNT(WS-NET-IDX)
                       * WS-INTERCHANGE-RATE
               ADD WS-NET-TXN-COUNT(WS-NET-IDX)
                   TO WS-GRAND-TXN-COUNT
               ADD WS-NET-TXN-AMOUNT(WS-NET-IDX)
                   TO WS-GRAND-TXN-AMOUNT
           END-PERFORM
           .

      ******************************************************************
      * 4000-WRITE-SUMMARY-VSAM: WRITE ONE SUMMARY PER NETWORK        *
      ******************************************************************
       4000-WRITE-SUMMARY-VSAM.
           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3

               INITIALIZE WS-SETTLE-SUMMARY-REC
               MOVE WS-FORMATTED-DATE
                   TO WS-SS-SETTLE-DATE
               MOVE WS-NET-ID(WS-NET-IDX)
                   TO WS-SS-NETWORK-ID
               MOVE WS-NET-TXN-COUNT(WS-NET-IDX)
                   TO WS-SS-TOTAL-TXN-COUNT
               MOVE WS-NET-TXN-AMOUNT(WS-NET-IDX)
                   TO WS-SS-TOTAL-TXN-AMOUNT
               MOVE WS-NET-MATCH-COUNT(WS-NET-IDX)
                   TO WS-SS-MATCHED-COUNT
               MOVE WS-NET-MATCH-AMOUNT(WS-NET-IDX)
                   TO WS-SS-MATCHED-AMOUNT
               MOVE WS-NET-UNMATCH-COUNT(WS-NET-IDX)
                   TO WS-SS-UNMATCHED-COUNT
               MOVE WS-NET-UNMATCH-AMT(WS-NET-IDX)
                   TO WS-SS-UNMATCHED-AMOUNT
               MOVE WS-NET-DISPUTE-COUNT(WS-NET-IDX)
                   TO WS-SS-DISPUTED-COUNT
               MOVE WS-NET-DISPUTE-AMT(WS-NET-IDX)
                   TO WS-SS-DISPUTED-AMOUNT
               MOVE WS-NET-FEES(WS-NET-IDX)
                   TO WS-SS-TOTAL-FEES
               COMPUTE WS-SS-NET-SETTLE-AMOUNT =
                   WS-NET-MATCH-AMOUNT(WS-NET-IDX)
                       - WS-NET-FEES(WS-NET-IDX)
               MOVE 'BL' TO WS-SS-RECON-STATUS
               MOVE FUNCTION CURRENT-DATE
                   TO WS-SS-CREATED-TIMESTAMP

               INITIALIZE SUMMARY-VSAM-RECORD
               MOVE WS-SS-SETTLE-DATE
                   TO SUM-VSAM-DATE
               MOVE WS-SS-NETWORK-ID
                   TO SUM-VSAM-NETWORK
               MOVE WS-SETTLE-SUMMARY-REC
                   TO SUMMARY-VSAM-RECORD

               WRITE SUMMARY-VSAM-RECORD
               IF WS-SUM-FILE-STATUS = '00'
                   ADD 1 TO WS-SUM-WRITE-COUNT
               ELSE
                   DISPLAY 'SUMMARY WRITE ERROR: '
                       WS-SUM-FILE-STATUS
                       ' FOR NETWORK: '
                       WS-NET-ID(WS-NET-IDX)
               END-IF
           END-PERFORM
           .

      ******************************************************************
      * 5000-WRITE-REPORT: RECONCILIATION REPORT                       *
      ******************************************************************
       5000-WRITE-REPORT.
           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE RECON-REPORT-RECORD FROM WS-RPT-HEADER
           WRITE RECON-REPORT-RECORD FROM WS-RPT-NET-HDR

           PERFORM VARYING WS-NET-IDX FROM 1 BY 1
               UNTIL WS-NET-IDX > 3
               INITIALIZE WS-RPT-NET-DTL
               MOVE WS-NET-ID(WS-NET-IDX) TO WS-RPT-NET-ID
               MOVE WS-NET-TXN-COUNT(WS-NET-IDX)
                   TO WS-RPT-TOT-CNT
               MOVE WS-NET-TXN-AMOUNT(WS-NET-IDX)
                   TO WS-RPT-TOT-AMT
               MOVE WS-NET-MATCH-COUNT(WS-NET-IDX)
                   TO WS-RPT-MAT-CNT
               MOVE WS-NET-MATCH-AMOUNT(WS-NET-IDX)
                   TO WS-RPT-MAT-AMT
               MOVE WS-NET-FEES(WS-NET-IDX)
                   TO WS-RPT-FEES
               COMPUTE WS-NET-SETTLE-CALC =
                   WS-NET-MATCH-AMOUNT(WS-NET-IDX)
                       - WS-NET-FEES(WS-NET-IDX)
               MOVE WS-NET-SETTLE-CALC TO WS-RPT-NET-AMT
               WRITE RECON-REPORT-RECORD FROM WS-RPT-NET-DTL
           END-PERFORM

           MOVE SPACES TO RECON-REPORT-RECORD
           WRITE RECON-REPORT-RECORD

           MOVE 'TOTAL MATCHED INPUT RECORDS:' TO WS-RPT-SUM-LABEL
           MOVE WS-INP-READ-COUNT              TO WS-RPT-SUM-VALUE
           WRITE RECON-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL ERROR RECORDS:        ' TO WS-RPT-SUM-LABEL
           MOVE WS-ERR-READ-COUNT              TO WS-RPT-SUM-VALUE
           WRITE RECON-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'SUMMARY RECORDS WRITTEN:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-SUM-WRITE-COUNT             TO WS-RPT-SUM-VALUE
           WRITE RECON-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

       9000-TERMINATE.
           CLOSE MATCH-INPUT-FILE
                 ERROR-INPUT-FILE
                 SUMMARY-VSAM-FILE
                 RECON-REPORT-FILE

           DISPLAY 'STLMT300 PROCESSING COMPLETE'
           DISPLAY 'SUMMARY RECORDS WRITTEN: ' WS-SUM-WRITE-COUNT
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
