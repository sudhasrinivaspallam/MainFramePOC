# Mainframe Financial Domain POC
## Payments - Plastic Issuance (PI) & Settlement System

### Application Overview

This project simulates a **real-world mainframe financial domain application** consisting of two major subsystems:

| Subsystem | Type | Online | Database | Key Tech |
|-----------|------|--------|----------|----------|
| **Plastic Issuance (PI)** | Debit Card Management | Yes (CICS) | DB2 | COBOL, JCL, DB2, CICS, VSAM |
| **Settlement** | Transaction Settlement | No | No (VSAM only) | COBOL, JCL, VSAM, SORT, Easytrieve |

---

### Technology Stack

- **COBOL** – Core business logic (batch and online programs)
- **JCL** – Job Control Language for batch execution
- **DB2** – Relational database for PI card management
- **VSAM** – Virtual Storage Access Method for Settlement files
- **CICS** – Online transaction processing for PI
- **SORT/DFSORT** – Data sorting and transformation utilities
- **Easytrieve** – Report generation
- **SAS** – Data analytics and reconciliation
- **CA7** – Batch job scheduling (schedule definitions included)

---

### Project Structure

```
MainFramePOC/
├── COBOL/
│   ├── PI/                        # Plastic Issuance COBOL programs
│   │   ├── PICRD100.cbl          # Card Issuance batch program
│   │   ├── PICRD200.cbl          # Card Activation batch program
│   │   ├── PICRD300.cbl          # Card Status Update batch program
│   │   ├── PICRD400.cbl          # Card Renewal batch program
│   │   ├── PIONL100.cbl          # CICS Online Card Inquiry
│   │   └── PIONL200.cbl          # CICS Online Card Update
│   └── SETTLE/                    # Settlement COBOL programs
│       ├── STLMT100.cbl          # Daily Settlement Extract
│       ├── STLMT200.cbl          # Settlement Matching
│       ├── STLMT300.cbl          # Settlement Reconciliation
│       └── STLMT400.cbl          # Settlement Report Generation
├── COPYBOOK/
│   ├── CPYCRD01.cpy              # Card Master record layout
│   ├── CPYCRD02.cpy              # Card Transaction record layout
│   ├── CPYSTL01.cpy              # Settlement record layout
│   ├── CPYSTL02.cpy              # Settlement summary layout
│   ├── CPYCOM01.cpy              # Common date/time routines
│   └── CPYERR01.cpy              # Common error handling
├── JCL/
│   ├── PI/                        # PI batch JCL
│   │   ├── PICRD10J.jcl          # Card Issuance job
│   │   ├── PICRD20J.jcl          # Card Activation job
│   │   ├── PICRD30J.jcl          # Card Status Update job
│   │   └── PICRD40J.jcl          # Card Renewal job
│   └── SETTLE/                    # Settlement batch JCL
│       ├── STLMT10J.jcl          # Daily Settlement Extract job
│       ├── STLMT20J.jcl          # Settlement Matching job
│       ├── STLMT30J.jcl          # Settlement Reconciliation job
│       └── STLMT40J.jcl          # Settlement Report job
├── DB2/
│   ├── DDL/
│   │   ├── CRTTBL01.sql          # Card Master table
│   │   ├── CRTTBL02.sql          # Card Transaction table
│   │   ├── CRTTBL03.sql          # Card Status History table
│   │   └── CRTIDX01.sql          # Index definitions
│   └── DML/
│       ├── INSCRD01.sql          # Insert sample card data
│       └── QRYCRD01.sql          # Common query patterns
├── VSAM/
│   ├── DEFCLS01.ams              # VSAM cluster definitions
│   ├── DEFALT01.ams              # Alternate index definitions
│   └── REPRO01.ams               # VSAM load utilities
├── SORT/
│   ├── SRTCRD01.srt              # Sort card transactions
│   ├── SRTSTL01.srt              # Sort settlement records
│   └── SRTRPT01.srt              # Sort for reporting
├── EASYTRIEVE/
│   ├── EZRPT01.ezt               # Card Activity Report
│   └── EZRPT02.ezt               # Settlement Summary Report
├── SAS/
│   ├── SASRCN01.sas              # Reconciliation analytics
│   └── SASRPT01.sas              # Management dashboard data
├── PROC/
│   ├── COBCMPL.prc               # COBOL compile procedure
│   └── DB2BIND.prc               # DB2 bind procedure
├── SCHEDULE/
│   └── CA7SCHED.txt              # CA7 job scheduling definitions
├── BMS/
│   ├── PISCR01.bms               # CICS Card Inquiry screen map
│   └── PISCR02.bms               # CICS Card Update screen map
├── TEST/
│   ├── PI/
│   │   ├── TESTDATA/
│   │   │   ├── PI_CARD_INPUT.dat
│   │   │   └── PI_CARD_EXPECTED.dat
│   │   └── TESTCASE/
│   │       ├── TC_PI_001.txt
│   │       └── TC_PI_002.txt
│   └── SETTLE/
│       ├── TESTDATA/
│       │   ├── STL_TXN_INPUT.dat
│       │   └── STL_TXN_EXPECTED.dat
│       └── TESTCASE/
│           ├── TC_STL_001.txt
│           └── TC_STL_002.txt
└── DOC/
    ├── SYSTEM_OVERVIEW.md
    ├── PI_DESIGN.md
    ├── SETTLEMENT_DESIGN.md
    └── DATA_FLOW.md
```

