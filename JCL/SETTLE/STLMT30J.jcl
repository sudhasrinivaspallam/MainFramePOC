//STLMT30J JOB (ACCT),'STL RECONCILIATION',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0030
//*
//*****************************************************************
//* JOB: STLMT30J                                                  *
//* DESC: SETTLEMENT - RECONCILIATION AND SUMMARY                  *
//* FREQ: DAILY - CA7 SCHEDULED AFTER STLMT20J                    *
//* DEPENDS: STLMT20J (SUCCESSFUL)                                 *
//* PROGRAMS: STLMT300 (COBOL/VSAM)                                *
//*****************************************************************
//*
//*------- STEP 01: DELETE/DEFINE SUMMARY VSAM --------------------
//*
//STEP010  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE SETTLE.DAILY.SUMMARY -
         CLUSTER -
         PURGE

  IF LASTCC <= 8 THEN -
    DO
      DEFINE CLUSTER -
        (NAME(SETTLE.DAILY.SUMMARY) -
         INDEXED                    -
         RECORDS(100 50)            -
         RECORDSIZE(214 214)        -
         KEYS(14 0)                 -
         FREESPACE(20 10)           -
         SHAREOPTIONS(2 3))         -
        DATA                        -
        (NAME(SETTLE.DAILY.SUMMARY.DATA) -
         CISZ(4096))               -
        INDEX                       -
        (NAME(SETTLE.DAILY.SUMMARY.INDEX))
    END
/*
//*
//*------- STEP 02: EXECUTE RECONCILIATION PROGRAM ----------------
//*
//STEP020  EXEC PGM=STLMT300,COND=(0,NE)
//STEPLIB  DD DSN=SETTLE.PROD.LOADLIB,DISP=SHR
//STLMTCH  DD DSN=SETTLE.DAILY.MATCHED(&DATE.),
//            DISP=SHR
//SUMVSAM  DD DSN=SETTLE.DAILY.SUMMARY,
//            DISP=SHR
//RECONRPT DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
