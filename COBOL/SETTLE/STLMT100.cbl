       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLMT100.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     STLMT100                                          *
      * DESCRIPTION: SETTLEMENT - DAILY TRANSACTION EXTRACT            *
      *              READS TRANSACTION INPUT FILE FROM CARD NETWORKS,  *
      *              VALIDATES AND FORMATS RECORDS, WRITES TO VSAM     *
      *              SETTLEMENT TRANSACTION FILE FOR DOWNSTREAM.       *
      * INPUT:       TXNINP   - NETWORK TRANSACTION FILE (SEQUENTIAL)  *
      * OUTPUT:      STLVSAM  - SETTLEMENT VSAM KSDS FILE             *
      *              STLERR   - REJECTED TRANSACTIONS FILE             *
      *              STLRPT   - EXTRACTION SUMMARY REPORT              *
      * FREQUENCY:   DAILY BATCH                                       *
      * NOTE:        SETTLEMENT IS FULLY BATCH, NO ONLINE, NO DB2     *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-INPUT-FILE
               ASSIGN TO TXNINP
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT SETTLE-VSAM-FILE
               ASSIGN TO STLVSAM
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS STL-VSAM-KEY
               FILE STATUS IS WS-VSAM-FILE-STATUS.

           SELECT SETTLE-ERROR-FILE
               ASSIGN TO STLERR
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERR-FILE-STATUS.

           SELECT SETTLE-REPORT-FILE
               ASSIGN TO STLRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  TXN-INPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 250 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  TXN-INPUT-RECORD               PIC X(250).

       FD  SETTLE-VSAM-FILE.
       01  SETTLE-VSAM-RECORD.
           05  STL-VSAM-KEY.
               10  STL-VSAM-SETTLE-ID     PIC X(20).
           05  STL-VSAM-DATA              PIC X(230).

       FD  SETTLE-ERROR-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 330 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  SETTLE-ERROR-RECORD            PIC X(330).

       FD  SETTLE-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  SETTLE-REPORT-RECORD           PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'STLMT100'.

       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-VSAM-FILE-STATUS            PIC X(02).
       01  WS-ERR-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYSTL01.
           COPY CPYCOM01.
           COPY CPYERR01.

      * INPUT NETWORK TRANSACTION LAYOUT
       01  WS-NETWORK-TXN-REC.
           05  WS-NET-TXN-ID              PIC X(20).
           05  WS-NET-CARD-NUMBER         PIC X(16).
           05  WS-NET-ACCOUNT-NUMBER      PIC X(12).
           05  WS-NET-TXN-TYPE            PIC X(02).
           05  WS-NET-TXN-AMOUNT          PIC S9(11)V99 COMP-3.
           05  WS-NET-TXN-DATE            PIC X(10).
           05  WS-NET-MERCHANT-ID         PIC X(15).
           05  WS-NET-MERCHANT-NAME       PIC X(40).
           05  WS-NET-ACQUIRER-ID         PIC X(11).
           05  WS-NET-ISSUER-ID           PIC X(11).
           05  WS-NET-NETWORK-ID          PIC X(04).
           05  WS-NET-INTERCHANGE-FEE     PIC S9(07)V99 COMP-3.
           05  FILLER                     PIC X(93).

      * SETTLEMENT SEQUENCE
       01  WS-SETTLE-SEQ                  PIC 9(06) VALUE ZEROS.
       01  WS-SETTLE-DATE                 PIC X(10).

      * COUNTERS BY NETWORK
       01  WS-VISA-COUNT                  PIC 9(09) VALUE ZEROS.
       01  WS-MC-COUNT                    PIC 9(09) VALUE ZEROS.
       01  WS-STAR-COUNT                  PIC 9(09) VALUE ZEROS.
       01  WS-OTHER-NET-COUNT             PIC 9(09) VALUE ZEROS.

      * AMOUNT TOTALS
       01  WS-TOTAL-AMOUNT                PIC S9(13)V99 COMP-3
                                          VALUE ZEROS.
       01  WS-TOTAL-FEES                  PIC S9(11)V99 COMP-3
                                          VALUE ZEROS.

      * REPORT LINES
       01  WS-RPT-HEADER.
           05  FILLER                    PIC X(01) VALUE '1'.
           05  FILLER                    PIC X(05) VALUE SPACES.
           05  FILLER                    PIC X(55) VALUE
               'SETTLEMENT SYSTEM - DAILY TRANSACTION EXTRACT REPORT'.
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
           PERFORM 2000-PROCESS-TRANSACTIONS
               UNTIL WS-EOF
           PERFORM 3000-WRITE-SUMMARY
           PERFORM 9000-TERMINATE
           STOP RUN.

      ******************************************************************
      * 1000-INITIALIZE                                                *
      ******************************************************************
       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING
           MOVE WS-FORMATTED-DATE TO WS-SETTLE-DATE

           OPEN INPUT  TXN-INPUT-FILE
           OPEN OUTPUT SETTLE-VSAM-FILE
                       SETTLE-ERROR-FILE
                       SETTLE-REPORT-FILE

           IF WS-INP-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING INPUT FILE: '
                   WS-INP-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF

           IF WS-VSAM-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING VSAM FILE: '
                   WS-VSAM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               PERFORM 9000-TERMINATE
               STOP RUN
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-RPT-DATE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-HEADER

           PERFORM 2100-READ-INPUT
           .

      ******************************************************************
      * 2000-PROCESS-TRANSACTIONS: MAIN LOOP                          *
      ******************************************************************
       2000-PROCESS-TRANSACTIONS.
           MOVE TXN-INPUT-RECORD TO WS-NETWORK-TXN-REC
           ADD 1 TO WS-RECORDS-READ

           PERFORM 2200-VALIDATE-TRANSACTION
           IF WS-CONTINUE-PROCESS
               PERFORM 2300-FORMAT-SETTLEMENT-REC
               PERFORM 2400-WRITE-VSAM
               PERFORM 2500-ACCUMULATE-TOTALS
           ELSE
               PERFORM 2600-WRITE-ERROR
               ADD 1 TO WS-RECORDS-REJECTED
               SET WS-CONTINUE-PROCESS TO TRUE
           END-IF

           PERFORM 2100-READ-INPUT
           .

       2100-READ-INPUT.
           READ TXN-INPUT-FILE
               INTO TXN-INPUT-RECORD
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

      ******************************************************************
      * 2200-VALIDATE-TRANSACTION: VALIDATE NETWORK TRANSACTION       *
      ******************************************************************
       2200-VALIDATE-TRANSACTION.
           SET WS-CONTINUE-PROCESS TO TRUE

           IF WS-NET-TXN-ID = SPACES
               MOVE 'TRANSACTION ID IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-NET-CARD-NUMBER = SPACES
               MOVE 'CARD NUMBER IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-NET-TXN-AMOUNT = ZEROS
               MOVE 'TRANSACTION AMOUNT IS ZERO'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-NET-TXN-DATE = SPACES
               MOVE 'TRANSACTION DATE IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF WS-NET-NETWORK-ID NOT = 'VISA'
              AND WS-NET-NETWORK-ID NOT = 'MC  '
              AND WS-NET-NETWORK-ID NOT = 'STAR'
               MOVE 'INVALID NETWORK ID'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF
           .

      ******************************************************************
      * 2300-FORMAT-SETTLEMENT-REC: BUILD VSAM RECORD                 *
      ******************************************************************
       2300-FORMAT-SETTLEMENT-REC.
           ADD 1 TO WS-SETTLE-SEQ

           INITIALIZE WS-SETTLE-TXN-REC

      *    GENERATE SETTLEMENT ID: DATE + SEQ
           STRING WS-CURRENT-YEAR
                  WS-CURRENT-MONTH
                  WS-CURRENT-DAY
                  WS-SETTLE-SEQ
               DELIMITED BY SIZE
               INTO WS-ST-SETTLE-ID
           END-STRING

           MOVE WS-NET-TXN-ID         TO WS-ST-TXN-ID
           MOVE WS-NET-CARD-NUMBER     TO WS-ST-CARD-NUMBER
           MOVE WS-NET-ACCOUNT-NUMBER  TO WS-ST-ACCOUNT-NUMBER
           MOVE WS-NET-TXN-TYPE        TO WS-ST-TXN-TYPE
           MOVE WS-NET-TXN-AMOUNT      TO WS-ST-TXN-AMOUNT
           MOVE WS-NET-TXN-DATE        TO WS-ST-TXN-DATE
           MOVE WS-NET-MERCHANT-ID     TO WS-ST-MERCHANT-ID
           MOVE WS-NET-MERCHANT-NAME   TO WS-ST-MERCHANT-NAME
           MOVE WS-NET-ACQUIRER-ID     TO WS-ST-ACQUIRER-ID
           MOVE WS-NET-ISSUER-ID       TO WS-ST-ISSUER-ID
           MOVE WS-NET-NETWORK-ID      TO WS-ST-NETWORK-ID
           MOVE WS-NET-INTERCHANGE-FEE TO WS-ST-INTERCHANGE-FEE
           MOVE 'PE'                   TO WS-ST-SETTLE-STATUS
           MOVE WS-SETTLE-DATE         TO WS-ST-SETTLE-DATE
           MOVE WS-SETTLE-SEQ          TO WS-ST-BATCH-SEQ-NUM

           MOVE FUNCTION CURRENT-DATE  TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY '-'
                  WS-CURRENT-HOUR '.'
                  WS-CURRENT-MIN '.'
                  WS-CURRENT-SEC
               DELIMITED BY SIZE
               INTO WS-ST-CREATED-TIMESTAMP
           END-STRING
           .

      ******************************************************************
      * 2400-WRITE-VSAM: WRITE RECORD TO VSAM KSDS                   *
      ******************************************************************
       2400-WRITE-VSAM.
           MOVE WS-ST-SETTLE-ID TO STL-VSAM-KEY
           MOVE WS-SETTLE-TXN-REC TO SETTLE-VSAM-RECORD

           WRITE SETTLE-VSAM-RECORD
           EVALUATE WS-VSAM-FILE-STATUS
               WHEN '00'
                   ADD 1 TO WS-RECORDS-WRITTEN
               WHEN '22'
                   MOVE 'DUPLICATE KEY IN VSAM'
                       TO WS-ERR-MESSAGE
                   PERFORM 2600-WRITE-ERROR
                   ADD 1 TO WS-RECORDS-REJECTED
               WHEN OTHER
                   DISPLAY 'VSAM WRITE ERROR: '
                       WS-VSAM-FILE-STATUS
                   MOVE 16 TO WS-RETURN-CODE
                   PERFORM 9000-TERMINATE
                   STOP RUN
           END-EVALUATE
           .

      ******************************************************************
      * 2500-ACCUMULATE-TOTALS: ACCUMULATE RUNNING TOTALS             *
      ******************************************************************
       2500-ACCUMULATE-TOTALS.
           ADD WS-NET-TXN-AMOUNT TO WS-TOTAL-AMOUNT
           ADD WS-NET-INTERCHANGE-FEE TO WS-TOTAL-FEES

           EVALUATE WS-NET-NETWORK-ID
               WHEN 'VISA'  ADD 1 TO WS-VISA-COUNT
               WHEN 'MC  '  ADD 1 TO WS-MC-COUNT
               WHEN 'STAR'  ADD 1 TO WS-STAR-COUNT
               WHEN OTHER   ADD 1 TO WS-OTHER-NET-COUNT
           END-EVALUATE
           .

      ******************************************************************
      * 2600-WRITE-ERROR: WRITE REJECTED RECORD                       *
      ******************************************************************
       2600-WRITE-ERROR.
           INITIALIZE SETTLE-ERROR-RECORD
           MOVE TXN-INPUT-RECORD TO SETTLE-ERROR-RECORD(1:250)
           MOVE WS-ERR-MESSAGE   TO SETTLE-ERROR-RECORD(251:80)
           WRITE SETTLE-ERROR-RECORD
           .

      ******************************************************************
      * 3000-WRITE-SUMMARY                                            *
      ******************************************************************
       3000-WRITE-SUMMARY.
           MOVE 'RECORDS READ:              ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ               TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'RECORDS WRITTEN TO VSAM:   ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-WRITTEN            TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'RECORDS REJECTED:          ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-REJECTED           TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'VISA TRANSACTIONS:         ' TO WS-RPT-SUM-LABEL
           MOVE WS-VISA-COUNT                 TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'MASTERCARD TRANSACTIONS:   ' TO WS-RPT-SUM-LABEL
           MOVE WS-MC-COUNT                   TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'STAR NETWORK TRANSACTIONS: ' TO WS-RPT-SUM-LABEL
           MOVE WS-STAR-COUNT                 TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL TRANSACTION AMOUNT:  ' TO WS-RPT-SUM-LABEL
           MOVE WS-TOTAL-AMOUNT               TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL INTERCHANGE FEES:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-TOTAL-FEES                 TO WS-RPT-SUM-VALUE
           WRITE SETTLE-REPORT-RECORD FROM WS-RPT-SUM-LINE
           .

      ******************************************************************
      * 9000-TERMINATE                                                 *
      ******************************************************************
       9000-TERMINATE.
           CLOSE TXN-INPUT-FILE
                 SETTLE-VSAM-FILE
                 SETTLE-ERROR-FILE
                 SETTLE-REPORT-FILE

           DISPLAY 'STLMT100 PROCESSING COMPLETE'
           DISPLAY 'RECORDS READ:    ' WS-RECORDS-READ
           DISPLAY 'RECORDS WRITTEN: ' WS-RECORDS-WRITTEN
           DISPLAY 'RECORDS REJECTED:' WS-RECORDS-REJECTED

           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
