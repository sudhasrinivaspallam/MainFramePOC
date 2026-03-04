      ******************************************************************
      * COPYBOOK: CPYHIST1                                          *
      * DESCRIPTION: Card Status History Record Layout               *
      * USED BY: PICRD300                                             *
      * STORAGE: Indexed Sequential File (replaces DB2 table)        *
      ******************************************************************
       01  WS-STATUS-HISTORY-REC.
           05  WS-SH-HISTORY-KEY.
               10  WS-SH-CARD-NUMBER    PIC X(16).
               10  WS-SH-SEQ-NUM        PIC 9(06).
           05  WS-SH-PREVIOUS-STATUS    PIC X(02).
           05  WS-SH-NEW-STATUS         PIC X(02).
           05  WS-SH-REASON-CODE        PIC X(04).
           05  WS-SH-REQUESTOR-ID       PIC X(10).
           05  WS-SH-STATUS-DATE        PIC X(10).
           05  WS-SH-CREATED-TIMESTAMP  PIC X(26).
           05  FILLER                   PIC X(24).
