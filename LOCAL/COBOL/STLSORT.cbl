       IDENTIFICATION DIVISION.
       PROGRAM-ID.    STLSORT.
       AUTHOR.        MAINFRAME POC TEAM.
      ******************************************************************
      * PROGRAM:     STLSORT                                          *
      * DESCRIPTION: COPY INDEXED SETTLEMENT VSAM TO SEQUENTIAL FILE  *
      *              EQUIVALENT TO DFSORT/ICETOOL ON MAINFRAME.        *
      *              READS STLVSAM.dat (INDEXED) -> STLSORT.dat (SEQ) *
      * INPUT:       DATA/STLVSAM.dat  - Indexed settlement file      *
      * OUTPUT:      DATA/STLSORT.dat  - Sequential sorted file       *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SETTLE-VSAM-FILE
               ASSIGN TO "DATA/STLVSAM.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS STL-VSAM-SETTLE-ID
               FILE STATUS IS WS-VSAM-STATUS.

           SELECT SETTLE-SORT-FILE
               ASSIGN TO "DATA/STLSORT.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SORT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  SETTLE-VSAM-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  SETTLE-VSAM-RECORD.
           05  STL-VSAM-KEY.
               10  STL-VSAM-SETTLE-ID    PIC X(20).
           05  STL-VSAM-DATA             PIC X(230).

       FD  SETTLE-SORT-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  SETTLE-SORT-RECORD            PIC X(250).

       WORKING-STORAGE SECTION.

       01  WS-VSAM-STATUS                PIC X(02).
       01  WS-SORT-STATUS                PIC X(02).
       01  WS-READ-COUNT                 PIC 9(09) VALUE 0.
       01  WS-WRITE-COUNT                PIC 9(09) VALUE 0.
       01  WS-EOF-FLAG                   PIC X(01) VALUE 'N'.
           88  WS-EOF                    VALUE 'Y'.

       PROCEDURE DIVISION.

       0000-MAIN-PROCESS.
           OPEN INPUT  SETTLE-VSAM-FILE
           OPEN OUTPUT SETTLE-SORT-FILE

           IF WS-VSAM-STATUS NOT = '00'
               DISPLAY 'STLSORT - VSAM OPEN ERROR: '
                   WS-VSAM-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF
               READ SETTLE-VSAM-FILE
                   AT END
                       SET WS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-READ-COUNT
                       WRITE SETTLE-SORT-RECORD
                           FROM SETTLE-VSAM-RECORD
                       ADD 1 TO WS-WRITE-COUNT
               END-READ
           END-PERFORM

           CLOSE SETTLE-VSAM-FILE
                 SETTLE-SORT-FILE

           DISPLAY 'STLSORT - READ:    ' WS-READ-COUNT
           DISPLAY 'STLSORT - WRITTEN: ' WS-WRITE-COUNT
           DISPLAY 'STLSORT - COMPLETE'
           .
