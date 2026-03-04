       IDENTIFICATION DIVISION.
       PROGRAM-ID.    GENDATA.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     GENDATA                                           *
      * DESCRIPTION: GENERATE ALL TEST INPUT DATA FILES                *
      *              READS CARDMAST TO GET ACTUAL CARD NUMBERS,        *
      *              THEN CREATES INPUT FILES FOR ALL BATCH PROGRAMS.  *
      * INPUT:       DATA/CARDMAST.dat (indexed, from PILOAD0)        *
      * OUTPUT:      DATA/CARDINP.dat  - Card issuance input          *
      *              DATA/ACTVINP.dat  - Activation input              *
      *              DATA/STSINP.dat   - Status change input           *
      *              DATA/TXNINP.dat   - Settlement TXN input          *
      *              DATA/ACQFILE.dat  - Acquirer confirmations        *
      *              DATA/INQINP.dat   - Inquiry stdin input           *
      *              DATA/UPDINP.dat   - Update stdin input            *
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
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CM-CARD-NUMBER
               FILE STATUS IS WS-CM-FILE-STATUS.

           SELECT CARD-INPUT-FILE
               ASSIGN TO "DATA/CARDINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-CI-FILE-STATUS.

           SELECT ACTV-INPUT-FILE
               ASSIGN TO "DATA/ACTVINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-AI-FILE-STATUS.

           SELECT STS-INPUT-FILE
               ASSIGN TO "DATA/STSINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SI-FILE-STATUS.

           SELECT TXN-INPUT-FILE
               ASSIGN TO "DATA/TXNINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-TI-FILE-STATUS.

           SELECT ACQ-INPUT-FILE
               ASSIGN TO "DATA/ACQFILE.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-AQ-FILE-STATUS.

           SELECT INQ-INPUT-FILE
               ASSIGN TO "DATA/INQINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-IQ-FILE-STATUS.

           SELECT UPD-INPUT-FILE
               ASSIGN TO "DATA/UPDINP.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-UP-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  CARD-MASTER-FILE.
       01  CARD-MASTER-RECORD.
           05  CM-CARD-NUMBER             PIC X(16).
           05  CM-DATA                    PIC X(384).

       FD  CARD-INPUT-FILE
           RECORD CONTAINS 300 CHARACTERS.
       01  CARD-INPUT-RECORD              PIC X(300).

       FD  ACTV-INPUT-FILE
           RECORD CONTAINS 80 CHARACTERS.
       01  ACTV-INPUT-RECORD              PIC X(80).

       FD  STS-INPUT-FILE
           RECORD CONTAINS 100 CHARACTERS.
       01  STS-INPUT-RECORD               PIC X(100).

       FD  TXN-INPUT-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  TXN-INPUT-RECORD               PIC X(250).

       FD  ACQ-INPUT-FILE
           RECORD CONTAINS 150 CHARACTERS.
       01  ACQ-INPUT-RECORD               PIC X(150).

       FD  INQ-INPUT-FILE
           RECORD CONTAINS 80 CHARACTERS.
       01  INQ-INPUT-RECORD               PIC X(80).

       FD  UPD-INPUT-FILE
           RECORD CONTAINS 80 CHARACTERS.
       01  UPD-INPUT-RECORD               PIC X(80).

       WORKING-STORAGE SECTION.

           COPY CPYCRD01.
           COPY CPYCOM01.

       01  WS-CM-FILE-STATUS              PIC X(02).
       01  WS-CI-FILE-STATUS              PIC X(02).
       01  WS-AI-FILE-STATUS              PIC X(02).
       01  WS-SI-FILE-STATUS              PIC X(02).
       01  WS-TI-FILE-STATUS              PIC X(02).
       01  WS-AQ-FILE-STATUS              PIC X(02).
       01  WS-IQ-FILE-STATUS              PIC X(02).
       01  WS-UP-FILE-STATUS              PIC X(02).

      * CARD NUMBER TABLE - LOADED FROM CARDMAST
       01  WS-CARD-TABLE.
           05  WS-CARD-ENTRY OCCURS 20 TIMES.
               10  WS-CT-CARD-NUM        PIC X(16).
               10  WS-CT-STATUS          PIC X(02).
               10  WS-CT-CUST-ID         PIC X(10).
               10  WS-CT-TYPE            PIC X(02).
               10  WS-CT-ACCT-NUM        PIC X(12).
       01  WS-CARD-COUNT                  PIC 9(02) VALUE 0.
       01  WS-CARD-IDX                    PIC 9(02).

      * CARD ISSUANCE INPUT RECORD (300 bytes)
       01  WS-CI-REC.
           05  WS-CI-REQUEST-TYPE         PIC X(02).
           05  WS-CI-ACCOUNT-NUMBER       PIC X(12).
           05  WS-CI-CUSTOMER-ID          PIC X(10).
           05  WS-CI-FIRST-NAME           PIC X(25).
           05  WS-CI-LAST-NAME            PIC X(25).
           05  WS-CI-ADDR-LINE1           PIC X(40).
           05  WS-CI-ADDR-LINE2           PIC X(40).
           05  WS-CI-CITY                 PIC X(25).
           05  WS-CI-STATE                PIC X(02).
           05  WS-CI-ZIP-CODE             PIC X(10).
           05  WS-CI-CARD-TYPE            PIC X(02).
           05  WS-CI-DAILY-LIMIT          PIC 9(09)V99.
           05  WS-CI-BRANCH-CODE          PIC X(06).
           05  FILLER                     PIC X(90).

      * ACTIVATION INPUT RECORD (80 bytes)
       01  WS-AI-REC.
           05  WS-AI-CARD-NUMBER          PIC X(16).
           05  WS-AI-CUSTOMER-ID          PIC X(10).
           05  WS-AI-PIN-OFFSET           PIC X(04).
           05  WS-AI-CHANNEL              PIC X(02).
           05  FILLER                     PIC X(48).

      * STATUS INPUT RECORD (100 bytes)
       01  WS-SI-REC.
           05  WS-SI-CARD-NUMBER          PIC X(16).
           05  WS-SI-ACTION-CODE          PIC X(02).
           05  WS-SI-REASON-CODE          PIC X(04).
           05  WS-SI-REQUESTOR-ID         PIC X(10).
           05  WS-SI-CHANNEL              PIC X(02).
           05  FILLER                     PIC X(66).

      * TXN INPUT RECORD (250 bytes)
       01  WS-TI-REC.
           05  WS-TI-TXN-ID              PIC X(20).
           05  WS-TI-CARD-NUMBER          PIC X(16).
           05  WS-TI-ACCOUNT-NUMBER       PIC X(12).
           05  WS-TI-TXN-TYPE             PIC X(02).
           05  WS-TI-TXN-AMOUNT           PIC 9(11)V99.
           05  WS-TI-TXN-DATE             PIC X(10).
           05  WS-TI-MERCHANT-ID           PIC X(15).
           05  WS-TI-MERCHANT-NAME         PIC X(40).
           05  WS-TI-ACQUIRER-ID           PIC X(11).
           05  WS-TI-ISSUER-ID            PIC X(11).
           05  WS-TI-NETWORK-ID            PIC X(04).
           05  WS-TI-INTERCHANGE-FEE       PIC 9(07)V99.
           05  FILLER                      PIC X(87).

      * ACQUIRER INPUT RECORD (150 bytes)
       01  WS-AQ-REC.
           05  WS-AQ-TXN-ID              PIC X(20).
           05  WS-AQ-CARD-NUMBER          PIC X(16).
           05  WS-AQ-TXN-AMOUNT           PIC 9(11)V99.
           05  WS-AQ-TXN-DATE             PIC X(10).
           05  WS-AQ-ACQUIRER-ID           PIC X(11).
           05  WS-AQ-AUTH-CODE             PIC X(06).
           05  WS-AQ-SETTLE-AMOUNT         PIC 9(11)V99.
           05  WS-AQ-NETWORK-ID            PIC X(04).
           05  FILLER                      PIC X(57).

       01  WS-TXN-SEQ                     PIC 9(06) VALUE 0.
       01  WS-GEN-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  WS-GEN-EOF                 VALUE 'Y'.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           PERFORM 1000-LOAD-CARD-TABLE
           PERFORM 2000-GEN-CARD-ISSUANCE
           PERFORM 3000-GEN-ACTIVATION
           PERFORM 4000-GEN-STATUS-CHANGE
           PERFORM 5000-GEN-TRANSACTIONS
           PERFORM 6000-GEN-INQUIRY-INPUT
           PERFORM 7000-GEN-UPDATE-INPUT
           DISPLAY 'GENDATA - ALL TEST DATA FILES CREATED'
           STOP RUN.

      ******************************************************************
      * 1000-LOAD-CARD-TABLE: READ ALL CARDS FROM MASTER FILE         *
      ******************************************************************
       1000-LOAD-CARD-TABLE.
           OPEN INPUT CARD-MASTER-FILE
           IF WS-CM-FILE-STATUS NOT = '00'
               DISPLAY '*** CARDMAST OPEN ERROR: '
                   WS-CM-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           MOVE 0 TO WS-CARD-COUNT
           PERFORM UNTIL WS-GEN-EOF
               READ CARD-MASTER-FILE INTO WS-CARD-MASTER-REC
                   AT END
                       SET WS-GEN-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-CARD-COUNT
                       MOVE WS-CM-CARD-NUMBER
                           TO WS-CT-CARD-NUM(WS-CARD-COUNT)
                       MOVE WS-CM-CARD-STATUS
                           TO WS-CT-STATUS(WS-CARD-COUNT)
                       MOVE WS-CM-CUSTOMER-ID
                           TO WS-CT-CUST-ID(WS-CARD-COUNT)
                       MOVE WS-CM-CARD-TYPE
                           TO WS-CT-TYPE(WS-CARD-COUNT)
                       MOVE WS-CM-ACCOUNT-NUMBER
                           TO WS-CT-ACCT-NUM(WS-CARD-COUNT)
               END-READ
           END-PERFORM

           CLOSE CARD-MASTER-FILE
           DISPLAY 'GENDATA - LOADED ' WS-CARD-COUNT ' CARD NUMBERS'
           .

      ******************************************************************
      * 2000-GEN-CARD-ISSUANCE: CREATE CARDINP.dat                    *
      *   3 NEW CARD REQUESTS                                         *
      ******************************************************************
       2000-GEN-CARD-ISSUANCE.
           OPEN OUTPUT CARD-INPUT-FILE

      * New debit card request
           INITIALIZE WS-CI-REC
           MOVE 'NC'               TO WS-CI-REQUEST-TYPE
           MOVE '200000000001'     TO WS-CI-ACCOUNT-NUMBER
           MOVE 'CUST000011'       TO WS-CI-CUSTOMER-ID
           MOVE 'THOMAS'           TO WS-CI-FIRST-NAME
           MOVE 'ANDERSON'         TO WS-CI-LAST-NAME
           MOVE '100 BROADWAY'     TO WS-CI-ADDR-LINE1
           MOVE 'FLOOR 5'          TO WS-CI-ADDR-LINE2
           MOVE 'BOSTON'            TO WS-CI-CITY
           MOVE 'MA'               TO WS-CI-STATE
           MOVE '02101'            TO WS-CI-ZIP-CODE
           MOVE 'DB'               TO WS-CI-CARD-TYPE
           MOVE 00005000.00        TO WS-CI-DAILY-LIMIT
           MOVE 'BOSBR1'           TO WS-CI-BRANCH-CODE
           WRITE CARD-INPUT-RECORD FROM WS-CI-REC

      * New prepaid card request
           INITIALIZE WS-CI-REC
           MOVE 'NC'               TO WS-CI-REQUEST-TYPE
           MOVE '200000000002'     TO WS-CI-ACCOUNT-NUMBER
           MOVE 'CUST000012'       TO WS-CI-CUSTOMER-ID
           MOVE 'PATRICIA'         TO WS-CI-FIRST-NAME
           MOVE 'WILLIAMS'         TO WS-CI-LAST-NAME
           MOVE '250 MARKET ST'    TO WS-CI-ADDR-LINE1
           MOVE SPACES             TO WS-CI-ADDR-LINE2
           MOVE 'SEATTLE'          TO WS-CI-CITY
           MOVE 'WA'               TO WS-CI-STATE
           MOVE '98101'            TO WS-CI-ZIP-CODE
           MOVE 'PP'               TO WS-CI-CARD-TYPE
           MOVE 00002000.00        TO WS-CI-DAILY-LIMIT
           MOVE 'SEABR1'           TO WS-CI-BRANCH-CODE
           WRITE CARD-INPUT-RECORD FROM WS-CI-REC

      * Another debit card
           INITIALIZE WS-CI-REC
           MOVE 'NC'               TO WS-CI-REQUEST-TYPE
           MOVE '200000000003'     TO WS-CI-ACCOUNT-NUMBER
           MOVE 'CUST000013'       TO WS-CI-CUSTOMER-ID
           MOVE 'RICHARD'          TO WS-CI-FIRST-NAME
           MOVE 'MARTINEZ'         TO WS-CI-LAST-NAME
           MOVE '500 PENN AVE'     TO WS-CI-ADDR-LINE1
           MOVE 'SUITE 200'        TO WS-CI-ADDR-LINE2
           MOVE 'MIAMI'            TO WS-CI-CITY
           MOVE 'FL'               TO WS-CI-STATE
           MOVE '33101'            TO WS-CI-ZIP-CODE
           MOVE 'DB'               TO WS-CI-CARD-TYPE
           MOVE 00008000.00        TO WS-CI-DAILY-LIMIT
           MOVE 'MIABR1'           TO WS-CI-BRANCH-CODE
           WRITE CARD-INPUT-RECORD FROM WS-CI-REC

           CLOSE CARD-INPUT-FILE
           DISPLAY 'GENDATA - CARDINP.dat CREATED (3 RECORDS)'
           .

      ******************************************************************
      * 3000-GEN-ACTIVATION: CREATE ACTVINP.dat                        *
      *   ACTIVATE NW STATUS CARDS (CARDS 3 AND 10)                    *
      ******************************************************************
       3000-GEN-ACTIVATION.
           OPEN OUTPUT ACTV-INPUT-FILE

           PERFORM VARYING WS-CARD-IDX FROM 1 BY 1
               UNTIL WS-CARD-IDX > WS-CARD-COUNT
               IF WS-CT-STATUS(WS-CARD-IDX) = 'NW'
                   INITIALIZE WS-AI-REC
                   MOVE WS-CT-CARD-NUM(WS-CARD-IDX)
                       TO WS-AI-CARD-NUMBER
                   MOVE WS-CT-CUST-ID(WS-CARD-IDX)
                       TO WS-AI-CUSTOMER-ID
                   MOVE '1234'     TO WS-AI-PIN-OFFSET
                   MOVE 'BR'       TO WS-AI-CHANNEL
                   WRITE ACTV-INPUT-RECORD FROM WS-AI-REC
               END-IF
           END-PERFORM

           CLOSE ACTV-INPUT-FILE
           DISPLAY 'GENDATA - ACTVINP.dat CREATED'
           .

      ******************************************************************
      * 4000-GEN-STATUS-CHANGE: CREATE STSINP.dat                     *
      *   BL: Block card 1 (AC->BL)                                   *
      *   UB: Unblock card 4 (BL->AC)                                 *
      *   HL: Hotlist card 9 (AC->BL)                                 *
      ******************************************************************
       4000-GEN-STATUS-CHANGE.
           OPEN OUTPUT STS-INPUT-FILE

      * Block card 1 (AC -> BL)
           IF WS-CARD-COUNT >= 1
               INITIALIZE WS-SI-REC
               MOVE WS-CT-CARD-NUM(1) TO WS-SI-CARD-NUMBER
               MOVE 'BL'              TO WS-SI-ACTION-CODE
               MOVE 'LOST'            TO WS-SI-REASON-CODE
               MOVE 'AGENT001'        TO WS-SI-REQUESTOR-ID
               MOVE 'PH'              TO WS-SI-CHANNEL
               WRITE STS-INPUT-RECORD FROM WS-SI-REC
           END-IF

      * Unblock card 4 (BL -> AC)
           IF WS-CARD-COUNT >= 4
               INITIALIZE WS-SI-REC
               MOVE WS-CT-CARD-NUM(4) TO WS-SI-CARD-NUMBER
               MOVE 'UB'              TO WS-SI-ACTION-CODE
               MOVE 'CUST'            TO WS-SI-REASON-CODE
               MOVE 'AGENT002'        TO WS-SI-REQUESTOR-ID
               MOVE 'BR'              TO WS-SI-CHANNEL
               WRITE STS-INPUT-RECORD FROM WS-SI-REC
           END-IF

      * Hotlist card 9 (AC -> BL via HL)
           IF WS-CARD-COUNT >= 9
               INITIALIZE WS-SI-REC
               MOVE WS-CT-CARD-NUM(9) TO WS-SI-CARD-NUMBER
               MOVE 'HL'              TO WS-SI-ACTION-CODE
               MOVE 'FRAD'            TO WS-SI-REASON-CODE
               MOVE 'FRAUD01'         TO WS-SI-REQUESTOR-ID
               MOVE 'OL'              TO WS-SI-CHANNEL
               WRITE STS-INPUT-RECORD FROM WS-SI-REC
           END-IF

           CLOSE STS-INPUT-FILE
           DISPLAY 'GENDATA - STSINP.dat CREATED (3 RECORDS)'
           .

      ******************************************************************
      * 5000-GEN-TRANSACTIONS: CREATE TXNINP.dat AND ACQFILE.dat      *
      *   5 SETTLEMENT TRANSACTIONS ACROSS 3 NETWORKS                 *
      ******************************************************************
       5000-GEN-TRANSACTIONS.
           OPEN OUTPUT TXN-INPUT-FILE
                       ACQ-INPUT-FILE

           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           STRING WS-CURRENT-YEAR '-'
                  WS-CURRENT-MONTH '-'
                  WS-CURRENT-DAY
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
           END-STRING

      * TXN 1: VISA purchase - card 1 (matched)
           ADD 1 TO WS-TXN-SEQ
           INITIALIZE WS-TI-REC
           STRING 'TXN' WS-FORMATTED-DATE WS-TXN-SEQ
               DELIMITED BY SIZE INTO WS-TI-TXN-ID
           MOVE WS-CT-CARD-NUM(1)    TO WS-TI-CARD-NUMBER
           MOVE WS-CT-ACCT-NUM(1)    TO WS-TI-ACCOUNT-NUMBER
           MOVE 'PU'                  TO WS-TI-TXN-TYPE
           MOVE 00000100.50           TO WS-TI-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-TI-TXN-DATE
           MOVE 'MERCH00000001'       TO WS-TI-MERCHANT-ID
           MOVE 'AMAZON MARKETPLACE'  TO WS-TI-MERCHANT-NAME
           MOVE 'ACQ00000001'         TO WS-TI-ACQUIRER-ID
           MOVE 'ISS00000001'         TO WS-TI-ISSUER-ID
           MOVE 'VISA'                TO WS-TI-NETWORK-ID
           MOVE 0000001.76            TO WS-TI-INTERCHANGE-FEE
           WRITE TXN-INPUT-RECORD FROM WS-TI-REC
      * Matching acquirer record
           INITIALIZE WS-AQ-REC
           MOVE WS-TI-TXN-ID         TO WS-AQ-TXN-ID
           MOVE WS-TI-CARD-NUMBER    TO WS-AQ-CARD-NUMBER
           MOVE 00000100.50           TO WS-AQ-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-AQ-TXN-DATE
           MOVE 'ACQ00000001'         TO WS-AQ-ACQUIRER-ID
           MOVE 'AUTH01'              TO WS-AQ-AUTH-CODE
           MOVE 00000100.50           TO WS-AQ-SETTLE-AMOUNT
           MOVE 'VISA'                TO WS-AQ-NETWORK-ID
           WRITE ACQ-INPUT-RECORD FROM WS-AQ-REC

      * TXN 2: MC purchase - card 2 (matched)
           ADD 1 TO WS-TXN-SEQ
           INITIALIZE WS-TI-REC
           STRING 'TXN' WS-FORMATTED-DATE WS-TXN-SEQ
               DELIMITED BY SIZE INTO WS-TI-TXN-ID
           MOVE WS-CT-CARD-NUM(2)    TO WS-TI-CARD-NUMBER
           MOVE WS-CT-ACCT-NUM(2)    TO WS-TI-ACCOUNT-NUMBER
           MOVE 'PU'                  TO WS-TI-TXN-TYPE
           MOVE 00000250.00           TO WS-TI-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-TI-TXN-DATE
           MOVE 'MERCH00000002'       TO WS-TI-MERCHANT-ID
           MOVE 'WALMART STORE 1234'  TO WS-TI-MERCHANT-NAME
           MOVE 'ACQ00000002'         TO WS-TI-ACQUIRER-ID
           MOVE 'ISS00000001'         TO WS-TI-ISSUER-ID
           MOVE 'MC  '                TO WS-TI-NETWORK-ID
           MOVE 0000004.38            TO WS-TI-INTERCHANGE-FEE
           WRITE TXN-INPUT-RECORD FROM WS-TI-REC
      * Matching acquirer record
           INITIALIZE WS-AQ-REC
           MOVE WS-TI-TXN-ID         TO WS-AQ-TXN-ID
           MOVE WS-TI-CARD-NUMBER    TO WS-AQ-CARD-NUMBER
           MOVE 00000250.00           TO WS-AQ-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-AQ-TXN-DATE
           MOVE 'ACQ00000002'         TO WS-AQ-ACQUIRER-ID
           MOVE 'AUTH02'              TO WS-AQ-AUTH-CODE
           MOVE 00000250.00           TO WS-AQ-SETTLE-AMOUNT
           MOVE 'MC  '                TO WS-AQ-NETWORK-ID
           WRITE ACQ-INPUT-RECORD FROM WS-AQ-REC

      * TXN 3: STAR debit - card 5 (matched)
           ADD 1 TO WS-TXN-SEQ
           INITIALIZE WS-TI-REC
           STRING 'TXN' WS-FORMATTED-DATE WS-TXN-SEQ
               DELIMITED BY SIZE INTO WS-TI-TXN-ID
           MOVE WS-CT-CARD-NUM(5)    TO WS-TI-CARD-NUMBER
           MOVE WS-CT-ACCT-NUM(5)    TO WS-TI-ACCOUNT-NUMBER
           MOVE 'PU'                  TO WS-TI-TXN-TYPE
           MOVE 00000075.99           TO WS-TI-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-TI-TXN-DATE
           MOVE 'MERCH00000003'       TO WS-TI-MERCHANT-ID
           MOVE 'TARGET STORE 5678'   TO WS-TI-MERCHANT-NAME
           MOVE 'ACQ00000003'         TO WS-TI-ACQUIRER-ID
           MOVE 'ISS00000001'         TO WS-TI-ISSUER-ID
           MOVE 'STAR'                TO WS-TI-NETWORK-ID
           MOVE 0000001.14            TO WS-TI-INTERCHANGE-FEE
           WRITE TXN-INPUT-RECORD FROM WS-TI-REC
      * Matching acquirer record
           INITIALIZE WS-AQ-REC
           MOVE WS-TI-TXN-ID         TO WS-AQ-TXN-ID
           MOVE WS-TI-CARD-NUMBER    TO WS-AQ-CARD-NUMBER
           MOVE 00000075.99           TO WS-AQ-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-AQ-TXN-DATE
           MOVE 'ACQ00000003'         TO WS-AQ-ACQUIRER-ID
           MOVE 'AUTH03'              TO WS-AQ-AUTH-CODE
           MOVE 00000075.99           TO WS-AQ-SETTLE-AMOUNT
           MOVE 'STAR'                TO WS-AQ-NETWORK-ID
           WRITE ACQ-INPUT-RECORD FROM WS-AQ-REC

      * TXN 4: VISA purchase - card 6 (AMOUNT MISMATCH)
           ADD 1 TO WS-TXN-SEQ
           INITIALIZE WS-TI-REC
           STRING 'TXN' WS-FORMATTED-DATE WS-TXN-SEQ
               DELIMITED BY SIZE INTO WS-TI-TXN-ID
           MOVE WS-CT-CARD-NUM(6)    TO WS-TI-CARD-NUMBER
           MOVE WS-CT-ACCT-NUM(6)    TO WS-TI-ACCOUNT-NUMBER
           MOVE 'PU'                  TO WS-TI-TXN-TYPE
           MOVE 00000500.00           TO WS-TI-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-TI-TXN-DATE
           MOVE 'MERCH00000004'       TO WS-TI-MERCHANT-ID
           MOVE 'BEST BUY STORE 42'   TO WS-TI-MERCHANT-NAME
           MOVE 'ACQ00000001'         TO WS-TI-ACQUIRER-ID
           MOVE 'ISS00000001'         TO WS-TI-ISSUER-ID
           MOVE 'VISA'                TO WS-TI-NETWORK-ID
           MOVE 0000008.75            TO WS-TI-INTERCHANGE-FEE
           WRITE TXN-INPUT-RECORD FROM WS-TI-REC
      * Acquirer with DIFFERENT amount (dispute scenario)
           INITIALIZE WS-AQ-REC
           MOVE WS-TI-TXN-ID         TO WS-AQ-TXN-ID
           MOVE WS-TI-CARD-NUMBER    TO WS-AQ-CARD-NUMBER
           MOVE 00000499.99           TO WS-AQ-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-AQ-TXN-DATE
           MOVE 'ACQ00000001'         TO WS-AQ-ACQUIRER-ID
           MOVE 'AUTH04'              TO WS-AQ-AUTH-CODE
           MOVE 00000499.99           TO WS-AQ-SETTLE-AMOUNT
           MOVE 'VISA'                TO WS-AQ-NETWORK-ID
           WRITE ACQ-INPUT-RECORD FROM WS-AQ-REC

      * TXN 5: VISA purchase - card 7 (UNMATCHED SETTLEMENT)
           ADD 1 TO WS-TXN-SEQ
           INITIALIZE WS-TI-REC
           STRING 'TXN' WS-FORMATTED-DATE WS-TXN-SEQ
               DELIMITED BY SIZE INTO WS-TI-TXN-ID
           MOVE WS-CT-CARD-NUM(7)    TO WS-TI-CARD-NUMBER
           MOVE WS-CT-ACCT-NUM(7)    TO WS-TI-ACCOUNT-NUMBER
           MOVE 'PU'                  TO WS-TI-TXN-TYPE
           MOVE 00000199.95           TO WS-TI-TXN-AMOUNT
           MOVE WS-FORMATTED-DATE     TO WS-TI-TXN-DATE
           MOVE 'MERCH00000005'       TO WS-TI-MERCHANT-ID
           MOVE 'HOME DEPOT 789'      TO WS-TI-MERCHANT-NAME
           MOVE 'ACQ00000003'         TO WS-TI-ACQUIRER-ID
           MOVE 'ISS00000001'         TO WS-TI-ISSUER-ID
           MOVE 'VISA'                TO WS-TI-NETWORK-ID
           MOVE 0000003.50            TO WS-TI-INTERCHANGE-FEE
           WRITE TXN-INPUT-RECORD FROM WS-TI-REC
      * NO acquirer record for TXN 5 - tests unmatched scenario

           CLOSE TXN-INPUT-FILE
                 ACQ-INPUT-FILE
           DISPLAY 'GENDATA - TXNINP.dat CREATED (5 RECORDS)'
           DISPLAY 'GENDATA - ACQFILE.dat CREATED (4 RECORDS)'
           .

      ******************************************************************
      * 6000-GEN-INQUIRY-INPUT: CREATE INQINP.dat (stdin for PIONL100)*
      ******************************************************************
       6000-GEN-INQUIRY-INPUT.
           OPEN OUTPUT INQ-INPUT-FILE

      * Look up card 1
           IF WS-CARD-COUNT >= 1
               INITIALIZE INQ-INPUT-RECORD
               MOVE WS-CT-CARD-NUM(1) TO INQ-INPUT-RECORD
               WRITE INQ-INPUT-RECORD
           END-IF

      * Look up card 5
           IF WS-CARD-COUNT >= 5
               INITIALIZE INQ-INPUT-RECORD
               MOVE WS-CT-CARD-NUM(5) TO INQ-INPUT-RECORD
               WRITE INQ-INPUT-RECORD
           END-IF

      * Blank line to exit
           INITIALIZE INQ-INPUT-RECORD
           MOVE SPACES TO INQ-INPUT-RECORD
           WRITE INQ-INPUT-RECORD

           CLOSE INQ-INPUT-FILE
           DISPLAY 'GENDATA - INQINP.dat CREATED'
           .

      ******************************************************************
      * 7000-GEN-UPDATE-INPUT: CREATE UPDINP.dat (stdin for PIONL200) *
      ******************************************************************
       7000-GEN-UPDATE-INPUT.
           OPEN OUTPUT UPD-INPUT-FILE

      * Update card 2 address
           IF WS-CARD-COUNT >= 2
               INITIALIZE UPD-INPUT-RECORD
               MOVE WS-CT-CARD-NUM(2) TO UPD-INPUT-RECORD
               WRITE UPD-INPUT-RECORD
      * Choice: 1 = Address Line 1
               INITIALIZE UPD-INPUT-RECORD
               MOVE '1' TO UPD-INPUT-RECORD
               WRITE UPD-INPUT-RECORD
      * New value
               INITIALIZE UPD-INPUT-RECORD
               MOVE '789 NEW OAK BLVD' TO UPD-INPUT-RECORD
               WRITE UPD-INPUT-RECORD
           END-IF

      * Blank line to exit
           INITIALIZE UPD-INPUT-RECORD
           MOVE SPACES TO UPD-INPUT-RECORD
           WRITE UPD-INPUT-RECORD

           CLOSE UPD-INPUT-FILE
           DISPLAY 'GENDATA - UPDINP.dat CREATED'
           .
