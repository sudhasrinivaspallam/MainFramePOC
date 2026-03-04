       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PIONL200.
       AUTHOR.        MAINFRAME POC TEAM.
       DATE-WRITTEN.  2026-03-04.
      ******************************************************************
      * PROGRAM:     PIONL200                                          *
      * DESCRIPTION: CICS ONLINE - CARD UPDATE PROGRAM                *
      *              ALLOWS AUTHORIZED USERS TO UPDATE CARD DETAILS    *
      *              SUCH AS DAILY LIMIT, ADDRESS, AND STATUS.         *
      * TRANSACTION: PI02                                               *
      * MAP/MAPSET:  PISCR02 / PIMAPS                                  *
      * DATABASE:    TB_CARD_MASTER (SELECT, UPDATE)                   *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-PROGRAM-ID                  PIC X(08) VALUE 'PIONL200'.
       01  WS-TRANSACTION-ID              PIC X(04) VALUE 'PI02'.

       01  WS-COMMAREA.
           05  WS-CA-ACTION               PIC X(02).
               88  WS-CA-FIRST-TIME       VALUE '  '.
               88  WS-CA-FETCH            VALUE 'FT'.
               88  WS-CA-UPDATE           VALUE 'UP'.
               88  WS-CA-CONFIRM          VALUE 'CF'.
               88  WS-CA-EXIT             VALUE 'EX'.
           05  WS-CA-CARD-NUMBER          PIC X(16).
           05  WS-CA-MSG                  PIC X(60).

       01  WS-COMMAREA-LENGTH             PIC S9(04) COMP VALUE 78.

      * BMS MAP AREA
       01  PISCR02I.
           05  FILLER                     PIC X(12).
           05  CARDNOL                    PIC S9(04) COMP.
           05  CARDNOF                    PIC X(01).
           05  CARDNOI                    PIC X(16).
           05  ADDRL1L                    PIC S9(04) COMP.
           05  ADDRL1F                    PIC X(01).
           05  ADDRL1I                    PIC X(40).
           05  ADDRL2L                    PIC S9(04) COMP.
           05  ADDRL2F                    PIC X(01).
           05  ADDRL2I                    PIC X(40).
           05  CITYL                      PIC S9(04) COMP.
           05  CITYF                      PIC X(01).
           05  CITYI                      PIC X(25).
           05  STATEL                     PIC S9(04) COMP.
           05  STATEF                     PIC X(01).
           05  STATEI                     PIC X(02).
           05  ZIPL                       PIC S9(04) COMP.
           05  ZIPF                       PIC X(01).
           05  ZIPI                       PIC X(10).
           05  DAYLMTL                    PIC S9(04) COMP.
           05  DAYLMTF                    PIC X(01).
           05  DAYLMTI                    PIC X(15).
           05  MSGL                       PIC S9(04) COMP.
           05  MSGF                       PIC X(01).
           05  MSGI                       PIC X(60).

       01  PISCR02O REDEFINES PISCR02I.
           05  FILLER                     PIC X(12).
           05  FILLER                     PIC X(03).
           05  CARDNOO                    PIC X(16).
           05  FILLER                     PIC X(03).
           05  ADDRL1O                    PIC X(40).
           05  FILLER                     PIC X(03).
           05  ADDRL2O                    PIC X(40).
           05  FILLER                     PIC X(03).
           05  CITYO                      PIC X(25).
           05  FILLER                     PIC X(03).
           05  STATEO                     PIC X(02).
           05  FILLER                     PIC X(03).
           05  ZIPO                       PIC X(10).
           05  FILLER                     PIC X(03).
           05  DAYLMTO                    PIC X(15).
           05  FILLER                     PIC X(03).
           05  MSGO                       PIC X(60).

           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HV-CARD-NUMBER                 PIC X(16).
       01  HV-ADDR-LINE1                  PIC X(40).
       01  HV-ADDR-LINE2                  PIC X(40).
       01  HV-CITY                        PIC X(25).
       01  HV-STATE                       PIC X(02).
       01  HV-ZIP-CODE                    PIC X(10).
       01  HV-DAILY-LIMIT                 PIC S9(09)V99 COMP-3.
       01  HV-CARD-STATUS                 PIC X(02).

       01  WS-RESP-CODE                   PIC S9(08) COMP.
       01  WS-NUM-DAILY-LIMIT             PIC S9(09)V99.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           EVALUATE TRUE
               WHEN WS-CA-FIRST-TIME
                   PERFORM 1000-SEND-EMPTY-MAP
                   MOVE 'FT' TO WS-CA-ACTION
               WHEN WS-CA-FETCH
                   PERFORM 2000-FETCH-CARD
                   MOVE 'UP' TO WS-CA-ACTION
               WHEN WS-CA-UPDATE
                   PERFORM 3000-PROCESS-UPDATE
               WHEN WS-CA-EXIT
                   EXEC CICS RETURN END-EXEC
               WHEN OTHER
                   PERFORM 1000-SEND-EMPTY-MAP
                   MOVE 'FT' TO WS-CA-ACTION
           END-EVALUATE

           EXEC CICS RETURN
               TRANSID(WS-TRANSACTION-ID)
               COMMAREA(WS-COMMAREA)
               LENGTH(WS-COMMAREA-LENGTH)
           END-EXEC
           .

       1000-SEND-EMPTY-MAP.
           INITIALIZE PISCR02O
           MOVE 'ENTER CARD NUMBER TO UPDATE' TO MSGO

           EXEC CICS SEND
               MAP('PISCR02')
               MAPSET('PIMAPS')
               FROM(PISCR02O)
               ERASE
           END-EXEC
           .

       2000-FETCH-CARD.
           EXEC CICS RECEIVE
               MAP('PISCR02')
               MAPSET('PIMAPS')
               INTO(PISCR02I)
               RESP(WS-RESP-CODE)
           END-EXEC

           IF CARDNOL = 0
               MOVE 'PLEASE ENTER A CARD NUMBER' TO MSGO
               PERFORM 4000-SEND-MAP-DATA
           ELSE
               MOVE CARDNOI TO HV-CARD-NUMBER
               MOVE CARDNOI TO WS-CA-CARD-NUMBER

               EXEC SQL
                   SELECT ADDR_LINE1, ADDR_LINE2, CITY,
                          STATE, ZIP_CODE, DAILY_LIMIT,
                          CARD_STATUS
                   INTO :HV-ADDR-LINE1, :HV-ADDR-LINE2,
                        :HV-CITY, :HV-STATE, :HV-ZIP-CODE,
                        :HV-DAILY-LIMIT, :HV-CARD-STATUS
                   FROM TB_CARD_MASTER
                   WHERE CARD_NUMBER = :HV-CARD-NUMBER
               END-EXEC

               IF SQLCODE = 0
                   MOVE HV-ADDR-LINE1 TO ADDRL1O
                   MOVE HV-ADDR-LINE2 TO ADDRL2O
                   MOVE HV-CITY       TO CITYO
                   MOVE HV-STATE      TO STATEO
                   MOVE HV-ZIP-CODE   TO ZIPO
                   MOVE HV-DAILY-LIMIT TO WS-NUM-DAILY-LIMIT
                   MOVE WS-NUM-DAILY-LIMIT TO DAYLMTO
                   MOVE 'MODIFY FIELDS AND PRESS ENTER'
                       TO MSGO
                   PERFORM 4000-SEND-MAP-DATA
               ELSE
                   MOVE 'CARD NOT FOUND' TO MSGO
                   PERFORM 4000-SEND-MAP-DATA
                   MOVE 'FT' TO WS-CA-ACTION
               END-IF
           END-IF
           .

       3000-PROCESS-UPDATE.
           EXEC CICS RECEIVE
               MAP('PISCR02')
               MAPSET('PIMAPS')
               INTO(PISCR02I)
               RESP(WS-RESP-CODE)
           END-EXEC

           MOVE WS-CA-CARD-NUMBER TO HV-CARD-NUMBER
           MOVE ADDRL1I           TO HV-ADDR-LINE1
           MOVE ADDRL2I           TO HV-ADDR-LINE2
           MOVE CITYI             TO HV-CITY
           MOVE STATEI            TO HV-STATE
           MOVE ZIPI              TO HV-ZIP-CODE

           EXEC SQL
               UPDATE TB_CARD_MASTER
               SET ADDR_LINE1 = :HV-ADDR-LINE1,
                   ADDR_LINE2 = :HV-ADDR-LINE2,
                   CITY = :HV-CITY,
                   STATE = :HV-STATE,
                   ZIP_CODE = :HV-ZIP-CODE,
                   UPDATED_TIMESTAMP = CURRENT TIMESTAMP
               WHERE CARD_NUMBER = :HV-CARD-NUMBER
           END-EXEC

           IF SQLCODE = 0
               EXEC SQL COMMIT END-EXEC
               MOVE 'CARD UPDATED SUCCESSFULLY' TO MSGO
           ELSE
               EXEC SQL ROLLBACK END-EXEC
               MOVE 'UPDATE FAILED - CONTACT SUPPORT' TO MSGO
           END-IF

           PERFORM 4000-SEND-MAP-DATA
           MOVE 'FT' TO WS-CA-ACTION
           .

       4000-SEND-MAP-DATA.
           EXEC CICS SEND
               MAP('PISCR02')
               MAPSET('PIMAPS')
               FROM(PISCR02O)
               DATAONLY
           END-EXEC
           .
