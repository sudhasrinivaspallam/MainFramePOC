//STLMT10J JOB (ACCT),'STL DAILY EXTRACT',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0045
//*
//*****************************************************************
//* JOB: STLMT10J                                                  *
//* DESC: SETTLEMENT - DAILY TRANSACTION EXTRACT                   *
//* FREQ: DAILY - CA7 SCHEDULED 07:00 AM                           *
//* PROGRAMS: SORT, STLMT100 (COBOL/VSAM)                         *
//* NOTE: SETTLEMENT IS FULLY BATCH - NO ONLINE, NO DATABASE       *
//*****************************************************************
//*
//*------- STEP 01: DELETE/DEFINE VSAM SETTLEMENT FILE ------------
//*
//STEP010  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE SETTLE.DAILY.TRANS -
         CLUSTER -
         PURGE

  IF LASTCC <= 8 THEN -
    DO
      DEFINE CLUSTER -
        (NAME(SETTLE.DAILY.TRANS)  -
         INDEXED                   -
         RECORDS(50000 10000)      -
         RECORDSIZE(250 250)       -
         KEYS(20 0)                -
         FREESPACE(20 10)          -
         SHAREOPTIONS(2 3))        -
        DATA                       -
        (NAME(SETTLE.DAILY.TRANS.DATA) -
         CISZ(8192))               -
        INDEX                      -
        (NAME(SETTLE.DAILY.TRANS.INDEX))
    END
/*
//*
//*------- STEP 02: SORT NETWORK TRANSACTIONS ---------------------
//*
//STEP020  EXEC PGM=SORT,COND=(0,NE)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=NETWORK.DAILY.VISA.TRANS,DISP=SHR
//         DD DSN=NETWORK.DAILY.MC.TRANS,DISP=SHR
//         DD DSN=NETWORK.DAILY.STAR.TRANS,DISP=SHR
//SORTOUT  DD DSN=&&SORTNET,
//            DISP=(NEW,PASS),
//            SPACE=(CYL,(50,20),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=0)
//SYSIN    DD *
  SORT FIELDS=(1,20,CH,A)
  SUM FIELDS=NONE
/*
//*
//*------- STEP 03: EXECUTE SETTLEMENT EXTRACT PROGRAM ------------
//*
//STEP030  EXEC PGM=STLMT100,COND=(4,LT)
//STEPLIB  DD DSN=SETTLE.PROD.LOADLIB,DISP=SHR
//TXNINP   DD DSN=&&SORTNET,
//            DISP=(OLD,DELETE)
//STLVSAM  DD DSN=SETTLE.DAILY.TRANS,
//            DISP=SHR
//STLERR   DD DSN=SETTLE.DAILY.EXTRACT.ERRORS(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=330,BLKSIZE=0)
//STLRPT   DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//*------- STEP 04: BACKUP VSAM TO SEQUENTIAL --------------------
//*
//STEP040  EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=SETTLE.DAILY.TRANS,DISP=SHR
//OUTFILE  DD DSN=SETTLE.DAILY.TRANS.BACKUP(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(50,20),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=0)
//SYSIN    DD *
  REPRO INFILE(INFILE) -
        OUTFILE(OUTFILE) -
        COUNT(999999)
/*
//
