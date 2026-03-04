      ******************************************************************
      * COPYBOOK: CPYCRD02                                          *
      * DESCRIPTION: Card Transaction Record Layout                 *
      * USED BY: PICRD100, PICRD300, STLMT100                       *
      * DATABASE: DB2 TABLE - TB_CARD_TRANSACTION                   *
      ******************************************************************
       01  WS-CARD-TXN-REC.
           05  WS-CT-TXN-ID              PIC X(20).
           05  WS-CT-CARD-NUMBER         PIC X(16).
           05  WS-CT-TXN-TYPE            PIC X(02).
               88  WS-CT-TYPE-PURCHASE    VALUE 'PU'.
               88  WS-CT-TYPE-ATM-WD     VALUE 'AW'.
               88  WS-CT-TYPE-REFUND     VALUE 'RF'.
               88  WS-CT-TYPE-REVERSAL   VALUE 'RV'.
               88  WS-CT-TYPE-FEE        VALUE 'FE'.
           05  WS-CT-TXN-AMOUNT          PIC S9(11)V99 COMP-3.
           05  WS-CT-TXN-DATE            PIC X(10).
           05  WS-CT-TXN-TIME            PIC X(08).
           05  WS-CT-MERCHANT-ID         PIC X(15).
           05  WS-CT-MERCHANT-NAME       PIC X(40).
           05  WS-CT-MERCHANT-CATG       PIC X(04).
           05  WS-CT-AUTH-CODE           PIC X(06).
           05  WS-CT-RESPONSE-CODE       PIC X(03).
               88  WS-CT-RESP-APPROVED   VALUE '000'.
               88  WS-CT-RESP-DECLINED   VALUE '051'.
               88  WS-CT-RESP-INVALID    VALUE '014'.
               88  WS-CT-RESP-EXPIRED    VALUE '054'.
           05  WS-CT-TERMINAL-ID         PIC X(08).
           05  WS-CT-BATCH-NUMBER        PIC X(08).
           05  WS-CT-SETTLE-FLAG         PIC X(01).
               88  WS-CT-NOT-SETTLED     VALUE 'N'.
               88  WS-CT-SETTLED         VALUE 'Y'.
               88  WS-CT-PENDING         VALUE 'P'.
           05  WS-CT-SETTLE-DATE         PIC X(10).
           05  WS-CT-CREATED-TIMESTAMP   PIC X(26).
           05  FILLER                    PIC X(15).
