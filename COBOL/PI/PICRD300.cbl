       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PICRD300.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PICRD300                                          *
      * DESCRIPTION: PLASTIC ISSUANCE - CARD STATUS UPDATE PROGRAM    *
      *              PROCESSES STATUS CHANGES: BLOCK, UNBLOCK, CLOSE   *
      *              VALIDATES TRANSITIONS AND UPDATES DB2.            *
      * INPUT:       STSINP   - STATUS CHANGE REQUEST FILE             *
      * OUTPUT:      STSOUT   - STATUS UPDATE CONFIRMATION FILE        *
      *              STSERR   - REJECTED STATUS CHANGES FILE           *
      *              STSRPT   - STATUS UPDATE SUMMARY REPORT           *
      * DATABASE:    TB_CARD_MASTER (SELECT, UPDATE)                   *
      *              TB_CARD_STATUS_HISTORY (INSERT)                   *
      * FREQUENCY:   DAILY BATCH                                       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT STATUS-INPUT-FILE
               ASSIGN TO STSINP
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INP-FILE-STATUS.

           SELECT STATUS-OUTPUT-FILE
               ASSIGN TO STSOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUT-FILE-STATUS.

           SELECT STATUS-ERROR-FILE
               ASSIGN TO STSERR
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERR-FILE-STATUS.

           SELECT STATUS-REPORT-FILE
               ASSIGN TO STSRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  STATUS-INPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 100 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  STATUS-INPUT-RECORD            PIC X(100).

       FD  STATUS-OUTPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 120 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  STATUS-OUTPUT-RECORD           PIC X(120).

       FD  STATUS-ERROR-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 180 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  STATUS-ERROR-RECORD            PIC X(180).

       FD  STATUS-REPORT-FILE
           RECORDING MODE IS FA
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  STATUS-REPORT-RECORD           PIC X(133).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PICRD300'.

       01  WS-INP-FILE-STATUS             PIC X(02).
       01  WS-OUT-FILE-STATUS             PIC X(02).
       01  WS-ERR-FILE-STATUS             PIC X(02).
       01  WS-RPT-FILE-STATUS             PIC X(02).

           COPY CPYCRD01.
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

      * DB2 HOST VARIABLES
           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HV-CARD-NUMBER                 PIC X(16).
       01  HV-CURRENT-STATUS              PIC X(02).
       01  HV-NEW-STATUS                  PIC X(02).
       01  HV-REASON-CODE                 PIC X(04).
       01  HV-REQUESTOR-ID               PIC X(10).
       01  HV-STATUS-DATE                 PIC X(10).

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
      *     AC -> CL (CLOSE)    NW -> CL (CLOSE)                      *
      *     AC -> HL (HOTLIST)                                         *
      ******************************************************************
       2300-VALIDATE-TRANSITION.
           SET WS-VALID-TRANSITION TO TRUE
           MOVE WS-STS-CARD-NUMBER TO HV-CARD-NUMBER

           EXEC SQL
               SELECT CARD_STATUS
               INTO :HV-CURRENT-STATUS
               FROM TB_CARD_MASTER
               WHERE CARD_NUMBER = :HV-CARD-NUMBER
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   CONTINUE
               WHEN 100
                   MOVE 'CARD NOT FOUND' TO WS-ERR-MESSAGE
                   SET WS-INVALID-TRANSITION TO TRUE
               WHEN OTHER
                   MOVE SQLCODE TO WS-ERR-SQLCODE
                   MOVE 'DB2 SELECT FAILED' TO WS-ERR-MESSAGE
                   MOVE 'S' TO WS-ERR-SEVERITY
                   PERFORM 8000-ERROR-HANDLER
           END-EVALUATE

           IF WS-VALID-TRANSITION
               EVALUATE TRUE
                   WHEN WS-STS-ACT-BLOCK
                       IF HV-CURRENT-STATUS = 'AC'
                           MOVE 'BL' TO HV-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT BLOCK - NOT ACTIVE'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-UNBLOCK
                       IF HV-CURRENT-STATUS = 'BL'
                           MOVE 'AC' TO HV-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT UNBLOCK - NOT BLOCKED'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-CLOSE
                       IF HV-CURRENT-STATUS = 'AC'
                          OR HV-CURRENT-STATUS = 'NW'
                          OR HV-CURRENT-STATUS = 'BL'
                           MOVE 'CL' TO HV-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT CLOSE FROM CURRENT STATUS'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
                   WHEN WS-STS-ACT-HOTLIST
                       IF HV-CURRENT-STATUS = 'AC'
                           MOVE 'BL' TO HV-NEW-STATUS
                       ELSE
                           MOVE 'CANNOT HOTLIST - NOT ACTIVE'
                               TO WS-ERR-MESSAGE
                           SET WS-INVALID-TRANSITION TO TRUE
                       END-IF
               END-EVALUATE
           END-IF
           .

      ******************************************************************
      * 2400-UPDATE-STATUS: UPDATE CARD STATUS IN DB2                 *
      ******************************************************************
       2400-UPDATE-STATUS.
           EXEC SQL
               UPDATE TB_CARD_MASTER
               SET CARD_STATUS = :HV-NEW-STATUS,
                   UPDATED_TIMESTAMP = CURRENT TIMESTAMP
               WHERE CARD_NUMBER = :HV-CARD-NUMBER
           END-EXEC

           IF SQLCODE = 0
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
               MOVE SQLCODE TO WS-ERR-SQLCODE
               MOVE 'DB2 UPDATE FAILED' TO WS-ERR-MESSAGE
               MOVE 'S' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

      ******************************************************************
      * 2500-INSERT-HISTORY: INSERT STATUS CHANGE HISTORY              *
      ******************************************************************
       2500-INSERT-HISTORY.
           MOVE WS-STS-REASON-CODE  TO HV-REASON-CODE
           MOVE WS-STS-REQUESTOR-ID TO HV-REQUESTOR-ID
           MOVE WS-FORMATTED-DATE   TO HV-STATUS-DATE

           EXEC SQL
               INSERT INTO TB_CARD_STATUS_HISTORY
               (CARD_NUMBER, PREVIOUS_STATUS, NEW_STATUS,
                REASON_CODE, REQUESTOR_ID, STATUS_DATE,
                CREATED_TIMESTAMP)
               VALUES
               (:HV-CARD-NUMBER, :HV-CURRENT-STATUS,
                :HV-NEW-STATUS, :HV-REASON-CODE,
                :HV-REQUESTOR-ID, :HV-STATUS-DATE,
                CURRENT TIMESTAMP)
           END-EXEC

           IF SQLCODE NOT = 0
               MOVE SQLCODE TO WS-ERR-SQLCODE
               MOVE 'HISTORY INSERT FAILED' TO WS-ERR-MESSAGE
               MOVE 'W' TO WS-ERR-SEVERITY
               PERFORM 8000-ERROR-HANDLER
           END-IF
           .

       2600-WRITE-OUTPUT.
           INITIALIZE STATUS-OUTPUT-RECORD
           MOVE WS-STS-CARD-NUMBER    TO STATUS-OUTPUT-RECORD(1:16)
           MOVE HV-CURRENT-STATUS     TO STATUS-OUTPUT-RECORD(17:02)
           MOVE HV-NEW-STATUS         TO STATUS-OUTPUT-RECORD(19:02)
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
           IF WS-RETURN-CODE > 0
               EXEC SQL ROLLBACK END-EXEC
               DISPLAY 'PICRD300 DB2 ROLLBACK PERFORMED'
           ELSE
               EXEC SQL COMMIT END-EXEC
           END-IF
           CLOSE STATUS-INPUT-FILE
                 STATUS-OUTPUT-FILE
                 STATUS-ERROR-FILE
                 STATUS-REPORT-FILE
           DISPLAY 'PICRD300 PROCESSING COMPLETE'
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
