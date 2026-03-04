       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PILOAD0.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     PILOAD0                                           *
      * DESCRIPTION: LOAD INITIAL TEST DATA INTO INDEXED FILES         *
      *              EQUIVALENT TO DB2 DML/INSCRD01.sql ON MAINFRAME   *
      *              CREATES CARD MASTER INDEXED FILE WITH SAMPLE DATA *
      * OUTPUT:      CARDMAST - Card Master Indexed File (VSAM equiv)  *
      * FREQUENCY:   RUN ONCE BEFORE BATCH CYCLE                       *
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
               FILE STATUS IS WS-CM-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       WORKING-STORAGE SECTION.

       01  WS-CM-STATUS                   PIC X(02).

           COPY CPYCRD01.
           COPY CPYCOM01.

      * CARD NUMBER SEEDS
       01  WS-CARD-SEQ                    PIC 9(09) VALUE 0.
       01  WS-LOAD-COUNT                  PIC 9(04) VALUE 0.

      * LUHN WORK AREAS
       01  WS-LUHN-SUM                    PIC 9(03) VALUE 0.
       01  WS-LUHN-DIGIT                  PIC 9(02) VALUE 0.
       01  WS-LUHN-IDX                    PIC 9(02) VALUE 0.
       01  WS-LUHN-TEMP                   PIC 9(02) VALUE 0.
       01  WS-CHECK-DIGIT                 PIC 9(01) VALUE 0.
       01  WS-CARD-NUM-WK                 PIC X(16).

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-LOAD-SAMPLE-DATA
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

           OPEN OUTPUT CARD-MASTER-FILE
           IF WS-CM-STATUS NOT = '00'
               DISPLAY '*** CARD MASTER OPEN ERROR: '
                   WS-CM-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY 'PILOAD0 - CARD MASTER FILE OPENED'
           .

      ******************************************************************
      * 2000-LOAD-SAMPLE-DATA: INSERT 10 CARD RECORDS                 *
      * BUSINESS RULES DEMONSTRATED:                                   *
      *   - Cards in various statuses (NW, AC, BL, EX)                *
      *   - Both card types (DB=Debit, PP=Prepaid)                    *
      *   - Different daily limits per card type                      *
      *   - Proper Luhn-valid card numbers                            *
      *   - Expiry dates covering renewal scenarios                   *
      ******************************************************************
       2000-LOAD-SAMPLE-DATA.
      *--- CARD 1: Active Debit card, normal scenario
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000001'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000001'             TO WS-CM-CUSTOMER-ID
           MOVE 'JOHN'                   TO WS-CM-FIRST-NAME
           MOVE 'DOE'                    TO WS-CM-LAST-NAME
           MOVE '123 MAIN STREET'        TO WS-CM-ADDR-LINE1
           MOVE 'APT 4B'                 TO WS-CM-ADDR-LINE2
           MOVE 'NEW YORK'               TO WS-CM-CITY
           MOVE 'NY'                     TO WS-CM-STATE
           MOVE '10001'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2025-01-15'             TO WS-CM-ISSUE-DATE
           MOVE '2028-01-15'             TO WS-CM-EXPIRY-DATE
           MOVE '2025-01-20'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-03-01'             TO WS-CM-LAST-USED-DATE
           MOVE 05000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 12500.50                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '1234'                   TO WS-CM-PIN-OFFSET
           MOVE '789'                    TO WS-CM-CVV-VALUE
           MOVE 'NYCBR1'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 2: Active Debit card, high limit
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000002'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000002'             TO WS-CM-CUSTOMER-ID
           MOVE 'JANE'                   TO WS-CM-FIRST-NAME
           MOVE 'SMITH'                  TO WS-CM-LAST-NAME
           MOVE '456 OAK AVENUE'         TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'CHICAGO'                TO WS-CM-CITY
           MOVE 'IL'                     TO WS-CM-STATE
           MOVE '60601'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2025-02-01'             TO WS-CM-ISSUE-DATE
           MOVE '2028-02-01'             TO WS-CM-EXPIRY-DATE
           MOVE '2025-02-05'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-02-28'             TO WS-CM-LAST-USED-DATE
           MOVE 10000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 25000.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '5678'                   TO WS-CM-PIN-OFFSET
           MOVE '456'                    TO WS-CM-CVV-VALUE
           MOVE 'CHCBR2'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 3: New (not activated) Prepaid card
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'PP'                     TO WS-CM-CARD-TYPE
           MOVE '100000000003'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000003'             TO WS-CM-CUSTOMER-ID
           MOVE 'ROBERT'                 TO WS-CM-FIRST-NAME
           MOVE 'JOHNSON'               TO WS-CM-LAST-NAME
           MOVE '789 PINE ROAD'          TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'LOS ANGELES'            TO WS-CM-CITY
           MOVE 'CA'                     TO WS-CM-STATE
           MOVE '90001'                  TO WS-CM-ZIP-CODE
           MOVE 'NW'                     TO WS-CM-CARD-STATUS
           MOVE '2026-03-01'             TO WS-CM-ISSUE-DATE
           MOVE '2029-03-01'             TO WS-CM-EXPIRY-DATE
           MOVE SPACES                   TO WS-CM-ACTIVATION-DATE
           MOVE SPACES                   TO WS-CM-LAST-USED-DATE
           MOVE 02000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 01000.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE SPACES                   TO WS-CM-PIN-OFFSET
           MOVE '321'                    TO WS-CM-CVV-VALUE
           MOVE 'LABR01'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 4: Blocked Debit card (can be unblocked)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000004'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000004'             TO WS-CM-CUSTOMER-ID
           MOVE 'MARIA'                  TO WS-CM-FIRST-NAME
           MOVE 'GARCIA'                TO WS-CM-LAST-NAME
           MOVE '321 ELM BOULEVARD'      TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'HOUSTON'                TO WS-CM-CITY
           MOVE 'TX'                     TO WS-CM-STATE
           MOVE '77001'                  TO WS-CM-ZIP-CODE
           MOVE 'BL'                     TO WS-CM-CARD-STATUS
           MOVE '2024-06-15'             TO WS-CM-ISSUE-DATE
           MOVE '2027-06-15'             TO WS-CM-EXPIRY-DATE
           MOVE '2024-06-20'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-01-10'             TO WS-CM-LAST-USED-DATE
           MOVE 05000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 03200.75                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '9012'                   TO WS-CM-PIN-OFFSET
           MOVE '654'                    TO WS-CM-CVV-VALUE
           MOVE 'HOUBR3'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 5: Active Debit, EXPIRING SOON (for renewal test)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000005'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000005'             TO WS-CM-CUSTOMER-ID
           MOVE 'DAVID'                  TO WS-CM-FIRST-NAME
           MOVE 'WILSON'                TO WS-CM-LAST-NAME
           MOVE '654 CEDAR LANE'         TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'PHOENIX'                TO WS-CM-CITY
           MOVE 'AZ'                     TO WS-CM-STATE
           MOVE '85001'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2023-04-01'             TO WS-CM-ISSUE-DATE
           MOVE '2026-04-01'             TO WS-CM-EXPIRY-DATE
           MOVE '2023-04-05'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-03-02'             TO WS-CM-LAST-USED-DATE
           MOVE 04000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 08750.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '3456'                   TO WS-CM-PIN-OFFSET
           MOVE '987'                    TO WS-CM-CVV-VALUE
           MOVE 'PHXBR1'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 6: Active Prepaid, low balance
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'PP'                     TO WS-CM-CARD-TYPE
           MOVE '100000000006'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000006'             TO WS-CM-CUSTOMER-ID
           MOVE 'SARAH'                  TO WS-CM-FIRST-NAME
           MOVE 'BROWN'                 TO WS-CM-LAST-NAME
           MOVE '987 MAPLE DRIVE'        TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'PHILADELPHIA'           TO WS-CM-CITY
           MOVE 'PA'                     TO WS-CM-STATE
           MOVE '19101'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2025-06-01'             TO WS-CM-ISSUE-DATE
           MOVE '2028-06-01'             TO WS-CM-EXPIRY-DATE
           MOVE '2025-06-05'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-03-03'             TO WS-CM-LAST-USED-DATE
           MOVE 02500.00                 TO WS-CM-DAILY-LIMIT
           MOVE 00150.25                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '7890'                   TO WS-CM-PIN-OFFSET
           MOVE '123'                    TO WS-CM-CVV-VALUE
           MOVE 'PHLBR2'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 7: Active Debit, EXPIRING SOON (renewal candidate 2)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000007'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000007'             TO WS-CM-CUSTOMER-ID
           MOVE 'MICHAEL'                TO WS-CM-FIRST-NAME
           MOVE 'JONES'                 TO WS-CM-LAST-NAME
           MOVE '147 BIRCH WAY'          TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'SAN ANTONIO'            TO WS-CM-CITY
           MOVE 'TX'                     TO WS-CM-STATE
           MOVE '78201'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2023-04-15'             TO WS-CM-ISSUE-DATE
           MOVE '2026-04-15'             TO WS-CM-EXPIRY-DATE
           MOVE '2023-04-20'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-03-01'             TO WS-CM-LAST-USED-DATE
           MOVE 05000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 15000.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '2345'                   TO WS-CM-PIN-OFFSET
           MOVE '567'                    TO WS-CM-CVV-VALUE
           MOVE 'SATBR1'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 8: Expired card (should NOT be renewed - already EX)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000008'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000008'             TO WS-CM-CUSTOMER-ID
           MOVE 'JENNIFER'               TO WS-CM-FIRST-NAME
           MOVE 'DAVIS'                 TO WS-CM-LAST-NAME
           MOVE '258 WALNUT COURT'       TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'SAN DIEGO'              TO WS-CM-CITY
           MOVE 'CA'                     TO WS-CM-STATE
           MOVE '92101'                  TO WS-CM-ZIP-CODE
           MOVE 'EX'                     TO WS-CM-CARD-STATUS
           MOVE '2022-01-01'             TO WS-CM-ISSUE-DATE
           MOVE '2025-01-01'             TO WS-CM-EXPIRY-DATE
           MOVE '2022-01-05'             TO WS-CM-ACTIVATION-DATE
           MOVE '2024-12-30'             TO WS-CM-LAST-USED-DATE
           MOVE 03500.00                 TO WS-CM-DAILY-LIMIT
           MOVE 00000.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '6789'                   TO WS-CM-PIN-OFFSET
           MOVE '234'                    TO WS-CM-CVV-VALUE
           MOVE 'SDBR01'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 9: Active Prepaid (for status change tests)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'PP'                     TO WS-CM-CARD-TYPE
           MOVE '100000000009'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000009'             TO WS-CM-CUSTOMER-ID
           MOVE 'WILLIAM'                TO WS-CM-FIRST-NAME
           MOVE 'MILLER'                TO WS-CM-LAST-NAME
           MOVE '369 SPRUCE PLACE'       TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'DALLAS'                 TO WS-CM-CITY
           MOVE 'TX'                     TO WS-CM-STATE
           MOVE '75201'                  TO WS-CM-ZIP-CODE
           MOVE 'AC'                     TO WS-CM-CARD-STATUS
           MOVE '2025-08-01'             TO WS-CM-ISSUE-DATE
           MOVE '2028-08-01'             TO WS-CM-EXPIRY-DATE
           MOVE '2025-08-03'             TO WS-CM-ACTIVATION-DATE
           MOVE '2026-02-15'             TO WS-CM-LAST-USED-DATE
           MOVE 01500.00                 TO WS-CM-DAILY-LIMIT
           MOVE 00500.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE '0123'                   TO WS-CM-PIN-OFFSET
           MOVE '890'                    TO WS-CM-CVV-VALUE
           MOVE 'DALBR2'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

      *--- CARD 10: New Debit (for activation test)
           PERFORM 2100-GEN-CARD-NUMBER
           INITIALIZE WS-CARD-MASTER-REC
           MOVE WS-CARD-NUM-WK          TO WS-CM-CARD-NUMBER
           MOVE 'DB'                     TO WS-CM-CARD-TYPE
           MOVE '100000000010'           TO WS-CM-ACCOUNT-NUMBER
           MOVE 'CUST000010'             TO WS-CM-CUSTOMER-ID
           MOVE 'ELIZABETH'              TO WS-CM-FIRST-NAME
           MOVE 'TAYLOR'                TO WS-CM-LAST-NAME
           MOVE '741 ASH STREET'         TO WS-CM-ADDR-LINE1
           MOVE SPACES                   TO WS-CM-ADDR-LINE2
           MOVE 'SAN JOSE'               TO WS-CM-CITY
           MOVE 'CA'                     TO WS-CM-STATE
           MOVE '95101'                  TO WS-CM-ZIP-CODE
           MOVE 'NW'                     TO WS-CM-CARD-STATUS
           MOVE '2026-03-04'             TO WS-CM-ISSUE-DATE
           MOVE '2029-03-04'             TO WS-CM-EXPIRY-DATE
           MOVE SPACES                   TO WS-CM-ACTIVATION-DATE
           MOVE SPACES                   TO WS-CM-LAST-USED-DATE
           MOVE 05000.00                 TO WS-CM-DAILY-LIMIT
           MOVE 00000.00                 TO WS-CM-AVAILABLE-BALANCE
           MOVE SPACES                   TO WS-CM-PIN-OFFSET
           MOVE '567'                    TO WS-CM-CVV-VALUE
           MOVE 'SJBR01'                 TO WS-CM-BRANCH-CODE
           MOVE WS-FORMATTED-DATE        TO WS-CM-CREATED-TIMESTAMP
           PERFORM 2900-WRITE-CARD

           DISPLAY 'PILOAD0 - LOADED ' WS-LOAD-COUNT ' CARDS'
           .

      ******************************************************************
      * 2100-GEN-CARD-NUMBER: GENERATE LUHN-VALID 16-DIGIT NUMBER     *
      ******************************************************************
       2100-GEN-CARD-NUMBER.
           ADD 1 TO WS-CARD-SEQ
           INITIALIZE WS-CARD-NUM-WK
           STRING '400012'
                  WS-CARD-SEQ
               DELIMITED BY SIZE
               INTO WS-CARD-NUM-WK
           END-STRING
      *    COMPUTE LUHN CHECK DIGIT
           MOVE 0 TO WS-LUHN-SUM
           PERFORM VARYING WS-LUHN-IDX FROM 1 BY 1
               UNTIL WS-LUHN-IDX > 15
               COMPUTE WS-LUHN-DIGIT =
                   FUNCTION ORD(
                       WS-CARD-NUM-WK(WS-LUHN-IDX:1)) - 48
               IF FUNCTION MOD(WS-LUHN-IDX, 2) = 1
                   COMPUTE WS-LUHN-TEMP = WS-LUHN-DIGIT * 2
                   IF WS-LUHN-TEMP > 9
                       SUBTRACT 9 FROM WS-LUHN-TEMP
                   END-IF
                   ADD WS-LUHN-TEMP TO WS-LUHN-SUM
               ELSE
                   ADD WS-LUHN-DIGIT TO WS-LUHN-SUM
               END-IF
           END-PERFORM
           COMPUTE WS-CHECK-DIGIT =
               FUNCTION MOD(
                   (10 - FUNCTION MOD(WS-LUHN-SUM, 10)), 10)
           MOVE WS-CHECK-DIGIT TO WS-CARD-NUM-WK(16:1)
           .

      ******************************************************************
      * 2900-WRITE-CARD: WRITE CARD RECORD TO INDEXED FILE            *
      ******************************************************************
       2900-WRITE-CARD.
           MOVE WS-CM-CARD-NUMBER TO CM-CARD-NUMBER
           MOVE WS-CARD-MASTER-REC TO CARD-MASTER-RECORD
           WRITE CARD-MASTER-RECORD
           IF WS-CM-STATUS = '00'
               ADD 1 TO WS-LOAD-COUNT
               DISPLAY '  LOADED: ' WS-CM-CARD-NUMBER
                   ' STATUS=' WS-CM-CARD-STATUS
                   ' TYPE=' WS-CM-CARD-TYPE
                   ' LIMIT=' WS-CM-DAILY-LIMIT
           ELSE
               DISPLAY '*** WRITE ERROR: ' WS-CM-STATUS
                   ' CARD=' WS-CM-CARD-NUMBER
           END-IF
           .

       9000-TERMINATE.
           CLOSE CARD-MASTER-FILE
           DISPLAY 'PILOAD0 COMPLETE - ' WS-LOAD-COUNT
               ' RECORDS LOADED'
           .
