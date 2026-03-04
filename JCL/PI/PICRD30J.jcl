//PICRD30J JOB (ACCT),'PI CARD STATUS UPD',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0030
//*
//*****************************************************************
//* JOB: PICRD30J                                                  *
//* DESC: PLASTIC ISSUANCE - CARD STATUS UPDATE BATCH              *
//* FREQ: DAILY - CA7 SCHEDULED AFTER PICRD20J                     *
//* DEPENDS: PICRD20J (SUCCESSFUL)                                 *
//* PROGRAMS: PICRD300 (COBOL/DB2)                                 *
//*****************************************************************
//*
//STEP010  EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=PI.PROD.LOADLIB,DISP=SHR
//         DD DSN=DB2.PROD.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=PI.PROD.DBRMLIB(PICRD300),DISP=SHR
//STSINP   DD DSN=PI.DAILY.STATUS.REQUESTS,
//            DISP=SHR
//STSOUT   DD DSN=PI.DAILY.STATUS.UPDATES(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//STSERR   DD DSN=PI.DAILY.STATUS.ERRORS(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(2,1),RLSE),
//            DCB=(RECFM=FB,LRECL=180,BLKSIZE=0)
//STSRPT   DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN  PROGRAM(PICRD300) PLAN(PIPLAN01) -
       LIB('PI.PROD.LOADLIB')
  END
/*
//
