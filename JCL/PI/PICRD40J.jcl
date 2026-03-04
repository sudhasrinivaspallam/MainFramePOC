//PICRD40J JOB (ACCT),'PI CARD RENEWAL',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,REGION=0M,TIME=0030
//*
//*****************************************************************
//* JOB: PICRD40J                                                  *
//* DESC: PLASTIC ISSUANCE - CARD RENEWAL BATCH                    *
//* FREQ: DAILY - CA7 SCHEDULED AFTER PICRD30J                     *
//* DEPENDS: PICRD30J (SUCCESSFUL)                                 *
//* PROGRAMS: PICRD400 (COBOL/DB2)                                 *
//*****************************************************************
//*
//STEP010  EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=PI.PROD.LOADLIB,DISP=SHR
//         DD DSN=DB2.PROD.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=PI.PROD.DBRMLIB(PICRD400),DISP=SHR
//RENWOUT  DD DSN=PI.DAILY.RENEWALS(&DATE.),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=200,BLKSIZE=0)
//RENWRPT  DD SYSOUT=*,
//            DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN  PROGRAM(PICRD400) PLAN(PIPLAN01) -
       LIB('PI.PROD.LOADLIB')
  END
/*
//
