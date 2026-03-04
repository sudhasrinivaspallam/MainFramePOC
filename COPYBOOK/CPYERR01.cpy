      ******************************************************************
      * COPYBOOK: CPYERR01                                          *
      * DESCRIPTION: Common Error Handling Routines                  *
      * USED BY: All programs                                         *
      ******************************************************************
       01  WS-ERROR-HANDLING.
           05  WS-ERR-PROGRAM-ID         PIC X(08).
           05  WS-ERR-PARAGRAPH          PIC X(30).
           05  WS-ERR-SQLCODE            PIC S9(09) COMP VALUE 0.
           05  WS-ERR-SQLSTATE           PIC X(05) VALUE SPACES.
           05  WS-ERR-FILE-STATUS        PIC X(02) VALUE SPACES.
           05  WS-ERR-MESSAGE            PIC X(80) VALUE SPACES.
           05  WS-ERR-SEVERITY           PIC X(01).
               88  WS-ERR-INFO           VALUE 'I'.
               88  WS-ERR-WARNING        VALUE 'W'.
               88  WS-ERR-SEVERE         VALUE 'S'.
               88  WS-ERR-CRITICAL       VALUE 'C'.
           05  WS-ERR-TIMESTAMP          PIC X(26).
           05  WS-ERR-COUNT              PIC 9(05) VALUE ZEROS.
           05  WS-ERR-MAX-ALLOWED        PIC 9(05) VALUE 100.

       01  WS-SQLCA.
           05  SQLCAID                   PIC X(08) VALUE 'SQLCA   '.
           05  SQLCABC                   PIC S9(09) COMP VALUE 136.
           05  SQLCODE                   PIC S9(09) COMP VALUE 0.
           05  SQLERRM.
               49  SQLERRML             PIC S9(04) COMP VALUE 0.
               49  SQLERRMC             PIC X(70) VALUE SPACES.
           05  SQLERRP                   PIC X(08) VALUE SPACES.
           05  SQLERRD                   OCCURS 6
                                         PIC S9(09) COMP VALUE 0.
           05  SQLWARN.
               10  SQLWARN0              PIC X(01) VALUE SPACE.
               10  SQLWARN1              PIC X(01) VALUE SPACE.
               10  SQLWARN2              PIC X(01) VALUE SPACE.
               10  SQLWARN3              PIC X(01) VALUE SPACE.
               10  SQLWARN4              PIC X(01) VALUE SPACE.
               10  SQLWARN5              PIC X(01) VALUE SPACE.
               10  SQLWARN6              PIC X(01) VALUE SPACE.
               10  SQLWARN7              PIC X(01) VALUE SPACE.
               10  SQLWARN8              PIC X(01) VALUE SPACE.
               10  SQLWARN9              PIC X(01) VALUE SPACE.
               10  SQLWARNA             PIC X(01) VALUE SPACE.
           05  SQLSTATE                  PIC X(05) VALUE SPACES.
