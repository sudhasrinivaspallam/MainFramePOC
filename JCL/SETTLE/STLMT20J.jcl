//STLMT20J JOB (ACCT),'STL MATCHING',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0045
//*
//*****************************************************************
//* JOB: STLMT20J                                                  *
//* DESC: SETTLEMENT - TRANSACTION MATCHING                        *
//* FREQ: DAILY - CA7 SCHEDULED AFTER STLMT10J                    *
//* DEPENDS: STLMT10J (SUCCESSFUL)                                 *
//* PROGRAMS: IDCAMS REPRO, SORT, STLMT200 (COBOL)                *
//*****************************************************************
//*
//*------- STEP 01: REPRO VSAM TO FLAT FILE -----------------------
//*
//STEP005  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//INVSAMFL DD DSN=SETTLE.DAILY.TRANS,
//            DISP=SHR
//OUTFLAT  DD DSN=&&VSAMFLAT,
//            DISP=(NEW,PASS),
//            SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=0)
//SYSIN    DD *
  REPRO INFILE(INVSAMFL) OUTFILE(OUTFLAT)
/*
//*
//*------- STEP 02: SORT VSAM EXTRACT BY TXN ID ------------------
//*
//STEP007  EXEC PGM=SORT,COND=(4,LT)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=&&VSAMFLAT,
//            DISP=(OLD,DELETE)
//SORTOUT  DD DSN=&&SORTSTL,
//            DISP=(NEW,PASS),
//            SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=0)
//SYSIN    DD *
  SORT FIELDS=(21,20,CH,A)
/*
//*
//*------- STEP 03: SORT ACQUIRER FILE BY TXN ID ------------------
//*
//STEP010  EXEC PGM=SORT,COND=(4,LT)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=ACQUIRE.DAILY.CONFIRMATIONS,
//            DISP=SHR
//SORTOUT  DD DSN=&&SORTACQ,
//            DISP=(NEW,PASS),
//            SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//SYSIN    DD *
  SORT FIELDS=(1,20,CH,A)
  INCLUDE COND=(1,20,CH,NE,C'                    ')
/*
//*
//*------- STEP 04: EXECUTE MATCHING PROGRAM ----------------------
//*
//STEP020  EXEC PGM=STLMT200,COND=(4,LT)
//STEPLIB  DD DSN=SETTLE.PROD.LOADLIB,DISP=SHR
//STLSORT  DD DSN=&&SORTSTL,
//            DISP=(OLD,DELETE)
//ACQFILE  DD DSN=&&SORTACQ,
//            DISP=(OLD,DELETE)
//STLOUT   DD DSN=SETTLE.DAILY.MATCHED(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(30,10),RLSE),
//            DCB=(RECFM=FB,LRECL=300,BLKSIZE=0)
//STLERR   DD DSN=SETTLE.DAILY.UNMATCHED(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=300,BLKSIZE=0)
//STLRPT   DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
