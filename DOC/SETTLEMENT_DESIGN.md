# Settlement Application - Design Document

## 1. Overview

The Settlement application is a **fully batch** system with **no online components** and **no database**. All data is stored in VSAM KSDS clusters. The system processes daily settlement transactions from card networks (VISA, MasterCard, STAR), matches them against acquirer records, performs reconciliation, and generates management reports.

## 2. Program Inventory

| Program   | Type  | Description               | VSAM | DB2 | CICS |
|-----------|-------|---------------------------|------|-----|------|
| STLMT100  | Batch | Daily Settlement Extract  | Yes  | No  | No   |
| STLMT200  | Batch | Transaction Matching      | Yes  | No  | No   |
| STLMT300  | Batch | Reconciliation            | Yes  | No  | No   |
| STLMT400  | Batch | Final Reporting           | Yes  | No  | No   |

## 3. VSAM Data Model

### SETTLE.DAILY.TRANS (KSDS)
- **Key**: TXN-ID (Position 1, Length 12)
- **Record Size**: Average 200, Max 250
- **CI Size**: 4096
- **Purpose**: Daily settlement transaction storage

### SETTLE.DAILY.SUMMARY (KSDS)
- **Key**: Network-ID + Date (Position 1, Length 12)
- **Record Size**: Average 150, Max 200
- **Purpose**: Daily reconciliation summary by network

### SETTLE.HISTORY.ARCHIVE (KSDS)
- **Key**: Archive-Key (Position 1, Length 20)
- **Record Size**: Average 200, Max 250
- **Purpose**: Historical archive for audit trail

### Alternate Indexes
- **SETTLE.DAILY.TRANS.AIX.CARD** - By card number (non-unique)
- **SETTLE.DAILY.TRANS.AIX.NET** - By network ID (non-unique)

## 4. Batch Program Design

### STLMT100 - Daily Settlement Extract
```
Input: Network transaction files (VISA, MC, STAR) - merged by SORT
Process:
  1. Read merged/sorted transaction record
  2. Validate network ID, amount, card number
  3. Check for duplicates via VSAM READ
  4. WRITE record to VSAM KSDS
  5. Accumulate counts by network
  6. Write detail to report
Output: VSAM KSDS loaded, summary report
```

### STLMT200 - Transaction Matching
```
Input: Settlement VSAM + Acquirer file (sorted by TXN-ID)
Process:
  Sequential matching algorithm:
  1. Read next settlement record (STL)
  2. Read next acquirer record (ACQ)
  3. Compare TXN-IDs:
     - STL < ACQ: Unmatched settlement, write to UNMATCHED-STL
     - STL > ACQ: Unmatched acquirer, write to UNMATCHED-ACQ
     - STL = ACQ: Compare amounts
       - Amounts match: Write to MATCHED output
       - Amounts differ: Write to MISMATCH output
  4. Continue until both files exhausted
Output: Matched, Unmatched-STL, Unmatched-ACQ, Mismatch files
```

### STLMT300 - Reconciliation
```
Input: Matched records from STLMT200
Process:
  1. Read each matched record
  2. Accumulate totals by network:
     - Transaction count
     - Total amount
     - Purchase vs withdrawal breakdown
  3. Calculate reconciliation status
  4. WRITE summary to VSAM KSDS
  5. Generate reconciliation report
Output: Summary VSAM, reconciliation report
```

### STLMT400 - Final Reporting
```
Input: Summary VSAM, matched/unmatched files
Process:
  1. Read summary VSAM records
  2. Format management report with:
     - Network-level totals
     - Match rate percentages
     - Exception counts
  3. Calculate grand totals
  4. Generate CSV feed for SAS analytics
Output: Management report, SAS feed file
```

## 5. JCL Job Flow

```
STLMT10J (Daily Extract)
  Step 1: VSAM00 - IDCAMS DELETE/DEFINE VSAM cluster
  Step 2: SORT00 - DFSORT merge of 3 network files
  Step 3: MAIN   - Execute STLMT100
  Step 4: BACKUP - IDCAMS REPRO to backup dataset
         |
         v
STLMT20J (Transaction Matching)
  Step 1: SORT00 - Sort acquirer file by TXN-ID
  Step 2: MAIN   - Execute STLMT200
         |
         v
STLMT30J (Reconciliation)
  Step 1: VSAM00 - IDCAMS DELETE/DEFINE summary cluster
  Step 2: MAIN   - Execute STLMT300
         |
         v
STLMT40J (Final Reports)
  Step 1: MAIN   - Execute STLMT400
  Step 2: EZTRPT - Easytrieve summary report (EZRPT02)
  Step 3: ARCHIV - Archive settlement files via IEBGENER
```

## 6. File Layout

### Settlement Transaction Record (200 bytes)
```
Position  Length  Field               Format
001-004   4      Network ID          CHAR (VISA/MC/STAR)
005-012   8      Transaction Date    CHAR (YYYYMMDD)
013-024   12     Transaction ID      CHAR
025-040   16     Card Number         CHAR
041-051   11     Transaction Amount  9(9)V99
052-053   2      Transaction Type    CHAR (PU/AW/RF)
054-055   2      Response Code       CHAR
056-064   9      Merchant ID         CHAR
065-066   2      Settlement Status   CHAR (PE/MT/UM/ST)
067-200   134    Filler/Reserved     CHAR
```

## 7. Error Handling

- VSAM status codes checked after every I/O operation
- Status 00 = Success, 02 = Duplicate alt key, 23 = Not found
- Non-zero status: Write error detail, increment error counter
- Programs set return codes: 0=OK, 4=Warning, 8=Error
- No ROLLBACK capability (no DB2); restart requires VSAM redefine
