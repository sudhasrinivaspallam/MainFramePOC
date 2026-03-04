      ******************************************************************
      * COPYBOOK: CPYCRD01                                          *
      * DESCRIPTION: Card Master Record Layout                      *
      * USED BY: PICRD100, PICRD200, PICRD300, PICRD400             *
      *          PIONL100, PIONL200                                  *
      * STORAGE: Indexed Sequential File (VSAM KSDS equivalent)     *
      * NOTE: This layout matches the DB2 TB_CARD_MASTER schema.    *
      *       On mainframe this is DB2; locally it is an indexed    *
      *       file with the same record structure.                  *
      ******************************************************************
       01  WS-CARD-MASTER-REC.
           05  WS-CM-CARD-NUMBER          PIC X(16).
           05  WS-CM-CARD-TYPE            PIC X(02).
               88  WS-CM-TYPE-DEBIT       VALUE 'DB'.
               88  WS-CM-TYPE-PREPAID     VALUE 'PP'.
           05  WS-CM-ACCOUNT-NUMBER       PIC X(12).
           05  WS-CM-CUSTOMER-ID          PIC X(10).
           05  WS-CM-CUSTOMER-NAME.
               10  WS-CM-FIRST-NAME       PIC X(25).
               10  WS-CM-LAST-NAME        PIC X(25).
           05  WS-CM-ADDRESS.
               10  WS-CM-ADDR-LINE1       PIC X(40).
               10  WS-CM-ADDR-LINE2       PIC X(40).
               10  WS-CM-CITY             PIC X(25).
               10  WS-CM-STATE            PIC X(02).
               10  WS-CM-ZIP-CODE         PIC X(10).
           05  WS-CM-CARD-STATUS          PIC X(02).
               88  WS-CM-STAT-NEW         VALUE 'NW'.
               88  WS-CM-STAT-ACTIVE      VALUE 'AC'.
               88  WS-CM-STAT-INACTIVE    VALUE 'IN'.
               88  WS-CM-STAT-BLOCKED     VALUE 'BL'.
               88  WS-CM-STAT-EXPIRED     VALUE 'EX'.
               88  WS-CM-STAT-CLOSED      VALUE 'CL'.
           05  WS-CM-ISSUE-DATE           PIC X(10).
           05  WS-CM-EXPIRY-DATE          PIC X(10).
           05  WS-CM-ACTIVATION-DATE      PIC X(10).
           05  WS-CM-LAST-USED-DATE       PIC X(10).
           05  WS-CM-DAILY-LIMIT          PIC 9(09)V99.
           05  WS-CM-AVAILABLE-BALANCE    PIC 9(11)V99.
           05  WS-CM-PIN-OFFSET           PIC X(04).
           05  WS-CM-CVV-VALUE            PIC X(03).
           05  WS-CM-BRANCH-CODE          PIC X(06).
           05  WS-CM-CREATED-TIMESTAMP    PIC X(26).
           05  WS-CM-UPDATED-TIMESTAMP    PIC X(26).
           05  FILLER                     PIC X(20).
