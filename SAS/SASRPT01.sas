/*-----------------------------------------------------------------*/
/* SAS PROGRAM: SASRPT01                                            */
/* DESCRIPTION: MANAGEMENT DASHBOARD DATA PREPARATION               */
/* INPUT: SETTLEMENT AND PI DB2 EXTRACT FILES                       */
/* OUTPUT: DASHBOARD-READY SUMMARY DATASETS                         */
/*-----------------------------------------------------------------*/

OPTIONS MPRINT SYMBOLGEN NOCENTER LS=132 PS=60;

%LET RUN_DATE = %SYSFUNC(TODAY(), DATE9.);

TITLE1 "Management Dashboard Data - Payments Division";
TITLE2 "Generated: &RUN_DATE";

/*----- CARD PORTFOLIO ANALYSIS -----------------------------------*/
DATA WORK.CARD_PORTFOLIO;
    INFILE 'PI.DAILY.CARD.EXTRACT' DLM=',' FIRSTOBS=1;
    INPUT
        CARD_NUMBER   :$16.
        CARD_TYPE     :$2.
        ACCOUNT_NUM   :$12.
        CARD_STATUS   :$2.
        ISSUE_DATE    :$10.
        EXPIRY_DATE   :$10.
        DAILY_LIMIT   :11.2
        BALANCE       :13.2
        BRANCH_CODE   :$6.
    ;
    FORMAT DAILY_LIMIT BALANCE DOLLAR13.2;

    LENGTH STATUS_DESC $10 TYPE_DESC $8;
    SELECT (CARD_STATUS);
        WHEN ('NW') STATUS_DESC = 'NEW';
        WHEN ('AC') STATUS_DESC = 'ACTIVE';
        WHEN ('IN') STATUS_DESC = 'INACTIVE';
        WHEN ('BL') STATUS_DESC = 'BLOCKED';
        WHEN ('EX') STATUS_DESC = 'EXPIRED';
        WHEN ('CL') STATUS_DESC = 'CLOSED';
        OTHERWISE    STATUS_DESC = 'UNKNOWN';
    END;

    SELECT (CARD_TYPE);
        WHEN ('DB') TYPE_DESC = 'DEBIT';
        WHEN ('PP') TYPE_DESC = 'PREPAID';
        OTHERWISE    TYPE_DESC = 'OTHER';
    END;
RUN;

/* Card Status Distribution */
PROC TABULATE DATA=WORK.CARD_PORTFOLIO;
    TITLE3 "Card Portfolio - Status Distribution";
    CLASS STATUS_DESC TYPE_DESC;
    VAR BALANCE;
    TABLE STATUS_DESC ALL='TOTAL',
          (TYPE_DESC ALL='TOTAL') *
          (N='Count' BALANCE='Total Balance'*SUM*F=DOLLAR13.2);
RUN;

/* Branch Performance */
PROC SUMMARY DATA=WORK.CARD_PORTFOLIO NWAY;
    WHERE CARD_STATUS = 'AC';
    CLASS BRANCH_CODE;
    VAR BALANCE DAILY_LIMIT;
    OUTPUT OUT=WORK.BRANCH_PERF (DROP=_TYPE_ _FREQ_)
        N=ACTIVE_CARDS
        SUM(BALANCE)=TOTAL_BALANCE
        MEAN(DAILY_LIMIT)=AVG_DAILY_LIMIT;
RUN;

PROC PRINT DATA=WORK.BRANCH_PERF NOOBS;
    TITLE3 "Branch Performance - Active Cards";
    FORMAT TOTAL_BALANCE DOLLAR15.2 AVG_DAILY_LIMIT DOLLAR11.2;
RUN;

/*----- KPI SUMMARY -----------------------------------------------*/
PROC SQL;
    TITLE3 "Key Performance Indicators";
    SELECT
        COUNT(*) AS TOTAL_CARDS FORMAT=COMMA9.,
        SUM(CASE WHEN CARD_STATUS='AC' THEN 1 ELSE 0 END)
            AS ACTIVE_CARDS FORMAT=COMMA9.,
        SUM(CASE WHEN CARD_STATUS='NW' THEN 1 ELSE 0 END)
            AS NEW_CARDS FORMAT=COMMA9.,
        SUM(CASE WHEN CARD_STATUS='BL' THEN 1 ELSE 0 END)
            AS BLOCKED_CARDS FORMAT=COMMA9.,
        SUM(BALANCE) AS TOTAL_BALANCE FORMAT=DOLLAR15.2,
        MEAN(BALANCE) AS AVG_BALANCE FORMAT=DOLLAR11.2
    FROM WORK.CARD_PORTFOLIO;
QUIT;

/*----- CLEANUP ---------------------------------------------------*/
PROC DELETE DATA=WORK.CARD_PORTFOLIO
                  WORK.BRANCH_PERF;
RUN;
