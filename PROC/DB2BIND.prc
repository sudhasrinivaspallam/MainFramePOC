//DB2BIND  PROC MBR=,
//            DBRMLIB='PAYMENTS.PI.DBRMLIB',
//            PLAN=,
//            SSID='DB2P',
//            OWNER='PAYUSR',
//            QUAL='PAYSCHM',
//            OUTC='*'
//*----------------------------------------------------------*
//*  PROC: DB2BIND                                           *
//*  DESC: DB2 BIND PLAN/PACKAGE PROCEDURE                   *
//*        BINDS DBRM TO CREATE ACCESS PATH                  *
//*  PARM: MBR     - DBRM MEMBER NAME                       *
//*        DBRMLIB - DBRM PDS                                *
//*        PLAN    - DB2 PLAN NAME                           *
//*        SSID    - DB2 SUBSYSTEM ID                        *
//*        OWNER   - DB2 PLAN OWNER                          *
//*        QUAL    - DB2 QUALIFIER                           *
//*----------------------------------------------------------*
//*
//*-------- STEP 1: FREE EXISTING PLAN -----------------------*
//*
//FREE     EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=&OUTC
//SYSPRINT DD SYSOUT=&OUTC
//SYSUDUMP DD SYSOUT=&OUTC
//SYSTSIN  DD *
  DSN SYSTEM(&SSID)
  FREE PLAN(&PLAN)
  END
/*
//*
//*-------- STEP 2: BIND PACKAGE -----------------------------*
//*
//BINDPKG  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=&DBRMLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=&OUTC
//SYSPRINT DD SYSOUT=&OUTC
//SYSUDUMP DD SYSOUT=&OUTC
//SYSTSIN  DD *
  DSN SYSTEM(&SSID)
  BIND PACKAGE(PAYMNTS) -
       MEMBER(&MBR) -
       OWNER(&OWNER) -
       QUALIFIER(&QUAL) -
       ACTION(REPLACE) -
       VALIDATE(BIND) -
       ISOLATION(CS) -
       RELEASE(COMMIT) -
       EXPLAIN(YES) -
       CURRENTDATA(YES) -
       ENCODING(EBCDIC)
  END
/*
//*
//*-------- STEP 3: BIND PLAN --------------------------------*
//*
//BINDPLN  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=&DBRMLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=&OUTC
//SYSPRINT DD SYSOUT=&OUTC
//SYSUDUMP DD SYSOUT=&OUTC
//SYSTSIN  DD *
  DSN SYSTEM(&SSID)
  BIND PLAN(&PLAN) -
       PKLIST(PAYMNTS.&MBR.*) -
       OWNER(&OWNER) -
       QUALIFIER(&QUAL) -
       ACTION(REPLACE) -
       VALIDATE(BIND) -
       ISOLATION(CS) -
       RELEASE(COMMIT) -
       EXPLAIN(YES) -
       ACQUIRE(USE) -
       CACHESIZE(1024) -
       CURRENTDATA(YES)
  END
/*
//*
//*-------- STEP 4: GRANT EXECUTE ON PLAN --------------------*
//*
//GRANT    EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=&OUTC
//SYSPRINT DD SYSOUT=&OUTC
//SYSUDUMP DD SYSOUT=&OUTC
//SYSTSIN  DD *
  DSN SYSTEM(&SSID)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIA12) -
      LIB('DB2.V12.RUNLIB.LOAD')
  END
//SYSIN    DD *
  GRANT EXECUTE ON PLAN &PLAN TO PUBLIC;
/*
//         PEND