---

### Batch Job Flow

#### PI (Plastic Issuance) Daily Cycle
```
PICRD10J (Card Issuance) → PICRD20J (Activation) → PICRD30J (Status Update) → PICRD40J (Renewal)
```

#### Settlement Daily Cycle
```
STLMT10J (Extract) → STLMT20J (Matching) → STLMT30J (Reconciliation) → STLMT40J (Reporting)
```

---

### Local Execution (GnuCOBOL)

The `LOCAL/` directory contains a fully runnable version of the entire POC adapted for **GnuCOBOL 3.2+ on Windows** (via MSYS2). All DB2 SQL is replaced with COBOL indexed files (KSDS equivalent), and CICS online programs use batch ACCEPT/DISPLAY.

#### Prerequisites

1. **MSYS2** with the `ucrt64` toolchain
2. **GnuCOBOL 3.2+** installed via `pacman -S mingw-w64-ucrt-x86_64-gnucobol`

#### LOCAL Directory Structure

```
LOCAL/
├── COBOL/          # 13 COBOL programs adapted for local execution
│   ├── PILOAD0.cbl     # Test data loader (10 sample cards)
│   ├── GENDATA.cbl     # Generates all test input data files
│   ├── PICRD100.cbl    # Card Issuance (DB2 INSERT → indexed WRITE)
│   ├── PICRD200.cbl    # Card Activation (DB2 UPDATE → READ/REWRITE)
│   ├── PICRD300.cbl    # Status Update + History (indexed files)
│   ├── PICRD400.cbl    # Card Renewal (CURSOR → START/READ NEXT)
│   ├── PIONL100.cbl    # Card Inquiry (CICS → ACCEPT/DISPLAY)
│   ├── PIONL200.cbl    # Card Update (CICS → ACCEPT/DISPLAY)
│   ├── STLMT100.cbl    # Network Extract (validates & loads TXNs)
│   ├── STLSORT.cbl     # VSAM-to-Sequential copy (replaces DFSORT)
│   ├── STLMT200.cbl    # Transaction Matching (two-file merge)
│   ├── STLMT300.cbl    # Net Settlement (network aggregation)
│   └── STLMT400.cbl    # Management Report + SAS CSV feed
├── COPYBOOK/       # 7 copybooks (COMP-3 → display numeric)
├── DATA/           # Runtime data files (created by programs)
├── OUTPUT/         # Reports and output files
├── BIN/            # Compiled executables
├── build.sh        # Compile all 13 programs
└── run.sh          # Execute full end-to-end pipeline
```

#### Build & Run

```bash
# From MSYS2 terminal:
export PATH=/ucrt64/bin:$PATH
export COB_CONFIG_DIR=/ucrt64/share/gnucobol/config
export COB_COPY_DIR=/ucrt64/share/gnucobol/copy
cd /c/Users/<your-user>/source/Repos/MainFramePOC/LOCAL

bash build.sh    # Compiles all 13 programs → BIN/
bash run.sh      # Runs full pipeline end-to-end
```

#### Pipeline Execution Order

```
PILOAD0 → GENDATA → PICRD100 → PICRD200 → PICRD300 → PICRD400
  → PIONL100 → PIONL200 → STLMT100 → STLSORT → STLMT200
  → STLMT300 → STLMT400
```

#### Key Outputs
| File | Description |
|------|-------------|
| OUTPUT/CARDRPT.txt | Card issuance report |
| OUTPUT/ACTVRPT.txt | Activation report |
| OUTPUT/STSRPT.txt | Status change report |
| OUTPUT/RENWRPT.txt | Renewal report |
| OUTPUT/STLRPT.txt | Settlement extract report |
| OUTPUT/STLRPT2.txt | Matching summary report |
| OUTPUT/STLRPT3.txt | Reconciliation report |
| OUTPUT/MGTRPT.txt | Management report (per-network) |
| OUTPUT/SASOUT.csv | SAS-ready CSV feed |

---

### Environment Setup

This POC is designed to be reviewed and understood as a simulation of a mainframe environment. The code follows IBM mainframe standards and conventions and can be deployed to:

- **IBM z/OS** mainframe environment
- **Micro Focus Enterprise Developer** for local development
- **IBM zD&T** (Z Development and Test)
- **Zowe CLI** for remote mainframe interaction
- **GnuCOBOL** for local compilation and testing (see LOCAL/ directory)

---

### Authors
Mainframe Modernization POC Team

### License
Internal Use Only - Financial Domain POC
