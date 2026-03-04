       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT400.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     STLMT400 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: SETTLEMENT - MANAGEMENT REPORT AND SAS CSV FEED  *
      *              READS SUMMARY VSAM FILE, GENERATES FORMATTED     *
      *              MANAGEMENT REPORT AND SAS-READY CSV OUTPUT.       *
      * INPUT:       SUMVSAM  - SETTLEMENT SUMMARY INDEXED FILE       *
      * OUTPUT:      MGTRPT   - FORMATTED MANAGEMENT REPORT           *
      *              SASOUT   - SAS CSV FEED FILE                      *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SUMMARY-VSAM-FILE
               ASSIGN TO "DATA/SUMVSAM.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS SUM-VSAM-KEY
               FILE STATUS IS WS-SUM-FILE-STATUS.

           SELECT MGMT-REPORT-FILE
               ASSIGN TO "OUTPUT/MGTRPT.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

           SELECT SAS-OUTPUT-FILE
               ASSIGN TO "OUTPUT/SASOUT.csv"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SAS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  SUMMARY-VSAM-FILE
           RECORD CONTAINS 214 CHARACTERS.
       01  SUMMARY-VSAM-RECORD.
           05  SUM-VSAM-KEY.
               10  SUM-VSAM-DATE         PIC X(10).
               10  SUM-VSAM-NETWORK      PIC X(04).
           05  SUM-VSAM-DATA             PIC X(200).

       FD  MGMT-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  MGMT-REPORT-RECORD            PIC X(133).

       FD  SAS-OUTPUT-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  SAS-OUTPUT-RECORD              PIC X(250).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT400'.

       01  WS-SUM-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).
       01  WS-SAS-FILE-STATUS             PIC X(02).

           COPY CPYSTL02.
           COPY CPYCOM01.
           COPY CPYERR01.

       01  WS-SUM-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  WS-SUM-EOF                 VALUE 'Y'.

       01  WS-SUM-READ-COUNT              PIC 9(09) VALUE ZEROS.
       01  WS-SAS-WRITE-COUNT             PIC 9(09) VALUE ZEROS.

      * GRAND TOTALS FOR REPORT
       01  WS-GT-TXN-COUNT                PIC 9(09) VALUE ZEROS.
       01  WS-GT-TXN-AMOUNT               PIC 9(15)V99 VALUE ZEROS.
       01  WS-GT-MATCH-COUNT              PIC 9(09) VALUE ZEROS.
       01  WS-GT-MATCH-AMOUNT             PIC 9(15)V99 VALUE ZEROS.
       01  WS-GT-UNMATCH-COUNT            PIC 9(09) VALUE ZEROS.
       01  WS-GT-FEES                     PIC 9(13)V99 VALUE ZEROS.
       01  WS-GT-NET-AMOUNT               PIC 9(15)V99 VALUE ZEROS.

      * REPORT LINES
       01  WS-RPT-TITLE.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(10) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               '========================================='.
           05  FILLER                    PIC X(72) VALUE SPACES.

       01  WS-RPT-HEADER1.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  FILLER                    PIC X(10) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               'DAILY SETTLEMENT MANAGEMENT REPORT'.
           05  FILLER                    PIC X(25) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-HEADER2.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  FILLER                    PIC X(10) VALUE SPACES.
           05  FILLER                    PIC X(50) VALUE
               '========================================='.
           05  FILLER                    PIC X(72) VALUE SPACES.

       01  WS-RPT-COL-HDR.
           05  FILLER        PIC X(01) VALUE ' '.
           05  FILLER        PIC X(06) VALUE 'DATE  '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(06) VALUE 'NETWRK'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(10) VALUE 'TXN COUNT '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE 'TXN AMOUNT      '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(10) VALUE 'MATCH CNT '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE 'MATCH AMOUNT    '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(13) VALUE 'FEES         '.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE 'NET SETTLEMENT  '.
           05  FILLER        PIC X(25) VALUE SPACES.

       01  WS-RPT-COL-SEP.
           05  FILLER        PIC X(01) VALUE ' '.
           05  FILLER        PIC X(06) VALUE '------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(06) VALUE '------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(10) VALUE '----------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE '----------------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(10) VALUE '----------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE '----------------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(13) VALUE '-------------'.
           05  FILLER        PIC X(02) VALUE SPACES.
           05  FILLER        PIC X(16)
               VALUE '----------------'.
           05  FILLER        PIC X(25) VALUE SPACES.

       01  WS-RPT-DETAIL.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-DTL-DATE          PIC X(06).
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-NETWORK       PIC X(06).
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-TXN-CNT       PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-TXN-AMT       PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-MAT-CNT       PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-MAT-AMT       PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-FEES          PIC $$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-DTL-NET-AMT       PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(04) VALUE SPACES.

       01  WS-RPT-GT-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  FILLER                    PIC X(16) VALUE
               'GRAND TOTALS:   '.
           05  WS-RPT-GT-TXN-CNT        PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-TXN-AMT        PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-MAT-CNT        PIC ZZZ,ZZZ,ZZ9.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-MAT-AMT        PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-FEES           PIC $$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(02) VALUE SPACES.
           05  WS-RPT-GT-NET-AMT        PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                    PIC X(04) VALUE SPACES.

       01  WS-SAS-HEADER                  PIC X(250).
       01  WS-SAS-LINE                    PIC X(250).

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-SUMMARIES
           PERFORM 3000-WRITE-GRAND-TOTALS
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

           IF WS-SUM-FILE-STATUS NOT = '00'
               DISPLAY 'SUMMARY FILE OPEN ERROR: '
                   WS-SUM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-TITLE
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER1
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-HEADER2
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-COL-HDR
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-COL-SEP

      * SAS CSV HEADER
           STRING
               'SETTLE_DATE' DELIMITED SIZE ','
               'NETWORK_ID'  DELIMITED SIZE ','
               'TXN_COUNT'   DELIMITED SIZE ','
               'TXN_AMOUNT'  DELIMITED SIZE ','
               'MATCH_COUNT' DELIMITED SIZE ','
               'MATCH_AMOUNT' DELIMITED SIZE ','
               'UNMATCH_COUNT' DELIMITED SIZE ','
               'UNMATCH_AMOUNT' DELIMITED SIZE ','
               'DISPUTE_COUNT' DELIMITED SIZE ','
               'DISPUTE_AMOUNT' DELIMITED SIZE ','
               'TOTAL_FEES'  DELIMITED SIZE ','
               'NET_SETTLE'  DELIMITED SIZE ','
               'RECON_STATUS' DELIMITED SIZE
               INTO WS-SAS-HEADER
           END-STRING
           WRITE SAS-OUTPUT-RECORD FROM WS-SAS-HEADER
           .

      ******************************************************************
      * 2000-PROCESS-SUMMARIES: READ ALL SUMMARY RECORDS              *
      ******************************************************************
       2000-PROCESS-SUMMARIES.
           PERFORM UNTIL WS-SUM-EOF
               READ SUMMARY-VSAM-FILE
                   INTO SUMMARY-VSAM-RECORD
                   AT END
                       SET WS-SUM-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-SUM-READ-COUNT
                       MOVE SUMMARY-VSAM-RECORD
                           TO WS-SETTLE-SUMMARY-REC
                       PERFORM 2100-WRITE-REPORT-LINE
                       PERFORM 2200-WRITE-SAS-LINE
                       PERFORM 2300-ACCUMULATE-TOTALS
               END-READ
           END-PERFORM
           .

       2100-WRITE-REPORT-LINE.
           INITIALIZE WS-RPT-DETAIL
           MOVE WS-SS-SETTLE-DATE(1:6) TO WS-RPT-DTL-DATE
           MOVE WS-SS-NETWORK-ID       TO WS-RPT-DTL-NETWORK
           MOVE WS-SS-TOTAL-TXN-COUNT  TO WS-RPT-DTL-TXN-CNT
           MOVE WS-SS-TOTAL-TXN-AMOUNT TO WS-RPT-DTL-TXN-AMT
           MOVE WS-SS-MATCHED-COUNT    TO WS-RPT-DTL-MAT-CNT
           MOVE WS-SS-MATCHED-AMOUNT   TO WS-RPT-DTL-MAT-AMT
           MOVE WS-SS-TOTAL-FEES       TO WS-RPT-DTL-FEES
           MOVE WS-SS-NET-SETTLE-AMOUNT TO WS-RPT-DTL-NET-AMT
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-DETAIL
           .

       2200-WRITE-SAS-LINE.
           INITIALIZE WS-SAS-LINE
           STRING
               WS-SS-SETTLE-DATE DELIMITED SIZE ','
               WS-SS-NETWORK-ID  DELIMITED SIZE ','
               WS-SS-TOTAL-TXN-COUNT  DELIMITED SIZE ','
               WS-SS-TOTAL-TXN-AMOUNT DELIMITED SIZE ','
               WS-SS-MATCHED-COUNT    DELIMITED SIZE ','
               WS-SS-MATCHED-AMOUNT   DELIMITED SIZE ','
               WS-SS-UNMATCHED-COUNT  DELIMITED SIZE ','
               WS-SS-UNMATCHED-AMOUNT DELIMITED SIZE ','
               WS-SS-DISPUTED-COUNT   DELIMITED SIZE ','
               WS-SS-DISPUTED-AMOUNT  DELIMITED SIZE ','
               WS-SS-TOTAL-FEES       DELIMITED SIZE ','
               WS-SS-NET-SETTLE-AMOUNT DELIMITED SIZE ','
               WS-SS-RECON-STATUS     DELIMITED SIZE
               INTO WS-SAS-LINE
           END-STRING
           WRITE SAS-OUTPUT-RECORD FROM WS-SAS-LINE
           ADD 1 TO WS-SAS-WRITE-COUNT
           .

       2300-ACCUMULATE-TOTALS.
           ADD WS-SS-TOTAL-TXN-COUNT
               TO WS-GT-TXN-COUNT
           ADD WS-SS-TOTAL-TXN-AMOUNT
               TO WS-GT-TXN-AMOUNT
           ADD WS-SS-MATCHED-COUNT
               TO WS-GT-MATCH-COUNT
           ADD WS-SS-MATCHED-AMOUNT
               TO WS-GT-MATCH-AMOUNT
           ADD WS-SS-UNMATCHED-COUNT
               TO WS-GT-UNMATCH-COUNT
           ADD WS-SS-TOTAL-FEES
               TO WS-GT-FEES
           ADD WS-SS-NET-SETTLE-AMOUNT
               TO WS-GT-NET-AMOUNT
           .

      ******************************************************************
      * 3000-WRITE-GRAND-TOTALS: PRINT GRAND TOTALS ON REPORT         *
      ******************************************************************
       3000-WRITE-GRAND-TOTALS.
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-COL-SEP

           INITIALIZE WS-RPT-GT-LINE
           MOVE WS-GT-TXN-COUNT    TO WS-RPT-GT-TXN-CNT
           MOVE WS-GT-TXN-AMOUNT   TO WS-RPT-GT-TXN-AMT
           MOVE WS-GT-MATCH-COUNT  TO WS-RPT-GT-MAT-CNT
           MOVE WS-GT-MATCH-AMOUNT TO WS-RPT-GT-MAT-AMT
           MOVE WS-GT-FEES         TO WS-RPT-GT-FEES
           MOVE WS-GT-NET-AMOUNT   TO WS-RPT-GT-NET-AMT
           WRITE MGMT-REPORT-RECORD FROM WS-RPT-GT-LINE

           MOVE SPACES TO MGMT-REPORT-RECORD
           WRITE MGMT-REPORT-RECORD

           DISPLAY 'SUMMARY RECORDS READ:   ' WS-SUM-READ-COUNT
           DISPLAY 'SAS CSV RECORDS WRITTEN: ' WS-SAS-WRITE-COUNT
           .

       9000-TERMINATE.
           CLOSE SUMMARY-VSAM-FILE
                 MGMT-REPORT-FILE
                 SAS-OUTPUT-FILE

           DISPLAY 'STLMT400 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
