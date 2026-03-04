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

      ******************************************************************
      * NOTE: DB2 programs should use EXEC SQL INCLUDE SQLCA END-EXEC *
      *       in their own WORKING-STORAGE. Do NOT define SQLCA here  *
      *       to avoid duplicate SQLCODE definitions.                  *
      ******************************************************************
