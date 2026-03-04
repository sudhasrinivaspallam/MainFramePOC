      ******************************************************************
      * COPYBOOK: CPYSTL02                                          *
      * DESCRIPTION: Settlement Summary Record Layout                *
      * USED BY: STLMT300, STLMT400                                  *
      * STORAGE: VSAM KSDS - Indexed Sequential File                 *
      ******************************************************************
       01  WS-SETTLE-SUMMARY-REC.
           05  WS-SS-SETTLE-DATE         PIC X(10).
           05  WS-SS-NETWORK-ID          PIC X(04).
           05  WS-SS-TOTAL-TXN-COUNT     PIC 9(09).
           05  WS-SS-TOTAL-TXN-AMOUNT    PIC 9(13)V99.
           05  WS-SS-MATCHED-COUNT       PIC 9(09).
           05  WS-SS-MATCHED-AMOUNT      PIC 9(13)V99.
           05  WS-SS-UNMATCHED-COUNT     PIC 9(09).
           05  WS-SS-UNMATCHED-AMOUNT    PIC 9(13)V99.
           05  WS-SS-DISPUTED-COUNT      PIC 9(09).
           05  WS-SS-DISPUTED-AMOUNT     PIC 9(13)V99.
           05  WS-SS-TOTAL-FEES          PIC 9(11)V99.
           05  WS-SS-NET-SETTLE-AMOUNT   PIC 9(13)V99.
           05  WS-SS-RECON-STATUS        PIC X(02).
               88  WS-SS-RECON-BALANCED  VALUE 'BL'.
               88  WS-SS-RECON-OUTOBAL   VALUE 'OB'.
               88  WS-SS-RECON-PENDING   VALUE 'PE'.
           05  WS-SS-CREATED-TIMESTAMP   PIC X(26).
           05  FILLER                    PIC X(20).
