       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PIONL100.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PIONL100 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: CARD INQUIRY - INTERACTIVE BATCH PROGRAM          *
      *              REPLACES CICS 3270 TERMINAL WITH ACCEPT/DISPLAY   *
      *              READS CARD MASTER INDEXED FILE BY KEY.            *
      * ORIGINAL:    CICS TRANSACTION PI01 WITH BMS MAP PISCR01       *
      * INPUT:       KEYBOARD (ACCEPT) - CARD NUMBER                   *
      *              CARDMAST - CARD MASTER INDEXED FILE (INPUT)       *
      * OUTPUT:      SCREEN (DISPLAY)                                  *
      * NOTE:        CICS SEND MAP/RECEIVE MAP -> DISPLAY/ACCEPT       *
      *              DB2 SELECT -> INDEXED FILE READ                   *
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
               ACCESS MODE IS RANDOM
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PIONL100'.

       01  WS-CM-FILE-STATUS              PIC X(02).

           COPY CPYCRD01.
           COPY CPYCOM01.

      * USER INPUT
       01  WS-USER-INPUT                  PIC X(16).
       01  WS-CONTINUE-FLAG               PIC X(01) VALUE 'Y'.
           88  WS-USER-CONTINUE           VALUE 'Y' 'y'.
           88  WS-USER-EXIT               VALUE 'N' 'n'.

      * DISPLAY FORMATTING
       01  WS-EDIT-BALANCE                PIC $$$,$$$,$$$,$$9.99.
       01  WS-EDIT-LIMIT                  PIC $$$,$$$,$$9.99.
       01  WS-CARD-TYPE-DESC              PIC X(15).
       01  WS-STATUS-DESC                 PIC X(15).

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-INQUIRY-LOOP
               UNTIL WS-USER-EXIT
           PERFORM 9000-TERMINATE
           STOP RUN.

       1000-INITIALIZE.
           OPEN INPUT CARD-MASTER-FILE
           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-FILE-STATUS
               STOP RUN
           END-IF

           DISPLAY '================================================'
           DISPLAY '  PLASTIC ISSUANCE - CARD INQUIRY SYSTEM'
           DISPLAY '  (EQUIVALENT TO CICS TRANSACTION PI01)'
           DISPLAY '================================================'
           DISPLAY SPACES
           .

      ******************************************************************
      * 2000-INQUIRY-LOOP: INTERACTIVE CARD INQUIRY                   *
      *   SIMULATES CICS SEND MAP / RECEIVE MAP / DB2 SELECT          *
      ******************************************************************
       2000-INQUIRY-LOOP.
           DISPLAY 'ENTER CARD NUMBER (OR BLANK TO EXIT): '
           ACCEPT WS-USER-INPUT

           IF WS-USER-INPUT = SPACES
               SET WS-USER-EXIT TO TRUE
           ELSE
               PERFORM 2100-FETCH-CARD-DETAILS
           END-IF
           .

      ******************************************************************
      * 2100-FETCH-CARD-DETAILS: READ CARD FROM INDEXED FILE          *
      ******************************************************************
       2100-FETCH-CARD-DETAILS.
           MOVE WS-USER-INPUT TO CM-CARD-NUMBER
           READ CARD-MASTER-FILE
               INTO WS-CARD-MASTER-REC
               KEY IS CM-CARD-NUMBER
               INVALID KEY
                   DISPLAY '  ** CARD NOT FOUND - VERIFY NUMBER'
                   DISPLAY SPACES
               NOT INVALID KEY
                   PERFORM 2200-DISPLAY-DETAILS
           END-READ
           .

      ******************************************************************
      * 2200-DISPLAY-DETAILS: FORMAT AND DISPLAY CARD INFORMATION     *
      ******************************************************************
       2200-DISPLAY-DETAILS.
           EVALUATE WS-CM-CARD-TYPE
               WHEN 'DB'  MOVE 'DEBIT'      TO WS-CARD-TYPE-DESC
               WHEN 'PP'  MOVE 'PREPAID'    TO WS-CARD-TYPE-DESC
               WHEN OTHER MOVE 'UNKNOWN'    TO WS-CARD-TYPE-DESC
           END-EVALUATE

           EVALUATE WS-CM-CARD-STATUS
               WHEN 'NW'  MOVE 'NEW'        TO WS-STATUS-DESC
               WHEN 'AC'  MOVE 'ACTIVE'     TO WS-STATUS-DESC
               WHEN 'IN'  MOVE 'INACTIVE'   TO WS-STATUS-DESC
               WHEN 'BL'  MOVE 'BLOCKED'    TO WS-STATUS-DESC
               WHEN 'EX'  MOVE 'EXPIRED'    TO WS-STATUS-DESC
               WHEN 'CL'  MOVE 'CLOSED'     TO WS-STATUS-DESC
               WHEN OTHER MOVE 'UNKNOWN'    TO WS-STATUS-DESC
           END-EVALUATE

           MOVE WS-CM-AVAILABLE-BALANCE TO WS-EDIT-BALANCE
           MOVE WS-CM-DAILY-LIMIT       TO WS-EDIT-LIMIT

           DISPLAY '  ----------------------------------------'
           DISPLAY '  CARD NUMBER:    ' WS-CM-CARD-NUMBER
           DISPLAY '  CUSTOMER ID:    ' WS-CM-CUSTOMER-ID
           DISPLAY '  CUSTOMER NAME:  '
               WS-CM-FIRST-NAME ' ' WS-CM-LAST-NAME
           DISPLAY '  CARD TYPE:      ' WS-CARD-TYPE-DESC
           DISPLAY '  STATUS:         ' WS-STATUS-DESC
           DISPLAY '  ACCOUNT NUMBER: ' WS-CM-ACCOUNT-NUMBER
           DISPLAY '  ISSUE DATE:     ' WS-CM-ISSUE-DATE
           DISPLAY '  EXPIRY DATE:    ' WS-CM-EXPIRY-DATE
           DISPLAY '  ACTIVATION:     ' WS-CM-ACTIVATION-DATE
           DISPLAY '  LAST USED:      ' WS-CM-LAST-USED-DATE
           DISPLAY '  DAILY LIMIT:    ' WS-EDIT-LIMIT
           DISPLAY '  BALANCE:        ' WS-EDIT-BALANCE
           DISPLAY '  BRANCH:         ' WS-CM-BRANCH-CODE
           DISPLAY '  ----------------------------------------'
           DISPLAY SPACES
           .

       9000-TERMINATE.
           CLOSE CARD-MASTER-FILE
           DISPLAY 'THANK YOU FOR USING PI INQUIRY SYSTEM'
           .
