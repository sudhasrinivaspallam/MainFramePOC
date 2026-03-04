       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PIONL100.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PIONL100                                          *
      * DESCRIPTION: CICS ONLINE - CARD INQUIRY PROGRAM               *
      *              PROVIDES REAL-TIME CARD STATUS AND DETAILS        *
      *              VIA CICS 3270 TERMINAL INTERFACE.                 *
      * TRANSACTION: PI01                                               *
      * MAP/MAPSET:  PISCR01 / PIMAPS                                  *
      * DATABASE:    TB_CARD_MASTER (SELECT)                           *
      *              TB_CARD_TRANSACTION (SELECT)                      *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PIONL100'.
       01  WS-TRANSACTION-ID              PIC X(04) VALUE 'PI01'.

      * COMMUNICATION AREA
       01  WS-COMMAREA.
           05  WS-CA-ACTION               PIC X(02).
               88  WS-CA-FIRST-TIME       VALUE '  '.
               88  WS-CA-INQUIRY          VALUE 'IQ'.
               88  WS-CA-EXIT             VALUE 'EX'.
           05  WS-CA-CARD-NUMBER          PIC X(16).
           05  WS-CA-MSG                  PIC X(60).

       01  WS-COMMAREA-LENGTH             PIC S9(04) COMP VALUE 78.

      * SCREEN FIELD ATTRIBUTES
       01  DFHBMSCA                       COPY DFHBMSCA.

      * BMS MAP AREA
       01  PISCR01I.
           05  FILLER                     PIC X(12).
           05  CARDNOL                    PIC S9(04) COMP.
           05  CARDNOF                    PIC X(01).
           05  FILLER REDEFINES CARDNOF.
               10  CARDNOA               PIC X(01).
           05  CARDNOI                    PIC X(16).
           05  CUSTIDL                    PIC S9(04) COMP.
           05  CUSTIDF                    PIC X(01).
           05  CUSTIDI                    PIC X(10).
           05  CUSTNAML                   PIC S9(04) COMP.
           05  CUSTNAMF                   PIC X(01).
           05  CUSTNAMI                   PIC X(50).
           05  CARDTYPL                   PIC S9(04) COMP.
           05  CARDTYPF                   PIC X(01).
           05  CARDTYPI                   PIC X(15).
           05  CARDSTSL                   PIC S9(04) COMP.
           05  CARDSTSF                   PIC X(01).
           05  CARDSTSI                   PIC X(15).
           05  ISSUDTL                    PIC S9(04) COMP.
           05  ISSUDTF                    PIC X(01).
           05  ISSUDTI                    PIC X(10).
           05  EXPDTL                     PIC S9(04) COMP.
           05  EXPDTF                     PIC X(01).
           05  EXPDTI                     PIC X(10).
           05  BALANCL                    PIC S9(04) COMP.
           05  BALANCF                    PIC X(01).
           05  BALANCI                    PIC X(15).
           05  DAYLMTL                    PIC S9(04) COMP.
           05  DAYLMTF                    PIC X(01).
           05  DAYLMTI                    PIC X(15).
           05  MSGL                       PIC S9(04) COMP.
           05  MSGF                       PIC X(01).
           05  MSGI                       PIC X(60).

       01  PISCR01O REDEFINES PISCR01I.
           05  FILLER                     PIC X(12).
           05  FILLER                     PIC X(03).
           05  CARDNOO                    PIC X(16).
           05  FILLER                     PIC X(03).
           05  CUSTIDO                    PIC X(10).
           05  FILLER                     PIC X(03).
           05  CUSTNAMO                   PIC X(50).
           05  FILLER                     PIC X(03).
           05  CARDTYPO                   PIC X(15).
           05  FILLER                     PIC X(03).
           05  CARDSTSO                   PIC X(15).
           05  FILLER                     PIC X(03).
           05  ISSUDTO                    PIC X(10).
           05  FILLER                     PIC X(03).
           05  EXPDTO                     PIC X(10).
           05  FILLER                     PIC X(03).
           05  BALANCO                    PIC X(15).
           05  FILLER                     PIC X(03).
           05  DAYLMTO                    PIC X(15).
           05  FILLER                     PIC X(03).
           05  MSGO                       PIC X(60).

      * DB2 HOST VARIABLES
           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HV-CARD-NUMBER                 PIC X(16).
       01  HV-CARD-TYPE                   PIC X(02).
       01  HV-ACCOUNT-NUMBER              PIC X(12).
       01  HV-CUSTOMER-ID                 PIC X(10).
       01  HV-FIRST-NAME                  PIC X(25).
       01  HV-LAST-NAME                   PIC X(25).
       01  HV-CARD-STATUS                 PIC X(02).
       01  HV-ISSUE-DATE                  PIC X(10).
       01  HV-EXPIRY-DATE                 PIC X(10).
       01  HV-DAILY-LIMIT                 PIC S9(09)V99 COMP-3.
       01  HV-AVAILABLE-BALANCE           PIC S9(11)V99 COMP-3.

       01  WS-EDIT-BALANCE                PIC $$$,$$$,$$$,$$9.99.
       01  WS-EDIT-LIMIT                  PIC $$$,$$$,$$9.99.

       01  WS-RESP-CODE                   PIC S9(08) COMP.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           EVALUATE TRUE
               WHEN WS-CA-FIRST-TIME
                   PERFORM 1000-SEND-EMPTY-MAP
               WHEN WS-CA-INQUIRY
                   PERFORM 2000-PROCESS-INQUIRY
               WHEN WS-CA-EXIT
                   EXEC CICS SEND TEXT
                       FROM('THANK YOU FOR USING PI SYSTEM')
                       LENGTH(30)
                       ERASE
                   END-EXEC
                   EXEC CICS RETURN END-EXEC
               WHEN OTHER
                   PERFORM 1000-SEND-EMPTY-MAP
           END-EVALUATE

           EXEC CICS RETURN
               TRANSID(WS-TRANSACTION-ID)
               COMMAREA(WS-COMMAREA)
               LENGTH(WS-COMMAREA-LENGTH)
           END-EXEC
           .

      ******************************************************************
      * 1000-SEND-EMPTY-MAP: DISPLAY EMPTY INQUIRY SCREEN             *
      ******************************************************************
       1000-SEND-EMPTY-MAP.
           INITIALIZE PISCR01O
           MOVE 'ENTER CARD NUMBER AND PRESS ENTER' TO MSGO

           EXEC CICS SEND
               MAP('PISCR01')
               MAPSET('PIMAPS')
               FROM(PISCR01O)
               ERASE
           END-EXEC

           MOVE 'IQ' TO WS-CA-ACTION
           .

      ******************************************************************
      * 2000-PROCESS-INQUIRY: RECEIVE MAP AND QUERY DB2               *
      ******************************************************************
       2000-PROCESS-INQUIRY.
           EXEC CICS RECEIVE
               MAP('PISCR01')
               MAPSET('PIMAPS')
               INTO(PISCR01I)
               RESP(WS-RESP-CODE)
           END-EXEC

           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
               MOVE 'MAP RECEIVE ERROR' TO MSGO
               PERFORM 3000-SEND-MAP-DATAONLY
           ELSE
               IF CARDNOL = 0 OR CARDNOI = SPACES
                   MOVE 'PLEASE ENTER A CARD NUMBER' TO MSGO
                   PERFORM 3000-SEND-MAP-DATAONLY
               ELSE
                   MOVE CARDNOI TO HV-CARD-NUMBER
                   PERFORM 2100-FETCH-CARD-DETAILS
               END-IF
           END-IF
           .

      ******************************************************************
      * 2100-FETCH-CARD-DETAILS: QUERY DB2 FOR CARD INFORMATION       *
      ******************************************************************
       2100-FETCH-CARD-DETAILS.
           EXEC SQL
               SELECT CARD_TYPE, ACCOUNT_NUMBER, CUSTOMER_ID,
                      FIRST_NAME, LAST_NAME, CARD_STATUS,
                      ISSUE_DATE, EXPIRY_DATE,
                      DAILY_LIMIT, AVAILABLE_BALANCE
               INTO :HV-CARD-TYPE, :HV-ACCOUNT-NUMBER,
                    :HV-CUSTOMER-ID, :HV-FIRST-NAME,
                    :HV-LAST-NAME, :HV-CARD-STATUS,
                    :HV-ISSUE-DATE, :HV-EXPIRY-DATE,
                    :HV-DAILY-LIMIT, :HV-AVAILABLE-BALANCE
               FROM TB_CARD_MASTER
               WHERE CARD_NUMBER = :HV-CARD-NUMBER
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 2200-POPULATE-MAP
                   MOVE 'CARD DETAILS RETRIEVED SUCCESSFULLY'
                       TO MSGO
                   PERFORM 3000-SEND-MAP-DATAONLY
               WHEN 100
                   MOVE 'CARD NOT FOUND - PLEASE VERIFY NUMBER'
                       TO MSGO
                   PERFORM 3000-SEND-MAP-DATAONLY
               WHEN OTHER
                   MOVE 'DATABASE ERROR - CONTACT SUPPORT'
                       TO MSGO
                   PERFORM 3000-SEND-MAP-DATAONLY
           END-EVALUATE
           .

      ******************************************************************
      * 2200-POPULATE-MAP: FILL SCREEN WITH CARD DETAILS              *
      ******************************************************************
       2200-POPULATE-MAP.
           MOVE HV-CARD-NUMBER       TO CARDNOO
           MOVE HV-CUSTOMER-ID       TO CUSTIDO

           STRING HV-FIRST-NAME DELIMITED BY '  '
                  ' ' DELIMITED BY SIZE
                  HV-LAST-NAME DELIMITED BY '  '
               INTO CUSTNAMO
           END-STRING

           EVALUATE HV-CARD-TYPE
               WHEN 'DB'  MOVE 'DEBIT'      TO CARDTYPO
               WHEN 'PP'  MOVE 'PREPAID'    TO CARDTYPO
               WHEN OTHER MOVE 'UNKNOWN'    TO CARDTYPO
           END-EVALUATE

           EVALUATE HV-CARD-STATUS
               WHEN 'NW'  MOVE 'NEW'        TO CARDSTSO
               WHEN 'AC'  MOVE 'ACTIVE'     TO CARDSTSO
               WHEN 'IN'  MOVE 'INACTIVE'   TO CARDSTSO
               WHEN 'BL'  MOVE 'BLOCKED'    TO CARDSTSO
               WHEN 'EX'  MOVE 'EXPIRED'    TO CARDSTSO
               WHEN 'CL'  MOVE 'CLOSED'     TO CARDSTSO
               WHEN OTHER MOVE 'UNKNOWN'    TO CARDSTSO
           END-EVALUATE

           MOVE HV-ISSUE-DATE        TO ISSUDTO
           MOVE HV-EXPIRY-DATE       TO EXPDTO

           MOVE HV-AVAILABLE-BALANCE TO WS-EDIT-BALANCE
           MOVE WS-EDIT-BALANCE      TO BALANCO

           MOVE HV-DAILY-LIMIT       TO WS-EDIT-LIMIT
           MOVE WS-EDIT-LIMIT        TO DAYLMTO
           .

      ******************************************************************
      * 3000-SEND-MAP-DATAONLY: SEND MAP WITH DATA ONLY               *
      ******************************************************************
       3000-SEND-MAP-DATAONLY.
           EXEC CICS SEND
               MAP('PISCR01')
               MAPSET('PIMAPS')
               FROM(PISCR01O)
               DATAONLY
           END-EXEC
           .
