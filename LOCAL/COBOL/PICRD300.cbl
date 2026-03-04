       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD300.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PICRD300 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD STATUS UPDATE PROGRAM    *
      *              PROCESSES STATUS CHANGES: BLOCK, UNBLOCK, CLOSE   *
      *              VALIDATES TRANSITIONS, UPDATES CARD MASTER,       *
      *              WRITES HISTORY TO INDEXED FILE.                  *
      * INPUT:       STSINP   - STATUS CHANGE REQUEST FILE             *
      * OUTPUT:      STSOUT   - STATUS UPDATE CONFIRMATION FILE        *
      *              STSERR   - REJECTED STATUS CHANGES FILE           *
      *              STSRPT   - STATUS UPDATE SUMMARY REPORT           *
      *              CARDMAST - CARD MASTER INDEXED FILE (I-O)         *
      *              HISTFILE - STATUS HISTORY INDEXED FILE (OUTPUT)    *
      * NOTE:        DB2 REPLACED WITH INDEXED FILE READ/REWRITE       *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT STATUS-INPUT-FILE
               ASSIGN TO "DATA/STSINP.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT STATUS-OUTPUT-FILE
               ASSIGN TO "OUTPUT/STSOUT.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT STATUS-ERROR-FILE
               ASSIGN TO "OUTPUT/STSERR.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERROUT-STATUS.

           SELECT STATUS-REPORT-FILE
               ASSIGN TO "OUTPUT/STSRPT.txt"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

           SELECT CARD-MASTER-FILE
               ASSIGN TO "DATA/CARDMAST.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

           SELECT HISTORY-FILE
               ASSIGN TO "DATA/CARDHIST.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS HF-HISTORY-KEY
               FILE STATUS IS WS-HF-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  STATUS-INPUT-FILE
           RECORD CONTAINS 100 CHARACTERS.
       01  STATUS-INPUT-RECORD            PIC X(100).

       FD  STATUS-OUTPUT-FILE
           RECORD CONTAINS 120 CHARACTERS.
       01  STATUS-OUTPUT-RECORD           PIC X(120).

       FD  STATUS-ERROR-FILE
           RECORD CONTAINS 180 CHARACTERS.
       01  STATUS-ERROR-RECORD            PIC X(180).

       FD  STATUS-REPORT-FILE
           RECORD CONTAINS 133 CHARACTERS.
       01  STATUS-REPORT-RECORD           PIC X(133).

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       FD  HISTORY-FILE.
       01  HISTORY-FILE-RECORD.
           05  HF-HISTORY-KEY.
               10  HF-CARD-NUMBER        PIC X(16).
               10  HF-SEQ-NUM            PIC 9(06).
           05  HF-DATA                   PIC X(78).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD300'.

       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-ERROUT-STATUS               PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).
       01  WS-CM-FILE-STATUS              PIC X(02).
       01  WS-HF-FILE-STATUS              PIC X(02).

           COPY CPYCRD01.
           COPY CPYHIST1.
           COPY CPYCOM01.
           COPY CPYERR01.

      * INPUT RECORD LAYOUT
       01  WS-STS-INPUT-REC.
           05  WS-STS-CARD-NUMBER         PIC X(16).
           05  WS-STS-ACTION-CODE         PIC X(02).
               88  WS-STS-ACT-BLOCK       VALUE 'BL'.
               88  WS-STS-ACT-UNBLOCK     VALUE 'UB'.
               88  WS-STS-ACT-CLOSE       VALUE 'CL'.
               88  WS-STS-ACT-HOTLIST     VALUE 'HL'.
           05  WS-STS-REASON-CODE         PIC X(04).
           05  WS-STS-REQUESTOR-ID        PIC X(10).
           05  WS-STS-CHANNEL             PIC X(02).
           05  FILLER                     PIC X(66).

      * STATUS TRANSITION VALIDATION
       01  WS-VALID-TRANSITION-FLAG       PIC X(01).
           88  WS-VALID-TRANSITION        VALUE 'Y'.
           88  WS-INVALID-TRANSITION      VALUE 'N'.

       01  WS-NEW-STATUS                  PIC X(02).
       01  WS-OLD-STATUS                  PIC X(02).

      * HISTORY SEQUENCE COUNTER
       01  WS-HIST-SEQ                    PIC 9(06) VALUE ZEROS.

      * COUNTERS BY ACTION
       01  WS-BLOCK-COUNT                 PIC 9(07) VALUE ZEROS.
       01  WS-UNBLOCK-COUNT               PIC 9(07) VALUE ZEROS.
       01  WS-CLOSE-COUNT                 PIC 9(07) VALUE ZEROS.
       01  WS-HOTLIST-COUNT               PIC 9(07) VALUE ZEROS.

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

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING

           OPEN INPUT  STATUS-INPUT-FILE
           OPEN OUTPUT STATUS-OUTPUT-FILE
                       STATUS-ERROR-FILE
                       STATUS-REPORT-FILE
           OPEN I-O    CARD-MASTER-FILE

           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               STOP RUN
           END-IF

      *    OPEN HISTORY FILE - OUTPUT IF NEW, I-O IF EXISTS
           OPEN I-O HISTORY-FILE
           IF WS-HF-FILE-STATUS = '35'
               OPEN OUTPUT HISTORY-FILE
           END-IF
           IF WS-HF-FILE-STATUS NOT = '00'
               DISPLAY '*** HISTORY FILE OPEN ERROR: '
                   WS-HF-FILE-STATUS
               MOVE 16 TO WS-RETURN-CODE
               STOP RUN
           END-IF

           PERFORM 2100-READ-INPUT
           .

       2000-PROCESS-RECORDS.
           MOVE STATUS-INPUT-RECORD TO WS-STS-INPUT-REC
           ADD 1 TO WS-RECORDS-READ

           PERFORM 2200-VALIDATE-REQUEST
           IF WS-CONTINUE-PROCESS
               PERFORM 2300-VALIDATE-TRANSITION
               IF WS-VALID-TRANSITION
                   PERFORM 2400-UPDATE-STATUS
                   PERFORM 2500-INSERT-HISTORY
                   PERFORM 2600-WRITE-OUTPUT
               ELSE
                   PERFORM 2700-WRITE-ERROR
                   ADD 1 TO WS-RECORDS-REJECTED
               END-IF
           ELSE
               PERFORM 2700-WRITE-ERROR
               ADD 1 TO WS-RECORDS-REJECTED
               SET WS-CONTINUE-PROCESS TO TRUE
           END-IF

           PERFORM 2100-READ-INPUT
           .

       2100-READ-INPUT.
           READ STATUS-INPUT-FILE
               INTO STATUS-INPUT-RECORD
               AT END SET WS-EOF TO TRUE
               NOT AT END CONTINUE
           END-READ
           .

      ******************************************************************
      * 2200-VALIDATE-REQUEST: VALIDATE INPUT FIELDS                  *
      ******************************************************************
       2200-VALIDATE-REQUEST.
           SET WS-CONTINUE-PROCESS TO TRUE

           IF WS-STS-CARD-NUMBER = SPACES
               MOVE 'CARD NUMBER IS BLANK'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF

           IF NOT (WS-STS-ACT-BLOCK OR WS-STS-ACT-UNBLOCK
              OR WS-STS-ACT-CLOSE OR WS-STS-ACT-HOTLIST)
               MOVE 'INVALID ACTION CODE'
                   TO WS-ERR-MESSAGE
               SET WS-STOP-PROCESS TO TRUE
           END-IF
           .

      ******************************************************************
      * 2300-VALIDATE-TRANSITION: CHECK VALID STATUS TRANSITION       *
      *   VALID TRANSITIONS:                                           *
      *     AC -> BL (BLOCK)    BL -> AC (UNBLOCK)                     *
      *     AC -> CL (CLOSE)    NW -> CL (CLOSE)   BL -> CL (CLOSE)  *
      *     AC -> HL (HOTLIST = BLOCK)                                 *
      ******************************************************************
       2300-VALIDATE-TRANSITION.
           SET WS-VALID-TRANSITION TO TRUE

      *    READ CARD FROM MASTER FILE
           MOVE WS-STS-CARD-NUMBER TO CM-CARD-NUMBER
           READ CARD-MASTER-FILE
               INTO WS-CARD-MASTER-REC
               KEY IS CM-CARD-NUMBER
               INVALID KEY
                   MOVE 'CARD NOT FOUND' TO WS-ERR-MESSAGE
                   SET WS-INVALID-TRANSITION TO TRUE
               NOT INVALID KEY
                   CONTINUE
           END-READ

           IF WS-VALID-TRANSITION
               MOVE WS-CM-CARD-STATUS TO WS-OLD-STATUS
               EVALUATE TRUE
                   WHEN WS-STS-ACT-BLOCK
                       IF WS-CM-CARD-STATUS = 'AC'
                           MOVE 'BL' TO WS-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT BLOCK - NOT ACTIVE'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-UNBLOCK
                       IF WS-CM-CARD-STATUS = 'BL'
                           MOVE 'AC' TO WS-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT UNBLOCK - NOT BLOCKED'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-CLOSE
                       IF WS-CM-CARD-STATUS = 'AC'
                          OR WS-CM-CARD-STATUS = 'NW'
                          OR WS-CM-CARD-STATUS = 'BL'
                           MOVE 'CL' TO WS-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT CLOSE FROM STATUS'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-HOTLIST
                       IF WS-CM-CARD-STATUS = 'AC'
                           MOVE 'BL' TO WS-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT HOTLIST - NOT ACTIVE'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
               END-EVALUATE
           END-IF
           .

      ******************************************************************
      * 2400-UPDATE-STATUS: UPDATE CARD STATUS VIA REWRITE            *
      ******************************************************************
       2400-UPDATE-STATUS.
           MOVE WS-NEW-STATUS TO WS-CM-CARD-STATUS

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
               EVALUATE TRUE
                   WHEN WS-STS-ACT-BLOCK
                       ADD 1 TO WS-BLOCK-COUNT
                   WHEN WS-STS-ACT-UNBLOCK
                       ADD 1 TO WS-UNBLOCK-COUNT
                   WHEN WS-STS-ACT-CLOSE
                       ADD 1 TO WS-CLOSE-COUNT
                   WHEN WS-STS-ACT-HOTLIST
                       ADD 1 TO WS-HOTLIST-COUNT
               END-EVALUATE
           ELSE
               DISPLAY '*** REWRITE ERROR: ' WS-CM-FILE-STATUS
               MOVE 'STATUS UPDATE FAILED' TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

      ******************************************************************
      * 2500-INSERT-HISTORY: WRITE STATUS CHANGE TO HISTORY FILE      *
      ******************************************************************
       2500-INSERT-HISTORY.
           ADD 1 TO WS-HIST-SEQ

           INITIALIZE WS-STATUS-HISTORY-REC
           MOVE WS-STS-CARD-NUMBER  TO WS-SH-CARD-NUMBER
           MOVE WS-HIST-SEQ         TO WS-SH-SEQ-NUM
           MOVE WS-OLD-STATUS       TO WS-SH-PREVIOUS-STATUS
           MOVE WS-NEW-STATUS       TO WS-SH-NEW-STATUS
           MOVE WS-STS-REASON-CODE  TO WS-SH-REASON-CODE
           MOVE WS-STS-REQUESTOR-ID TO WS-SH-REQUESTOR-ID
           MOVE WS-FORMATTED-DATE   TO WS-SH-STATUS-DATE

           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY '-'
                  WS-CURRENT-HOUR '.'
                  WS-CURRENT-MIN '.'
                  WS-CURRENT-SEC
               DELIMITED BY SIZE
               INTO WS-SH-CREATED-TIMESTAMP
           END-STRING

           MOVE WS-STATUS-HISTORY-REC TO HISTORY-FILE-RECORD
           WRITE HISTORY-FILE-RECORD

           IF WS-HF-FILE-STATUS NOT = '00'
               DISPLAY '*** HISTORY WRITE ERROR: '
                   WS-HF-FILE-STATUS
               MOVE 'HISTORY INSERT FAILED' TO WS-ERR-MESSAGE
               MOVE 'W' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

       2600-WRITE-OUTPUT.
           INITIALIZE STATUS-OUTPUT-RECORD
           MOVE WS-STS-CARD-NUMBER    TO STATUS-OUTPUT-RECORD(1:16)
           MOVE WS-OLD-STATUS         TO STATUS-OUTPUT-RECORD(17:02)
           MOVE WS-NEW-STATUS         TO STATUS-OUTPUT-RECORD(19:02)
           MOVE WS-STS-ACTION-CODE    TO STATUS-OUTPUT-RECORD(21:02)
           MOVE WS-STS-REASON-CODE    TO STATUS-OUTPUT-RECORD(23:04)
           MOVE WS-FORMATTED-DATE     TO STATUS-OUTPUT-RECORD(27:10)
           WRITE STATUS-OUTPUT-RECORD
           .

       2700-WRITE-ERROR.
           INITIALIZE STATUS-ERROR-RECORD
           MOVE STATUS-INPUT-RECORD TO STATUS-ERROR-RECORD(1:100)
           MOVE WS-ERR-MESSAGE      TO STATUS-ERROR-RECORD(101:80)
           WRITE STATUS-ERROR-RECORD
           .

       3000-WRITE-SUMMARY.
           MOVE 'TOTAL RECORDS READ:       ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-READ               TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS BLOCKED:      ' TO WS-RPT-SUM-LABEL
           MOVE WS-BLOCK-COUNT                TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS UNBLOCKED:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-UNBLOCK-COUNT              TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS CLOSED:       ' TO WS-RPT-SUM-LABEL
           MOVE WS-CLOSE-COUNT                TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL CARDS HOTLISTED:    ' TO WS-RPT-SUM-LABEL
           MOVE WS-HOTLIST-COUNT              TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE

           MOVE 'TOTAL RECORDS REJECTED:   ' TO WS-RPT-SUM-LABEL
           MOVE WS-RECORDS-REJECTED           TO WS-RPT-SUM-COUNT
           WRITE STATUS-REPORT-RECORD FROM WS-RPT-SUM-LINE
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
           CLOSE STATUS-INPUT-FILE
                 STATUS-OUTPUT-FILE
                 STATUS-ERROR-FILE
                 STATUS-REPORT-FILE
                 CARD-MASTER-FILE
                 HISTORY-FILE

           DISPLAY 'PICRD300 PROCESSING COMPLETE'
           DISPLAY 'RECORDS READ:    ' WS-RECORDS-READ
           DISPLAY 'RECORDS UPDATED: ' WS-RECORDS-UPDATED
           DISPLAY 'RECORDS REJECTED:' WS-RECORDS-REJECTED

           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
