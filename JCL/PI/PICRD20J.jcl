//PICRD20J JOB (ACCT),'PI CARD ACTIVATION',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0030
//*
//*****************************************************************
//* JOB: PICRD20J                                                  *
//* DESC: PLASTIC ISSUANCE - CARD ACTIVATION BATCH                 *
//* FREQ: DAILY - CA7 SCHEDULED AFTER PICRD10J                     *
//* DEPENDS: PICRD10J (SUCCESSFUL)                                 *
//* PROGRAMS: PICRD200 (COBOL/DB2)                                 *
//*****************************************************************
//*
//*------- STEP 01: EXECUTE CARD ACTIVATION PROGRAM ---------------
//*
//STEP010  EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=PI.PROD.LOADLIB,DISP=SHR
//         DD DSN=DB2.PROD.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=PI.PROD.DBRMLIB(PICRD200),DISP=SHR
//ACTVINP  DD DSN=PI.DAILY.ACTIVATION.REQUESTS,
//            DISP=SHR
//ACTVOUT  DD DSN=PI.DAILY.ACTIVATIONS(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//ACTVERR  DD DSN=PI.DAILY.ACTV.ERRORS(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(2,1),RLSE),
//            DCB=(RECFM=FB,LRECL=160,BLKSIZE=0)
//ACTVRPT  DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN  PROGRAM(PICRD200) PLAN(PIPLAN01) -
       LIB('PI.PROD.LOADLIB')
  END
/*
//
