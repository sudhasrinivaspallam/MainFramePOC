       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT400.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     STLMT400                                          *
      * DESCRIPTION: SETTLEMENT - FINAL REPORT GENERATION              *
      *              READS VSAM SUMMARY, GENERATES MANAGEMENT REPORT,  *
      *              PRODUCES FLAT FILE FOR SAS ANALYTICS INPUT.        *
      * INPUT:       SUMVSAM  - SETTLEMENT SUMMARY VSAM KSDS          *
      * OUTPUT:      MGTRPT   - MANAGEMENT SETTLEMENT REPORT          *
      *              SASOUT   - SAS ANALYTICS FEED FILE                *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SUMMARY-VSAM-FILE
               ASSIGN TO SUMVSAM
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS SUM-VSAM-KEY
               FILE STATUS IS WS-VSAM-FILE-STATUS.

           SELECT MGMT-REPORT-FILE
               ASSIGN TO MGTRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

           SELECT SAS-OUTPUT-FILE
               ASSIGN TO SASOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SAS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  SUMMARY-VSAM-FILE.
       01  SUMMARY-VSAM-RECORD.
           05  SUM-VSAM-KEY.
               10  SUM-VSAM-DATE          PIC X(10).
               10  SUM-VSAM-NETWORK       PIC X(04).
           05  SUM-VSAM-DATA              PIC X(200).

       FD  MGMT-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  MGMT-REPORT-RECORD            PIC X(133).

       FD  SAS-OUTPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 200 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  SAS-OUTPUT-RECORD              PIC X(200).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT400'.

       01  WS-VSAM-FILE-STATUS            PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).
       01  WS-SAS-FILE-STATUS             PIC X(02).

           COPY CPYSTL02.
           COPY CPYCOM01.
           COPY CPYERR01.

       01  WS-GRAND-TXN-COUNT            PIC 9(09) VALUE ZEROS.
       01  WS-GRAND-TXN-AMT              PIC S9(13)V99 COMP-3
                                          VALUE ZEROS.
       01  WS-GRAND-NET-AMT              PIC S9(13)V99 COMP-3
                                          VALUE ZEROS.
       01  WS-GRAND-FEE-AMT              PIC S9(11)V99 COMP-3
                                          VALUE ZEROS.

      * REPORT HEADER
       01  WS-RPT-HEADER-1.
           05  FILLER PIC X(01) VALUE '1'.
           05  FILLER PIC X(10) VALUE SPACES.
           05  FILLER PIC X(60) VALUE
               '================================================'.
           05  FILLER PIC X(62) VALUE SPACES.

       01  WS-RPT-HEADER-2.
           05  FILLER PIC X(01) VALUE ' '.
           05  FILLER PIC X(10) VALUE SPACES.
           05  FILLER PIC X(50) VALUE
               '   DAILY SETTLEMENT MANAGEMENT REPORT'.
           05  FILLER PIC X(72) VALUE SPACES.

       01  WS-RPT-HEADER-3.
           05  FILLER PIC X(01) VALUE ' '.
           05  FILLER PIC X(10) VALUE SPACES.
           05  FILLER PIC X(15) VALUE '   RUN DATE:  '.
           05  WS-RPT-DATE PIC X(10).
           05  FILLER PIC X(97) VALUE SPACES.

       01  WS-RPT-HEADER-4.
           05  FILLER PIC X(01) VALUE ' '.
           05  FILLER PIC X(10) VALUE SPACES.
           05  FILLER PIC X(60) VALUE
               '================================================'.
           05  FILLER PIC X(62) VALUE SPACES.

       01  WS-RPT-COL-HDR.
           05  FILLER PIC X(01) VALUE '-'.
           05  FILLER PIC X(12) VALUE 'SETTLE DATE '.
           05  FILLER PIC X(08) VALUE 'NETWORK '.
           05  FILLER PIC X(12) VALUE 'TXN COUNT   '.
           05  FILLER PIC X(20) VALUE 'TOTAL AMOUNT        '.
           05  FILLER PIC X(18) VALUE 'TOTAL FEES        '.
           05  FILLER PIC X(20) VALUE 'NET SETTLEMENT      '.
           05  FILLER PIC X(10) VALUE 'RECON     '.
           05  FILLER PIC X(32) VALUE SPACES.

       01  WS-RPT-DETAIL.
           05  FILLER PIC X(01) VALUE ' '.
           05  WS-RPT-STL-DATE PIC X(12).
           05  WS-RPT-NET-ID   PIC X(08).
           05  WS-RPT-TXN-CT   PIC ZZZ,ZZZ,ZZ9.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-TXN-AMT  PIC $$$,$$$,$$$,$$9.99.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-FEE-AMT  PIC $$,$$$,$$$,$$9.99.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-NET-AMT  PIC $$$,$$$,$$$,$$9.99.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-RECON    PIC X(10).
           05  FILLER PIC X(22) VALUE SPACES.

       01  WS-RPT-GRAND-TOTAL.
           05  FILLER PIC X(01) VALUE '-'.
           05  FILLER PIC X(12) VALUE 'GRAND TOTAL '.
           05  FILLER PIC X(08) VALUE SPACES.
           05  WS-RPT-GT-CT    PIC ZZZ,ZZZ,ZZ9.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-AMT   PIC $$$,$$$,$$$,$$9.99.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-FEE   PIC $$,$$$,$$$,$$9.99.
           05  FILLER PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-NET   PIC $$$,$$$,$$$,$$9.99.
           05  FILLER PIC X(34) VALUE SPACES.

      * SAS OUTPUT LAYOUT (CSV-LIKE FOR SAS INFILE)
       01  WS-SAS-REC.
           05  WS-SAS-DATE      PIC X(10).
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-NETWORK   PIC X(04).
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-TXN-CNT   PIC 9(09).
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-TXN-AMT   PIC S9(13)V99.
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-FEE-AMT   PIC S9(11)V99.
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-NET-AMT   PIC S9(13)V99.
           05  FILLER            PIC X(01) VALUE ','.
           05  WS-SAS-STATUS    PIC X(02).
           05  FILLER            PIC X(125) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-SUMMARY
               UNTIL WS-EOF
           PERFORM 3000-WRITE-GRAND-TOTAL
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

           OPEN INPUT  SUMMARY-VSAM-FILE
           OPEN OUTPUT MGMT-REPORT-FILE
                       SAS-OUTPUT-FILE

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER-1
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER-2
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER-3
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER-4
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-COL-HDR

           PERFORM 2100-READ-VSAM
           .

       2000-PROCESS-SUMMARY.
           MOVE SUMMARY-VSAM-RECORD TO WS-SETTLE-SUMMARY-REC
           ADD 1 TO WS-RECORDS-READ

      *    WRITE REPORT DETAIL
           INITIALIZE WS-RPT-DETAIL
           MOVE WS-SS-SETTLE-DATE   TO WS-RPT-STL-DATE
           MOVE WS-SS-NETWORK-ID    TO WS-RPT-NET-ID
           MOVE WS-SS-TOTAL-TXN-COUNT TO WS-RPT-TXN-CT
           MOVE WS-SS-TOTAL-TXN-AMOUNT TO WS-RPT-TXN-AMT
           MOVE WS-SS-TOTAL-FEES    TO WS-RPT-FEE-AMT
           MOVE WS-SS-NET-SETTLE-AMOUNT TO WS-RPT-NET-AMT
           EVALUATE WS-SS-RECON-STATUS
               WHEN 'BL'  MOVE 'BALANCED'  TO WS-RPT-RECON
               WHEN 'OB'  MOVE 'OUT-OF-BAL' TO WS-RPT-RECON
               WHEN 'PE'  MOVE 'PENDING'   TO WS-RPT-RECON
           END-EVALUATE
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-DETAIL

      *    WRITE SAS FEED
           INITIALIZE WS-SAS-REC
           MOVE WS-SS-SETTLE-DATE       TO WS-SAS-DATE
           MOVE WS-SS-NETWORK-ID        TO WS-SAS-NETWORK
           MOVE WS-SS-TOTAL-TXN-COUNT   TO WS-SAS-TXN-CNT
           MOVE WS-SS-TOTAL-TXN-AMOUNT  TO WS-SAS-TXN-AMT
           MOVE WS-SS-TOTAL-FEES        TO WS-SAS-FEE-AMT
           MOVE WS-SS-NET-SETTLE-AMOUNT TO WS-SAS-NET-AMT
           MOVE WS-SS-RECON-STATUS      TO WS-SAS-STATUS
           WRITE SAS-OUTPUT-RECORD FROM WS-SAS-REC

      *    ACCUMULATE GRAND TOTALS
           ADD WS-SS-TOTAL-TXN-COUNT TO WS-GRAND-TXN-COUNT
           ADD WS-SS-TOTAL-TXN-AMOUNT TO WS-GRAND-TXN-AMT
           ADD WS-SS-TOTAL-FEES TO WS-GRAND-FEE-AMT
           ADD WS-SS-NET-SETTLE-AMOUNT TO WS-GRAND-NET-AMT

           PERFORM 2100-READ-VSAM
           .

       2100-READ-VSAM.
           READ SUMMARY-VSAM-FILE
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

       3000-WRITE-GRAND-TOTAL.
           INITIALIZE WS-RPT-GRAND-TOTAL
           MOVE WS-GRAND-TXN-COUNT TO WS-RPT-GT-CT
           MOVE WS-GRAND-TXN-AMT   TO WS-RPT-GT-AMT
           MOVE WS-GRAND-FEE-AMT   TO WS-RPT-GT-FEE
           MOVE WS-GRAND-NET-AMT   TO WS-RPT-GT-NET
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-GRAND-TOTAL
           .

       9000-TERMINATE.
           CLOSE SUMMARY-VSAM-FILE
                 MGMT-REPORT-FILE
                 SAS-OUTPUT-FILE
           DISPLAY 'STLMT400 PROCESSING COMPLETE'
           DISPLAY 'SUMMARY RECORDS: ' WS-RECORDS-READ
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
