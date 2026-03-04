      ******************************************************************
      * COPYBOOK: CPYCOM01                                          *
      * DESCRIPTION: Common Date/Time Routines and Work Areas        *
      * USED BY: All programs                                         *
      ******************************************************************
       01  WS-COMMON-WORK-AREAS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURRENT-DATE.
                   15  WS-CURRENT-YEAR    PIC 9(04).
                   15  WS-CURRENT-MONTH   PIC 9(02).
                   15  WS-CURRENT-DAY     PIC 9(02).
               10  WS-CURRENT-TIME.
                   15  WS-CURRENT-HOUR    PIC 9(02).
                   15  WS-CURRENT-MIN     PIC 9(02).
                   15  WS-CURRENT-SEC     PIC 9(02).
                   15  WS-CURRENT-HUND    PIC 9(02).
               10  WS-GMT-OFFSET          PIC S9(04).
           05  WS-FORMATTED-DATE          PIC X(10).
           05  WS-FORMATTED-TIME          PIC X(08).
           05  WS-FORMATTED-TIMESTAMP     PIC X(26).

       01  WS-DATE-WORK-AREAS.
           05  WS-DATE-WORK-1            PIC 9(08).
           05  WS-DATE-WORK-2            PIC 9(08).
           05  WS-DATE-DIFF-DAYS         PIC S9(05) COMP-3.
           05  WS-LEAP-YEAR-FLAG         PIC X(01).
               88  WS-IS-LEAP-YEAR       VALUE 'Y'.
               88  WS-NOT-LEAP-YEAR      VALUE 'N'.

       01  WS-COMMON-COUNTERS.
           05  WS-RECORDS-READ           PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-WRITTEN        PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-UPDATED        PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-REJECTED       PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-BYPASSED       PIC 9(09) VALUE ZEROS.

       01  WS-COMMON-FLAGS.
           05  WS-EOF-FLAG               PIC X(01) VALUE 'N'.
               88  WS-EOF                VALUE 'Y'.
               88  WS-NOT-EOF            VALUE 'N'.
           05  WS-PROCESS-FLAG           PIC X(01) VALUE 'Y'.
               88  WS-CONTINUE-PROCESS   VALUE 'Y'.
               88  WS-STOP-PROCESS       VALUE 'N'.

       01  WS-RETURN-CODE                PIC S9(04) COMP VALUE 0.
       01  WS-ABEND-CODE                 PIC X(04) VALUE SPACES.
