       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PIONL200.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PIONL200 (LOCAL GNUCOBOL VERSION)                *
      * DESCRIPTION: CARD UPDATE - INTERACTIVE BATCH PROGRAM           *
      *              REPLACES CICS 3270 TERMINAL WITH ACCEPT/DISPLAY   *
      *              ALLOWS UPDATING ADDRESS AND DAILY LIMIT.          *
      * ORIGINAL:    CICS TRANSACTION PI02 WITH BMS MAP PISCR02       *
      * INPUT:       KEYBOARD (ACCEPT) - CARD NUMBER + FIELDS         *
      *              CARDMAST - CARD MASTER INDEXED FILE (I-O)         *
      * OUTPUT:      SCREEN (DISPLAY)                                  *
      * NOTE:        CICS SEND/RECEIVE MAP -> DISPLAY/ACCEPT           *
      *              DB2 UPDATE -> INDEXED FILE REWRITE                *
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
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PIONL200'.

       01  WS-CM-FILE-STATUS              PIC X(02).

           COPY CPYCRD01.
           COPY CPYCOM01.

      * USER INPUT AREAS
       01  WS-USER-CARD-NUM              PIC X(16).
       01  WS-USER-FIELD-CHOICE          PIC X(01).
       01  WS-USER-INPUT-VALUE           PIC X(40).
       01  WS-USER-LIMIT-INPUT           PIC X(15).
       01  WS-NEW-LIMIT                  PIC 9(09)V99.
       01  WS-CONTINUE-FLAG              PIC X(01) VALUE 'Y'.
           88  WS-USER-CONTINUE          VALUE 'Y' 'y'.
           88  WS-USER-EXIT              VALUE 'N' 'n'.
       01  WS-UPDATE-FLAG                PIC X(01) VALUE 'N'.
           88  WS-UPDATE-MADE            VALUE 'Y'.
           88  WS-NO-UPDATE              VALUE 'N'.

      * DISPLAY FORMATTING
       01  WS-EDIT-LIMIT                 PIC $$$,$$$,$$9.99.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-UPDATE-LOOP
               UNTIL WS-USER-EXIT
           PERFORM 9000-TERMINATE
           STOP RUN.

       1000-INITIALIZE.
           OPEN I-O CARD-MASTER-FILE
           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-FILE-STATUS
               STOP RUN
           END-IF

           DISPLAY '================================================'
           DISPLAY '  PLASTIC ISSUANCE - CARD UPDATE SYSTEM'
           DISPLAY '  (EQUIVALENT TO CICS TRANSACTION PI02)'
           DISPLAY '================================================'
           DISPLAY SPACES
           .

      ******************************************************************
      * 2000-UPDATE-LOOP: INTERACTIVE UPDATE CYCLE                    *
      ******************************************************************
       2000-UPDATE-LOOP.
           DISPLAY 'ENTER CARD NUMBER TO UPDATE (BLANK TO EXIT): '
           ACCEPT WS-USER-CARD-NUM

           IF WS-USER-CARD-NUM = SPACES
               SET WS-USER-EXIT TO TRUE
           ELSE
               PERFORM 2100-FETCH-CARD
           END-IF
           .

      ******************************************************************
      * 2100-FETCH-CARD: READ AND DISPLAY CURRENT CARD DATA           *
      ******************************************************************
       2100-FETCH-CARD.
           MOVE WS-USER-CARD-NUM TO CM-CARD-NUMBER
           READ CARD-MASTER-FILE
               INTO WS-CARD-MASTER-REC
               KEY IS CM-CARD-NUMBER
               INVALID KEY
                   DISPLAY '  ** CARD NOT FOUND'
                   DISPLAY SPACES
               NOT INVALID KEY
                   PERFORM 2200-SHOW-CURRENT-DATA
                   PERFORM 2300-GET-UPDATES
           END-READ
           .

      ******************************************************************
      * 2200-SHOW-CURRENT-DATA: DISPLAY CURRENT VALUES                *
      ******************************************************************
       2200-SHOW-CURRENT-DATA.
           MOVE WS-CM-DAILY-LIMIT TO WS-EDIT-LIMIT
           DISPLAY '  CURRENT CARD DATA:'
           DISPLAY '  CARD:       ' WS-CM-CARD-NUMBER
           DISPLAY '  STATUS:     ' WS-CM-CARD-STATUS
           DISPLAY '  ADDR LINE1: ' WS-CM-ADDR-LINE1
           DISPLAY '  ADDR LINE2: ' WS-CM-ADDR-LINE2
           DISPLAY '  CITY:       ' WS-CM-CITY
           DISPLAY '  STATE:      ' WS-CM-STATE
           DISPLAY '  ZIP CODE:   ' WS-CM-ZIP-CODE
           DISPLAY '  DAILY LIMIT:' WS-EDIT-LIMIT
           DISPLAY SPACES
           .

      ******************************************************************
      * 2300-GET-UPDATES: PROMPT FOR FIELD UPDATES                    *
      *   BUSINESS RULES:                                              *
      *   - Can update: address line 1, address line 2, city,         *
      *     state, zip code, daily limit                              *
      *   - Daily limit max: 99999 for debit, 25000 for prepaid      *
      ******************************************************************
       2300-GET-UPDATES.
           SET WS-NO-UPDATE TO TRUE

           DISPLAY '  UPDATE OPTIONS:'
           DISPLAY '  1 = ADDRESS LINE 1'
           DISPLAY '  2 = ADDRESS LINE 2'
           DISPLAY '  3 = CITY'
           DISPLAY '  4 = STATE'
           DISPLAY '  5 = ZIP CODE'
           DISPLAY '  6 = DAILY LIMIT'
           DISPLAY '  0 = SKIP (NO CHANGES)'
           DISPLAY '  ENTER CHOICE: '
           ACCEPT WS-USER-FIELD-CHOICE

           EVALUATE WS-USER-FIELD-CHOICE
               WHEN '1'
                   DISPLAY '  NEW ADDRESS LINE 1: '
                   ACCEPT WS-USER-INPUT-VALUE
                   MOVE WS-USER-INPUT-VALUE
                       TO WS-CM-ADDR-LINE1
                   SET WS-UPDATE-MADE TO TRUE
               WHEN '2'
                   DISPLAY '  NEW ADDRESS LINE 2: '
                   ACCEPT WS-USER-INPUT-VALUE
                   MOVE WS-USER-INPUT-VALUE
                       TO WS-CM-ADDR-LINE2
                   SET WS-UPDATE-MADE TO TRUE
               WHEN '3'
                   DISPLAY '  NEW CITY: '
                   ACCEPT WS-USER-INPUT-VALUE
                   MOVE WS-USER-INPUT-VALUE(1:25)
                       TO WS-CM-CITY
                   SET WS-UPDATE-MADE TO TRUE
               WHEN '4'
                   DISPLAY '  NEW STATE (2 CHARS): '
                   ACCEPT WS-USER-INPUT-VALUE
                   MOVE WS-USER-INPUT-VALUE(1:2)
                       TO WS-CM-STATE
                   SET WS-UPDATE-MADE TO TRUE
               WHEN '5'
                   DISPLAY '  NEW ZIP CODE: '
                   ACCEPT WS-USER-INPUT-VALUE
                   MOVE WS-USER-INPUT-VALUE(1:10)
                       TO WS-CM-ZIP-CODE
                   SET WS-UPDATE-MADE TO TRUE
               WHEN '6'
                   DISPLAY '  NEW DAILY LIMIT: '
                   ACCEPT WS-USER-LIMIT-INPUT
                   COMPUTE WS-NEW-LIMIT =
                       FUNCTION NUMVAL(WS-USER-LIMIT-INPUT)
      *            VALIDATE LIMIT BY CARD TYPE
                   IF WS-CM-TYPE-DEBIT
                       IF WS-NEW-LIMIT > 99999
                           DISPLAY '  ** LIMIT EXCEEDS MAX 99999'
                       ELSE
                           MOVE WS-NEW-LIMIT
                               TO WS-CM-DAILY-LIMIT
                           SET WS-UPDATE-MADE TO TRUE
                       END-IF
                   ELSE
                       IF WS-NEW-LIMIT > 25000
                           DISPLAY '  ** PREPAID LIMIT MAX 25000'
                       ELSE
                           MOVE WS-NEW-LIMIT
                               TO WS-CM-DAILY-LIMIT
                           SET WS-UPDATE-MADE TO TRUE
                       END-IF
                   END-IF
               WHEN '0'
                   DISPLAY '  NO CHANGES MADE'
               WHEN OTHER
                   DISPLAY '  ** INVALID CHOICE'
           END-EVALUATE

           IF WS-UPDATE-MADE
               PERFORM 2400-APPLY-UPDATE
           END-IF
           DISPLAY SPACES
           .

      ******************************************************************
      * 2400-APPLY-UPDATE: REWRITE CARD MASTER RECORD                 *
      ******************************************************************
       2400-APPLY-UPDATE.
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
               DISPLAY '  ** CARD UPDATED SUCCESSFULLY'
           ELSE
               DISPLAY '  ** UPDATE FAILED - STATUS: '
                   WS-CM-FILE-STATUS
           END-IF
           .

       9000-TERMINATE.
           CLOSE CARD-MASTER-FILE
           DISPLAY 'THANK YOU FOR USING PI UPDATE SYSTEM'
           .
