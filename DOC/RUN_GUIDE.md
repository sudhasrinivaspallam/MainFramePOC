# Mainframe POC - End-to-End Run Guide

## For New Mainframe Engineers

This guide walks you through the entire project, explains every component, and shows how it all fits together on a real IBM z/OS mainframe.

---

## Table of Contents

1. [Understanding the Tech Stack](#1-understanding-the-tech-stack)
2. [Project Structure Walkthrough](#2-project-structure-walkthrough)
3. [How to Deploy on z/OS](#3-how-to-deploy-on-zos)
4. [Running the PI Batch Cycle](#4-running-the-pi-batch-cycle)
5. [Running the Settlement Batch Cycle](#5-running-the-settlement-batch-cycle)
6. [CICS Online Transactions](#6-cics-online-transactions)
7. [Common Mainframe Commands](#7-common-mainframe-commands)
8. [Troubleshooting Guide](#8-troubleshooting-guide)
9. [Understanding the Code Flow](#9-understanding-the-code-flow)

---

## 1. Understanding the Tech Stack

### What is COBOL?
COBOL (COmmon Business Oriented Language) is the primary programming language on mainframes. It processes data in **fixed-format records** — every field has a defined position and length (similar to a spreadsheet column).

**Key rules:**
- Columns 1-6: Sequence numbers (ignored by compiler)
- Column 7: `*` for comments, `-` for continuation
- Columns 8-11: Area A (DIVISION, SECTION, paragraph names)
- Columns 12-72: Area B (actual code statements)
- Every COBOL program has 4 divisions:
  1. `IDENTIFICATION DIVISION` — Program name
  2. `ENVIRONMENT DIVISION` — File definitions
  3. `DATA DIVISION` — Variable definitions
  4. `PROCEDURE DIVISION` — Business logic

### What is JCL?
JCL (Job Control Language) is the "batch script" of mainframes. It tells the system:
- Which programs to run (EXEC PGM=)
- Which files to use (DD statements)
- How to chain multiple steps
- What to do on errors (COND parameter)

```
//JOBNAME  JOB (ACCT),'description'    ← Job card
//STEP1    EXEC PGM=MYPROGRAM          ← Run program
//INPUT    DD DSN=MY.INPUT.FILE,DISP=SHR  ← Input file
//OUTPUT   DD DSN=MY.OUTPUT.FILE,...    ← Output file
```

### What is DB2?
DB2 is IBM's relational database on z/OS. COBOL accesses it via **Embedded SQL**:
```cobol
           EXEC SQL
               SELECT COLUMN1 INTO :HOST-VAR
               FROM TABLE WHERE KEY = :ANOTHER-VAR
           END-EXEC
```
Programs run through `IKJEFT01` utility in JCL to connect to DB2.

### What is VSAM?
VSAM (Virtual Storage Access Method) is a high-performance file system:
- **KSDS** (Key Sequenced) — like a sorted index file
- Defined using **IDCAMS** utility
- Accessed with COBOL READ/WRITE/REWRITE/DELETE statements
- Has FILE STATUS codes (00=OK, 02=duplicate alt key, 23=not found)

### What is CICS?
CICS is the online transaction processor:
- Users interact via **3270 terminals** (green screens)
- Each screen is defined with **BMS maps** (Basic Mapping Support)
- Programs are **pseudo-conversational** — they RETURN after each user interaction, saving state in COMMAREA
- Uses EXEC CICS commands instead of standard COBOL I/O

### What is DFSORT?
IBM's sort utility — sorts/merges large files:
```
SORT FIELDS=(1,16,CH,A)     ← Sort by positions 1-16, character, ascending
```

### What is Easytrieve?
A 4GL report writing language — generates formatted reports from files:
```
FILE MYFILE                   ← Define input file
  FIELD1  1  10  A           ← Position 1, length 10, alphanumeric
REPORT ...                    ← Generate report
```

### What is CA7?
Workload Automation — schedules batch jobs with dependencies and triggers.

---

## 2. Project Structure Walkthrough

```
MainFramePOC/
├── COBOL/
│   ├── PI/              ← Plastic Issuance programs
│   │   ├── PICRD100.cbl ← Card Issuance (INSERT new cards)
│   │   ├── PICRD200.cbl ← Card Activation (UPDATE status NW→AC)
│   │   ├── PICRD300.cbl ← Card Status Update (block/unblock/close)
│   │   ├── PICRD400.cbl ← Card Renewal (cursor-driven rebatch)
│   │   ├── PIONL100.cbl ← CICS: Card Inquiry screen
│   │   └── PIONL200.cbl ← CICS: Card Update screen
│   └── SETTLE/          ← Settlement programs (NO DB2, uses VSAM)
│       ├── STLMT100.cbl ← Extract network files → VSAM
│       ├── STLMT200.cbl ← Match settlement vs acquirer
│       ├── STLMT300.cbl ← Reconciliation → Summary VSAM
│       └── STLMT400.cbl ← Final reports + SAS feed
├── COPYBOOK/            ← Shared data structures (like #include)
│   ├── CPYCRD01.cpy     ← Card Master record layout
│   ├── CPYCRD02.cpy     ← Card Transaction record layout
│   ├── CPYSTL01.cpy     ← Settlement Transaction (250 bytes)
│   ├── CPYSTL02.cpy     ← Settlement Summary
│   ├── CPYCOM01.cpy     ← Common work areas (dates, counters)
│   └── CPYERR01.cpy     ← Error handling fields
├── JCL/
│   ├── PI/              ← PI batch jobs
│   │   ├── PICRD10J.jcl ← Issues cards (SORT → COBOL → DB2)
│   │   ├── PICRD20J.jcl ← Activates cards
│   │   ├── PICRD30J.jcl ← Updates card status
│   │   └── PICRD40J.jcl ← Renews expiring cards
│   └── SETTLE/          ← Settlement batch jobs
│       ├── STLMT10J.jcl ← Extract (IDCAMS → SORT → COBOL → REPRO)
│       ├── STLMT20J.jcl ← Matching (REPRO → SORT → SORT → COBOL)
│       ├── STLMT30J.jcl ← Reconciliation (IDCAMS → COBOL)
│       └── STLMT40J.jcl ← Reporting (COBOL → Easytrieve → Archive)
├── DB2/
│   ├── DDL/             ← Table definitions
│   │   ├── CRTTBL01.sql ← TB_CARD_MASTER (main card table)
│   │   ├── CRTTBL02.sql ← TB_CARD_TRANSACTION
│   │   ├── CRTTBL03.sql ← TB_CARD_STATUS_HISTORY
│   │   └── CRTIDX01.sql ← All indexes
│   └── DML/             ← Sample data & queries
│       ├── INSCRD01.sql ← Test data inserts
│       └── QRYCRD01.sql ← Common query patterns
├── BMS/
│   └── PIMAPS.bms       ← Combined BMS mapset (PISCR01 + PISCR02)
├── VSAM/                ← VSAM cluster definitions
│   ├── DEFCLS01.ams     ← 3 KSDS clusters
│   ├── DEFALT01.ams     ← Alternate indexes + paths
│   └── REPRO01.ams      ← Load/unload/verify utilities
├── SORT/                ← Sort control cards
├── EASYTRIEVE/          ← Report programs
├── SAS/                 ← Analytics programs
├── PROC/                ← Compile/bind procedures
├── SCHEDULE/            ← CA7 scheduling
├── TEST/                ← Test data and test cases
└── DOC/                 ← Design documentation
```

---

## 3. How to Deploy on z/OS

### Step 1: Upload Source to Mainframe

Using **Zowe CLI** (modern approach):
```bash
# Create PDS libraries on mainframe
zowe files create pds "USERID.PAYMENTS.COBOL" --record-format FB --record-length 80
zowe files create pds "USERID.PAYMENTS.COPYBOOK" --record-format FB --record-length 80
zowe files create pds "USERID.PAYMENTS.JCL" --record-format FB --record-length 80
zowe files create pds "USERID.PAYMENTS.BMS" --record-format FB --record-length 80

# Upload COBOL programs
zowe files upload ftds "COBOL/PI/PICRD100.cbl" "USERID.PAYMENTS.COBOL(PICRD100)"
zowe files upload ftds "COBOL/PI/PICRD200.cbl" "USERID.PAYMENTS.COBOL(PICRD200)"
# ... repeat for all programs

# Upload copybooks
zowe files upload ftds "COPYBOOK/CPYCRD01.cpy" "USERID.PAYMENTS.COPYBOOK(CPYCRD01)"
# ... repeat for all copybooks

# Upload JCL
zowe files upload ftds "JCL/PI/PICRD10J.jcl" "USERID.PAYMENTS.JCL(PICRD10J)"
# ... repeat for all JCL
```

Using **ISPF 3.4** (traditional approach):
1. Log in to ISPF (via Reflection/Virtel 3270 terminal)
2. Navigate to ISPF Option 3.4 (Dataset List)
3. Create PDS: `USERID.PAYMENTS.COBOL` (RECFM=FB, LRECL=80)
4. Open the PDS, use option **E** to edit member
5. Paste source code from PC clipboard (line by line)

Using **FTP**:
```
ftp mainframe.hostname.com
binary
cd 'USERID.PAYMENTS.COBOL'
put PICRD100.cbl PICRD100
```

### Step 2: Create DB2 Tables

```
==> SPUFI                          (from ISPF)

-- Execute each DDL file in order:
1. CRTTBL01.sql  (TB_CARD_MASTER)
2. CRTTBL02.sql  (TB_CARD_TRANSACTION)
3. CRTTBL03.sql  (TB_CARD_STATUS_HISTORY)
4. CRTIDX01.sql  (All indexes)
5. INSCRD01.sql  (Test data)
```

### Step 3: Define VSAM Clusters

Submit the IDCAMS job:
```
//DEFVSAM  JOB (ACCT),'DEFINE VSAM',CLASS=A,MSGCLASS=X
//STEP1    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=USERID.PAYMENTS.VSAM(DEFCLS01),DISP=SHR
```

### Step 4: Compile COBOL Programs

For each batch program (DB2):
```
//COMPILE  JOB (ACCT),'COMPILE',CLASS=A,MSGCLASS=X
//STEP1    EXEC PROC=COBCMPL,MBR=PICRD100
```

This runs through the `COBCMPL` procedure:
1. **DB2 Precompile** — Converts EXEC SQL to COBOL calls
2. **COBOL Compile** — Compiles COBOL source to object code
3. **Link-Edit** — Creates executable load module

For CICS programs:
1. Translate BMS map: `DFHCSDUP ... PIMAPS` → generates COBOL copybook
2. Translate CICS commands: `DFHEXCL` — converts EXEC CICS to calls
3. Compile and link as above

### Step 5: Bind DB2 Plans

```
//BIND     JOB (ACCT),'BIND',CLASS=A,MSGCLASS=X
//STEP1    EXEC PROC=DB2BIND,MBR=PICRD100,PLAN=PICRD100
```

### Step 6: Define CICS Resources

In CICS region (CEDA):
```
CEDA DEFINE PROGRAM(PIONL100) GROUP(PIMAPS) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(PIONL200) GROUP(PIMAPS) LANGUAGE(COBOL)
CEDA DEFINE TRANSACTION(PI01) PROGRAM(PIONL100) GROUP(PIMAPS)
CEDA DEFINE TRANSACTION(PI02) PROGRAM(PIONL200) GROUP(PIMAPS)
CEDA DEFINE MAPSET(PIMAPS) GROUP(PIMAPS)
CEDA INSTALL GROUP(PIMAPS)
```

---

## 4. Running the PI Batch Cycle

### Daily Execution Order (CA7 handles this automatically)

```
PICRD10J ──→ PICRD20J ──→ PICRD30J ──→ PICRD40J
```

### Manual Execution (Testing)

**Submit Job:**
```
==> SUB 'USERID.PAYMENTS.JCL(PICRD10J)'
```
Or from ISPF 3.4:
1. Navigate to JCL PDS
2. Type `S` next to `PICRD10J` (Submit)

**Check Job Status:**
```
==> ST                              (from SDSF)
    Select NP column, type 'S' next to job
```
Or use SDSF Option 13.14:
- Look for `CC 0000` = SUCCESS
- `CC 0004` = Warning (check messages)
- `CC 0008+` = Error (check SYSOUT)

### Job 1: PICRD10J - Card Issuance
```
What it does:
1. SORT step: Sorts input card requests by card type and branch
2. MAIN step: Runs PICRD100 via IKJEFT01 (DB2 connection)
   - Reads each request from sorted file
   - Validates card type (DB=Debit, PP=Prepaid)
   - Generates 16-digit card number with Luhn check digit
   - INSERTs into TB_CARD_MASTER with STATUS='NW'
   - Writes report with counts
3. NOTIFY step: Sends completion notification

Input:  PAYMENTS.PI.CARD.REQUESTS (FB80 flat file)
Output: TB_CARD_MASTER rows, Report (SYSOUT)
```

### Job 2: PICRD20J - Card Activation
```
What it does:
1. MAIN step: Runs PICRD200 via IKJEFT01
   - Reads activation request file
   - SELECTs card from DB2, verifies STATUS='NW'
   - UPDATEs STATUS to 'AC', adds PIN offset
   - INSERTs audit trail into TB_CARD_STATUS_HISTORY

Input:  PAYMENTS.PI.CARD.ACTIVATE (FB80)
Output: TB_CARD_MASTER updated, History rows inserted
```

### Job 3: PICRD30J - Card Status Update
```
What it does:
1. MAIN step: Runs PICRD300 via IKJEFT01
   - Reads status change requests (Block/Unblock/Close)
   - Validates transition matrix:
     AC→BL (block), BL→AC (unblock), AC/NW/BL→CL (close)
   - UPDATEs card status
   - INSERTs history record for audit

Input:  PAYMENTS.PI.STATUS.CHANGES (FB80)
Output: Status updated in DB2
```

### Job 4: PICRD40J - Card Renewal
```
What it does:
1. MAIN step: Runs PICRD400 via IKJEFT01
   - DECLARE CURSOR for cards expiring within 60 days
   - Uses INTEGER-OF-DATE for proper date arithmetic
   - For each expiring card:
     * Generates new card number (with Luhn check)
     * INSERTs new card (STATUS='NW', new expiry +3 years)
     * UPDATEs old card STATUS='EX'

Input:  None (cursor-driven from DB2)
Output: New renewal cards, old cards expired
```

---

## 5. Running the Settlement Batch Cycle

### Daily Execution Order

```
STLMT10J ──→ STLMT20J ──→ STLMT30J ──→ STLMT40J
```

### Job 1: STLMT10J - Settlement Extract
```
What it does:
1. VSAM00: IDCAMS DELETE/DEFINE - clears VSAM cluster
2. SORT00: DFSORT merges 3 network files (VISA+MC+STAR)
3. MAIN:   Runs STLMT100
   - Reads merged/sorted network transactions
   - Validates network ID, amount, card number
   - WRITEs valid records to VSAM KSDS
   - Counts by network
4. BACKUP: IDCAMS REPRO backs up VSAM to flat file

Input:  SETTLE.NETWORK.VISA.DAILY, MC.DAILY, STAR.DAILY
Output: VSAM loaded (SETTLE.DAILY.TRANS), backup file
```

### Job 2: STLMT20J - Transaction Matching
```
What it does:
1. STEP005: IDCAMS REPRO - copies VSAM to flat file
2. STEP007: SORT - sorts flat file by TXN-ID (pos 21,20)
3. STEP010: SORT - sorts acquirer file by TXN-ID (pos 1,20)
4. STEP020: Runs STLMT200
   - Sequential matching algorithm on two sorted files:
     * STL-TXN-ID = ACQ-TXN-ID → MATCHED
     * STL-TXN-ID < ACQ-TXN-ID → UNMATCHED SETTLEMENT
     * STL-TXN-ID > ACQ-TXN-ID → UNMATCHED ACQUIRER
   - Amount verification for matched records
   - Writes matched/unmatched/mismatch output files

Input:  VSAM (via REPRO+SORT), Acquirer confirmations
Output: Matched file, Unmatched-STL, Unmatched-ACQ files
```

### Job 3: STLMT30J - Reconciliation
```
What it does:
1. VSAM00: IDCAMS DELETE/DEFINE summary cluster
2. MAIN:   Runs STLMT300
   - Reads matched records from STLMT200
   - Accumulates totals by network (VISA/MC/STAR):
     * Transaction count, total amount
     * Purchase vs withdrawal breakdown
   - WRITEs summary to VSAM KSDS
   - Generates reconciliation report

Input:  SETTLE.DAILY.MATCHED
Output: SETTLE.DAILY.SUMMARY (VSAM), Recon report
```

### Job 4: STLMT40J - Final Reports
```
What it does:
1. MAIN:    Runs STLMT400 - Management report + SAS CSV feed
2. EZTRPT:  Runs Easytrieve EZRPT02 - Settlement summary report
3. ARCHIV:  Archives files using IEBGENER

Input:  SETTLE.DAILY.SUMMARY (VSAM)
Output: Management report, SAS feed CSV, Easytrieve report
```

---

## 6. CICS Online Transactions

### PI01 - Card Inquiry
```
1. On 3270 terminal, type: PI01 [ENTER]
2. Empty inquiry screen appears
3. Enter 16-digit card number in CARD NUMBER field
4. Press ENTER
5. Card details populate (name, type, status, balance, limits)
6. Press PF3 to exit

Flow: Terminal → CICS → PIONL100 → DB2 SELECT → BMS SEND → Terminal
```

### PI02 - Card Update
```
1. On 3270 terminal, type: PI02 [ENTER]
2. Empty update screen appears
3. Enter card number, press ENTER
4. Current address and limits populate
5. Modify fields (address, daily limit)
6. Press ENTER to submit update
7. Confirmation message appears
8. Press PF3 to exit

Flow: Terminal → CICS → PIONL200 → DB2 UPDATE → SYNCPOINT → Terminal
```

---

## 7. Common Mainframe Commands

### ISPF Commands
```
ISPF 1     - Browse (view files read-only)
ISPF 2     - Edit (modify files)
ISPF 3.2   - Dataset utilities (allocate, rename, delete)
ISPF 3.4   - Dataset list (search and manage datasets)
ISPF 6     - Command (TSO commands)
```

### SDSF (System Display and Search Facility)
```
ST         - Status of jobs (active)
H          - Held output
O          - Output queue
LOG        - System log
PREFIX     - Filter by job name prefix
OWNER      - Filter by owner
```

### TSO Commands
```
LISTDS 'dataset.name'       - List dataset attributes
ALLOC FILE(DD) DA('dsn')    - Allocate dataset
FREE  FILE(DD)              - Free allocation
SUBMIT 'jcl.pds(member)'    - Submit JCL for execution
STATUS                       - Check job status
```

### IDCAMS Commands
```
DEFINE CLUSTER ...           - Create VSAM file
DELETE 'cluster.name'        - Delete VSAM file
REPRO  INFILE() OUTFILE()   - Copy data between files
LISTCAT ENT('name') ALL     - List catalog entry details
PRINT  INFILE() CHAR        - Print file contents
VERIFY FILE()               - Verify VSAM integrity
```

### DB2 (SPUFI)
```
SELECT * FROM table          - Query data
INSERT INTO table VALUES(...) - Insert row
UPDATE table SET ... WHERE   - Update row
EXPLAIN PLAN FOR ...         - Show access path
```

---

## 8. Troubleshooting Guide

### Common JCL Errors
| Code | Meaning | Fix |
|------|---------|-----|
| JCL ERROR | Syntax error in JCL | Check `//` in column 1, DD names, commas |
| S806 | Program not found | Check STEPLIB, verify program is compiled |
| S0C7 | Data exception | Invalid numeric data — check input file format |
| S0C4 | Protection exception | Subscript out of range, bad pointer |
| S013 | File not found | DD name mismatch or dataset doesn't exist |
| S213 | Dataset not found on volume | Check catalog entry |
| SB37 | Dataset full | Increase SPACE parameter in JCL |
| S322 | Time exceeded | Increase TIME parameter or fix infinite loop |

### Common DB2 SQLCODEs
| SQLCODE | Meaning | Fix |
|---------|---------|-----|
| 0 | Success | No problem |
| +100 | Not found / end of data | Check WHERE clause |
| -803 | Duplicate key on INSERT | Record already exists |
| -811 | SELECT returned more than 1 row | Add more conditions to WHERE |
| -904 | Resource unavailable | Table locked — try later |
| -911 | Deadlock/timeout | Retry the operation |
| -818 | Timestamp mismatch | REBIND the plan |

### Common VSAM Status Codes
| Status | Meaning | Fix |
|--------|---------|-----|
| 00 | Success | OK |
| 02 | Duplicate alternate key | May be expected |
| 22 | Duplicate primary key | Record already exists |
| 23 | Record not found | Check key value |
| 35 | File not found | Define cluster first |
| 39 | File attributes mismatch | Check FD matches cluster definition |
| 46 | Read beyond end of file | Check AT END logic |
| 97 | OPEN failed | Check cluster is defined |

### Common CICS RESP Codes
| RESP | Meaning | Fix |
|------|---------|-----|
| NORMAL | Success | OK |
| MAPFAIL | Map receive failed | User pressed PF key without entering data |
| NOTFND | Record not found | Check key |
| DUPKEY | Duplicate key | Record already exists |
| INVREQ | Invalid request | Check command syntax |
| PGMIDERR | Program not found | CEDA INSTALL the program |

---

## 9. Understanding the Code Flow

### How a Batch COBOL Program Works (PICRD100 Example)

```
PROCEDURE DIVISION.
    0000-MAIN-PROCESS.          ← Entry point
        PERFORM 1000-INITIALIZE ← Open files, set up dates
        PERFORM 2000-PROCESS    ← Read-process-write loop
        PERFORM 3000-SUMMARY    ← Write totals
        PERFORM 9000-TERMINATE  ← Close files, COMMIT/ROLLBACK
        STOP RUN.               ← Return to JCL

    1000-INITIALIZE.
        Open files
        Accept current date
        Write report header

    2000-PROCESS.
        PERFORM UNTIL WS-EOF    ← Loop until end of file
            READ input file
            Validate record
            Process (INSERT/UPDATE)
            Write output
        END-PERFORM

    9000-TERMINATE.
        IF error occurred
            EXEC SQL ROLLBACK    ← Undo all changes
        ELSE
            EXEC SQL COMMIT      ← Save all changes
        END-IF
        Close all files
```

### How a CICS Program Works (PIONL100 Example)

```
PROCEDURE DIVISION.
    0000-MAIN-PROCESS.
        IF EIBCALEN > 0              ← Check if returning from RETURN
            MOVE DFHCOMMAREA TO WS   ← Restore state from COMMAREA
        END-IF

        EVALUATE WS-CA-ACTION
            WHEN spaces (first time)
                Send empty map
                Set action = 'IQ'    ← Next time: process inquiry
            WHEN 'IQ'
                Receive map (get user input)
                Query DB2
                Send map with data
            WHEN 'EX'
                Send goodbye message
                EXEC CICS RETURN     ← End transaction
        END-EVALUATE

        EXEC CICS RETURN
            TRANSID('PI01')          ← Come back as PI01
            COMMAREA(WS-COMMAREA)    ← Save state for next time
        END-EXEC
```

### How the Sequential Matching Algorithm Works (STLMT200)

```
Both files MUST be sorted by the same key (TXN-ID)

    Settlement File (sorted):     Acquirer File (sorted):
    TXN-001  $50.00               TXN-001  $50.00  ── MATCH!
    TXN-003  $75.00               TXN-002  $30.00  ── ACQ unmatched
    TXN-005  $100.00              TXN-003  $75.00  ── MATCH!
    TXN-007  $25.00               TXN-005  $100.00 ── MATCH!
                                  TXN-006  $40.00  ── ACQ unmatched

    Result: TXN-007 is STL unmatched (no acquirer record)

    The algorithm advances ONLY the file with the smaller key.
    This is O(n) — very efficient for millions of records.
```

---

## Quick Reference Card

| Action | Command |
|--------|---------|
| Submit a job | `SUB 'USERID.PAYMENTS.JCL(PICRD10J)'` |
| Check job status | SDSF → ST → find job → S |
| View job output | SDSF → H → find job → S → select DD |
| Edit COBOL source | ISPF 2 → `USERID.PAYMENTS.COBOL(PICRD100)` |
| Run SQL query | ISPF → SPUFI |
| Define VSAM | Submit IDCAMS JCL |
| Compile program | Submit COBCMPL proc |
| Start CICS transaction | Type `PI01` or `PI02` at blank screen |
| Check VSAM | `IDCAMS LISTCAT ENT('cluster.name') ALL` |
