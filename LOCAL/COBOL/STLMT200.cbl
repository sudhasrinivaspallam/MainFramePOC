       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT200.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     STLMT200 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: SETTLEMENT - TRANSACTION MATCHING PROGRAM         *
      *              TWO-FILE SEQUENTIAL MERGE MATCHING ALGORITHM.     *
      *              READS SORTED SETTLEMENT AND ACQUIRER FILES,       *
      *              PERFORMS MATCHING LOGIC, DETECTS MISMATCHES.      *
      * INPUT:       STLSORT  - SETTLEMENT RECORDS (SORTED BY TXN-ID)*
      *              ACQFILE  - ACQUIRER CONFIRMATIONS (SORTED)        *
      * OUTPUT:      STLOUT   - MATCHED/UNMATCHED OUTPUT FILE          *
      *              STLERR   - MATCHING EXCEPTIONS FILE               *
      *              STLRPT   - MATCHING SUMMARY REPORT                *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SETTLE-SORTED-FILE
               ASSIGN TO "DATA/STLSORT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-VSAM-FILE-STATUS.

           SELECT ACQUIRER-FILE
               ASSIGN TO "DATA/ACQFILE.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ACQ-FILE-STATUS.

           SELECT MATCH-OUTPUT-FILE
               ASSIGN TO "OUTPUT/STLOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT MATCH-ERROR-FILE
               ASSIGN TO "OUTPUT/STLERR2.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERROUT-STATUS.

           SELECT MATCH-REPORT-FILE
               ASSIGN TO "OUTPUT/STLRPT2.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  SETTLE-SORTED-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  SETTLE-SORTED-RECORD           PIC X(250).

       FD  ACQUIRER-FILE
           RECORD CONTAINS 150 CHARACTERS.
       01  ACQUIRER-RECORD                PIC X(150).

       FD  MATCH-OUTPUT-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  MATCH-OUTPUT-RECORD            PIC X(300).

       FD  MATCH-ERROR-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  MATCH-ERROR-RECORD             PIC X(300).

       FD  MATCH-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  MATCH-REPORT-RECORD            PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT200'.

       01  WS-VSAM-FILE-STATUS            PIC X(02).
       01  WS-ACQ-FILE-STATUS             PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-ERROUT-STATUS               PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYSTL01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * ACQUIRER CONFIRMATION RECORD
       01  WS-ACQ-REC.
           05  WS-ACQ-TXN-ID             PIC X(20).
           05  WS-ACQ-CARD-NUMBER        PIC X(16).
           05  WS-ACQ-TXN-AMOUNT         PIC 9(11)V99.
           05  WS-ACQ-TXN-DATE           PIC X(10).
           05  WS-ACQ-ACQUIRER-ID        PIC X(11).
           05  WS-ACQ-AUTH-CODE          PIC X(06).
           05  WS-ACQ-SETTLE-AMOUNT      PIC 9(11)V99.
           05  WS-ACQ-NETWORK-ID         PIC X(04).
           05  FILLER                    PIC X(57).

      * MATCHING WORK AREAS
       01  WS-STL-EOF-FLAG               PIC X(01) VALUE 'N'.
           88  WS-STL-EOF                VALUE 'Y'.
       01  WS-ACQ-EOF-FLAG               PIC X(01) VALUE 'N'.
           88  WS-ACQ-EOF                VALUE 'Y'.

       01  WS-MATCH-KEY-STL              PIC X(20).
       01  WS-MATCH-KEY-ACQ              PIC X(20).

      * COUNTERS
       01  WS-MATCHED-COUNT              PIC 9(09) VALUE ZEROS.
       01  WS-UNMATCHED-STL-COUNT        PIC 9(09) VALUE ZEROS.
       01  WS-UNMATCHED-ACQ-COUNT        PIC 9(09) VALUE ZEROS.
       01  WS-AMOUNT-MISMATCH-COUNT      PIC 9(09) VALUE ZEROS.
       01  WS-STL-READ-COUNT             PIC 9(09) VALUE ZEROS.
       01  WS-ACQ-READ-COUNT             PIC 9(09) VALUE ZEROS.

       01  WS-MATCHED-AMOUNT             PIC 9(13)V99
                                         VALUE ZEROS.
       01  WS-UNMATCHED-AMOUNT           PIC 9(13)V99
                                         VALUE ZEROS.

       01  WS-EDIT-AMT                   PIC 9(11)99.

       01  WS-RPT-HEADER.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(55) VALUE
               'SETTLEMENT SYSTEM - TRANSACTION MATCHING REPORT     '.
           05  FILLER                    PIC X(25) VALUE SPACES.
           05  FILLER                    PIC X(06) VALUE 'DATE: '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(31) VALUE SPACES.

       01  WS-RPT-SUM-LINE.
           05  FILLER                    PIC X(01) VALUE ' '.
           05  WS-RPT-SUM-LABEL         PIC X(40).
           05  WS-RPT-SUM-VALUE         PIC X(20).
           05  FILLER                    PIC X(72) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-MATCH-PROCESS
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

           OPEN INPUT  SETTLE-SORTED-FILE
                       ACQUIRER-FILE
           OPEN OUTPUT MATCH-OUTPUT-FILE
                       MATCH-ERROR-FILE
                       MATCH-REPORT-FILE

           IF WS-VSAM-FILE-STATUS NOT = '00'
               DISPLAY 'SORTED FILE OPEN ERROR: '
                   WS-VSAM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-HEADER

           PERFORM 2100-READ-SETTLE
           PERFORM 2200-READ-ACQUIRER
           .

      ******************************************************************
      * 2000-MATCH-PROCESS: SEQUENTIAL MATCHING ALGORITHM              *
      *   BOTH FILES SORTED BY TRANSACTION ID                          *
      *   IF STL-KEY = ACQ-KEY -> MATCHED (VERIFY AMOUNTS)            *
      *   IF STL-KEY < ACQ-KEY -> UNMATCHED SETTLEMENT                 *
      *   IF STL-KEY > ACQ-KEY -> UNMATCHED ACQUIRER                   *
      ******************************************************************
       2000-MATCH-PROCESS.
           PERFORM UNTIL WS-STL-EOF AND WS-ACQ-EOF
               EVALUATE TRUE
                   WHEN WS-STL-EOF AND NOT WS-ACQ-EOF
                       PERFORM 2500-UNMATCHED-ACQUIRER
                       PERFORM 2200-READ-ACQUIRER
                   WHEN NOT WS-STL-EOF AND WS-ACQ-EOF
                       PERFORM 2400-UNMATCHED-SETTLEMENT
                       PERFORM 2100-READ-SETTLE
                   WHEN NOT WS-STL-EOF AND NOT WS-ACQ-EOF
                       EVALUATE TRUE
                           WHEN WS-MATCH-KEY-STL = WS-MATCH-KEY-ACQ
                               PERFORM 2300-MATCH-FOUND
                               PERFORM 2100-READ-SETTLE
                               PERFORM 2200-READ-ACQUIRER
                           WHEN WS-MATCH-KEY-STL < WS-MATCH-KEY-ACQ
                               PERFORM 2400-UNMATCHED-SETTLEMENT
                               PERFORM 2100-READ-SETTLE
                           WHEN OTHER
                               PERFORM 2500-UNMATCHED-ACQUIRER
                               PERFORM 2200-READ-ACQUIRER
                       END-EVALUATE
               END-EVALUATE
           END-PERFORM
           .

       2100-READ-SETTLE.
           READ SETTLE-SORTED-FILE
               INTO SETTLE-SORTED-RECORD
               AT END
                   SET WS-STL-EOF TO TRUE
                   MOVE HIGH-VALUES TO WS-MATCH-KEY-STL
               NOT AT END
                   ADD 1 TO WS-STL-READ-COUNT
                   MOVE SETTLE-SORTED-RECORD
                       TO WS-SETTLE-TXN-REC
                   MOVE WS-ST-TXN-ID TO WS-MATCH-KEY-STL
           END-READ
           .

       2200-READ-ACQUIRER.
           READ ACQUIRER-FILE INTO ACQUIRER-RECORD
               AT END
                   SET WS-ACQ-EOF TO TRUE
                   MOVE HIGH-VALUES TO WS-MATCH-KEY-ACQ
               NOT AT END
                   ADD 1 TO WS-ACQ-READ-COUNT
                   MOVE ACQUIRER-RECORD TO WS-ACQ-REC
                   MOVE WS-ACQ-TXN-ID TO WS-MATCH-KEY-ACQ
           END-READ
           .

      ******************************************************************
      * 2300-MATCH-FOUND: TRANSACTION IDS MATCH - VERIFY AMOUNTS      *
      ******************************************************************
       2300-MATCH-FOUND.
           IF WS-ST-TXN-AMOUNT = WS-ACQ-TXN-AMOUNT
               MOVE 'MT' TO WS-ST-SETTLE-STATUS
               ADD 1 TO WS-MATCHED-COUNT
               ADD WS-ST-TXN-AMOUNT TO WS-MATCHED-AMOUNT
               PERFORM 2310-WRITE-MATCHED
           ELSE
               MOVE 'DI' TO WS-ST-SETTLE-STATUS
               ADD 1 TO WS-AMOUNT-MISMATCH-COUNT
               PERFORM 2320-WRITE-AMOUNT-MISMATCH
           END-IF
           .

       2310-WRITE-MATCHED.
           INITIALIZE MATCH-OUTPUT-RECORD
           MOVE 'MATCHED  '           TO MATCH-OUTPUT-RECORD(1:10)
           MOVE WS-ST-SETTLE-ID       TO MATCH-OUTPUT-RECORD(11:20)
           MOVE WS-ST-TXN-ID          TO MATCH-OUTPUT-RECORD(31:20)
           MOVE WS-ST-CARD-NUMBER     TO MATCH-OUTPUT-RECORD(51:16)
           MOVE WS-ST-TXN-AMOUNT      TO WS-EDIT-AMT
           MOVE WS-EDIT-AMT           TO MATCH-OUTPUT-RECORD(67:13)
           MOVE WS-ST-NETWORK-ID      TO MATCH-OUTPUT-RECORD(80:04)
           MOVE WS-ACQ-AUTH-CODE      TO MATCH-OUTPUT-RECORD(84:06)
           WRITE MATCH-OUTPUT-RECORD
           .

       2320-WRITE-AMOUNT-MISMATCH.
           INITIALIZE MATCH-ERROR-RECORD
           MOVE 'AMT-DIFF '           TO MATCH-ERROR-RECORD(1:10)
           MOVE WS-ST-TXN-ID          TO MATCH-ERROR-RECORD(11:20)
           MOVE WS-ST-TXN-AMOUNT      TO WS-EDIT-AMT
           MOVE WS-EDIT-AMT           TO MATCH-ERROR-RECORD(31:13)
           MOVE WS-ACQ-TXN-AMOUNT     TO WS-EDIT-AMT
           MOVE WS-EDIT-AMT           TO MATCH-ERROR-RECORD(44:13)
           WRITE MATCH-ERROR-RECORD
           .

      ******************************************************************
      * 2400-UNMATCHED-SETTLEMENT: STL RECORD WITH NO ACQ MATCH       *
      ******************************************************************
       2400-UNMATCHED-SETTLEMENT.
           MOVE 'UM' TO WS-ST-SETTLE-STATUS
           ADD 1 TO WS-UNMATCHED-STL-COUNT
           ADD WS-ST-TXN-AMOUNT TO WS-UNMATCHED-AMOUNT

           INITIALIZE MATCH-ERROR-RECORD
           MOVE 'UNMT-STL '           TO MATCH-ERROR-RECORD(1:10)
           MOVE WS-ST-SETTLE-ID       TO MATCH-ERROR-RECORD(11:20)
           MOVE WS-ST-TXN-ID          TO MATCH-ERROR-RECORD(31:20)
           MOVE WS-ST-CARD-NUMBER     TO MATCH-ERROR-RECORD(51:16)
           MOVE WS-ST-TXN-AMOUNT      TO WS-EDIT-AMT
           MOVE WS-EDIT-AMT           TO MATCH-ERROR-RECORD(67:13)
           WRITE MATCH-ERROR-RECORD
           .

      ******************************************************************
      * 2500-UNMATCHED-ACQUIRER: ACQ RECORD WITH NO STL MATCH         *
      ******************************************************************
       2500-UNMATCHED-ACQUIRER.
           ADD 1 TO WS-UNMATCHED-ACQ-COUNT

           INITIALIZE MATCH-ERROR-RECORD
           MOVE 'UNMT-ACQ '           TO MATCH-ERROR-RECORD(1:10)
           MOVE WS-ACQ-TXN-ID        TO MATCH-ERROR-RECORD(11:20)
           MOVE WS-ACQ-CARD-NUMBER   TO MATCH-ERROR-RECORD(31:16)
           MOVE WS-ACQ-TXN-AMOUNT    TO WS-EDIT-AMT
           MOVE WS-EDIT-AMT          TO MATCH-ERROR-RECORD(47:13)
           WRITE MATCH-ERROR-RECORD
           .

       3000-WRITE-SUMMARY.
           MOVE 'SETTLEMENT RECORDS READ:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-STL-READ-COUNT               TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'ACQUIRER RECORDS READ:      ' TO WS-RPT-SUM-LABEL
           MOVE WS-ACQ-READ-COUNT               TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'MATCHED TRANSACTIONS:       ' TO WS-RPT-SUM-LABEL
           MOVE WS-MATCHED-COUNT                TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'UNMATCHED SETTLEMENT RECS:  ' TO WS-RPT-SUM-LABEL
           MOVE WS-UNMATCHED-STL-COUNT          TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'UNMATCHED ACQUIRER RECS:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-UNMATCHED-ACQ-COUNT          TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'AMOUNT MISMATCHES:          ' TO WS-RPT-SUM-LABEL
           MOVE WS-AMOUNT-MISMATCH-COUNT        TO WS-RPT-SUM-VALUE
           WRITE MATCH-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

       9000-TERMINATE.
           CLOSE SETTLE-SORTED-FILE
                 ACQUIRER-FILE
                 MATCH-OUTPUT-FILE
                 MATCH-ERROR-FILE
                 MATCH-REPORT-FILE

           DISPLAY 'STLMT200 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
