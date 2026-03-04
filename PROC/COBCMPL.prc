//COBCMPL  PROC WSPC='50',MBR=,
//            SRCLIB='PAYMENTS.PI.COBOL.SRCLIB',
//            CPYLIB='PAYMENTS.PI.COPYBOOK',
//            LOADLIB='PAYMENTS.PI.LOADLIB',
//            DBRMLIB='PAYMENTS.PI.DBRMLIB',
//            OUTC='*',REGN='6M'
//*----------------------------------------------------------*
//*  PROC: COBCMPL                                          *
//*  DESC: STANDARD COBOL COMPILE AND LINK PROCEDURE         *
//*        SUPPORTS DB2 PRECOMPILE (OPTIONAL)                *
//*  PARM: WSPC   - WORK SPACE SIZE                          *
//*        MBR    - SOURCE MEMBER NAME                       *
//*        SRCLIB - SOURCE PDS                               *
//*        CPYLIB - COPYBOOK PDS                             *
//*        LOADLIB - LOAD MODULE PDS                         *
//*        DBRMLIB - DBRM PDS (DB2 ONLY)                     *
//*----------------------------------------------------------*
//*
//*-------- STEP 1: DB2 PRECOMPILE (CONDITIONAL) ------------*
//*
//PC       EXEC PGM=DSNHPC,
//            PARM='HOST(COBOL),APOST,APOSTSQL,SOURCE,XREF',
//            COND=(4,LT),
//            REGION=&REGN
//STEPLIB  DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=&DBRMLIB(&MBR),DISP=SHR
//SYSCIN   DD DSN=&&DSNHOUT,DISP=(MOD,PASS),
//            UNIT=SYSALLDA,SPACE=(800,(&WSPC,&WSPC))
//SYSIN    DD DSN=&SRCLIB(&MBR),DISP=SHR
//SYSLIB   DD DSN=&CPYLIB,DISP=SHR
//SYSPRINT DD SYSOUT=&OUTC
//SYSTERM  DD SYSOUT=&OUTC
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(800,(&WSPC,&WSPC))
//SYSUT2   DD UNIT=SYSALLDA,SPACE=(800,(&WSPC,&WSPC))
//*
//*-------- STEP 2: COBOL COMPILE ----------------------------*
//*
//COB      EXEC PGM=IGYCRCTL,
//            PARM=('LIB,OBJECT,APOST,RENT,MAP,XREF,OFFSET',
//            'OPT(1),FLAG(W),SSRANGE,LIST'),
//            COND=(4,LT),
//            REGION=&REGN
//STEPLIB  DD DSN=IGY.V6R4M0.SIGYCOMP,DISP=SHR
//SYSIN    DD DSN=&&DSNHOUT,DISP=(OLD,DELETE)
//         DD DSN=&SRCLIB(&MBR),DISP=SHR
//SYSLIB   DD DSN=&CPYLIB,DISP=SHR
//         DD DSN=CEE.SCEESAMP,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(MOD,PASS),
//            UNIT=SYSALLDA,SPACE=(TRK,(3,3))
//SYSPRINT DD SYSOUT=&OUTC
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//*
//*-------- STEP 3: LINK-EDIT --------------------------------*
//*
//LKED     EXEC PGM=IEWL,
//            PARM='LIST,MAP,XREF,LET,RENT',
//            COND=(4,LT),
//            REGION=&REGN
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=&LOADLIB(&MBR),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DB2.V12.SDSNLOAD,DISP=SHR
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=&OUTC
//SYSIN    DD *
  INCLUDE SYSLIB(DSNELI)
  NAME &MBR(R)
/*
//         PEND
