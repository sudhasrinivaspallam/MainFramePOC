      ******************************************************************
      * COPYBOOK: CPYSTL01                                          *
      * DESCRIPTION: Settlement Transaction Record Layout            *
      * USED BY: STLMT100, STLMT200, STLMT300                       *
      * STORAGE: VSAM KSDS - Indexed Sequential File                 *
      ******************************************************************
       01  WS-SETTLE-TXN-REC.
           05  WS-ST-SETTLE-ID           PIC X(20).
           05  WS-ST-TXN-ID             PIC X(20).
           05  WS-ST-CARD-NUMBER         PIC X(16).
           05  WS-ST-ACCOUNT-NUMBER      PIC X(12).
           05  WS-ST-TXN-TYPE           PIC X(02).
           05  WS-ST-TXN-AMOUNT         PIC 9(11)V99.
           05  WS-ST-TXN-DATE           PIC X(10).
           05  WS-ST-MERCHANT-ID        PIC X(15).
           05  WS-ST-MERCHANT-NAME      PIC X(40).
           05  WS-ST-ACQUIRER-ID        PIC X(11).
           05  WS-ST-ISSUER-ID          PIC X(11).
           05  WS-ST-NETWORK-ID         PIC X(04).
               88  WS-ST-NET-VISA       VALUE 'VISA'.
               88  WS-ST-NET-MC         VALUE 'MC  '.
               88  WS-ST-NET-STAR       VALUE 'STAR'.
           05  WS-ST-INTERCHANGE-FEE    PIC 9(07)V99.
           05  WS-ST-SETTLE-STATUS      PIC X(02).
               88  WS-ST-STAT-PENDING   VALUE 'PE'.
               88  WS-ST-STAT-MATCHED   VALUE 'MT'.
               88  WS-ST-STAT-UNMATCHED VALUE 'UM'.
               88  WS-ST-STAT-SETTLED   VALUE 'ST'.
               88  WS-ST-STAT-DISPUTED  VALUE 'DI'.
           05  WS-ST-SETTLE-DATE        PIC X(10).
           05  WS-ST-BATCH-SEQ-NUM      PIC 9(06).
           05  WS-ST-CREATED-TIMESTAMP  PIC X(26).
           05  FILLER                   PIC X(33).
