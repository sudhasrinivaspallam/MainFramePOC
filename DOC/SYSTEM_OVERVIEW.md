# System Overview - Payments Division Mainframe POC

## 1. Business Context

The Payments Division operates two core mainframe applications:

1. **Plastic Issuance (PI)** - Debit Card Management System
2. **Settlement** - Transaction Settlement & Reconciliation

Both applications process financial transactions for debit card operations, running on IBM z/OS mainframe infrastructure.

## 2. Application Architecture

### Plastic Issuance (PI)
- **Type**: Batch + Online (CICS)
- **Database**: DB2 for z/OS
- **Processing**: Daily batch cycle for card lifecycle management
- **Online**: CICS transactions for real-time card inquiry and updates
- **Technology**: COBOL, JCL, DB2, CICS/BMS, SORT, Easytrieve

### Settlement
- **Type**: Fully Batch (No Online, No Database)
- **Storage**: VSAM KSDS clusters
- **Processing**: Daily batch cycle for settlement and reconciliation
- **Technology**: COBOL, JCL, VSAM, SORT, Easytrieve, SAS

## 3. Technology Stack

| Component       | Technology            | Purpose                        |
|-----------------|-----------------------|--------------------------------|
| Batch Programs  | COBOL (Enterprise)    | Core business logic            |
| Job Control     | JCL                   | Batch job execution            |
| Database        | DB2 for z/OS          | PI card data storage           |
| File Storage    | VSAM KSDS             | Settlement transaction storage |
| Online          | CICS / BMS            | PI inquiry and update screens  |
| Sorting         | DFSORT / SYNCSORT     | Data sorting and merging       |
| Reporting       | Easytrieve Plus       | Operational reports            |
| Analytics       | SAS                   | Reconciliation analytics       |
| Scheduling      | CA7 Workload Automation| Job scheduling and dependencies|
| Utilities       | IDCAMS, IKJEFT01      | VSAM management, DB2 execution |

## 4. Environment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    z/OS LPAR                                │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Endeavor    │───>│  MF Source   │───>│  Compile/    │  │
│  │   (SCM)      │    │  Code        │    │  Link-Edit   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                  │          │
│         ┌────────────────────────────────────────┘          │
│         v                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  PI Test     │    │  Settlement  │    │  Production  │  │
│  │  Environment │    │  Test Env    │    │  Environment │  │
│  └──────┬───────┘    └──────┬───────┘    └──────────────┘  │
│         │                   │                               │
│         v                   v                               │
│  ┌──────────────┐    ┌──────────────┐                      │
│  │  Test Scripts│    │  Test Scripts│                      │
│  │  (Limited)   │    │  (Limited)   │                      │
│  └──────┬───────┘    └──────┬───────┘                      │
│         │                   │                               │
│         v                   v                               │
│  ┌──────────────────────────────────┐                      │
│  │  Validation & Expected Outputs   │                      │
│  └──────────────────────────────────┘                      │
│                                                             │
│  Developer Access:                                          │
│  ├── Reflection / Virtel (3270 Terminal)                    │
│  ├── ISPF / TSO                                             │
│  ├── IBM Developer for z/OS (IDz)                           │
│  └── Zowe CLI / Explorer                                    │
└─────────────────────────────────────────────────────────────┘
```

## 5. Batch Processing Schedule

### PI Daily Cycle (Mon-Fri, 18:00-22:00)
```
PICRD10J ──> PICRD20J ──> PICRD30J ──> PICRD40J
(Issue)      (Activate)   (Status)     (Renewal)
```

### Settlement Daily Cycle (Mon-Fri, 20:00-03:00)
```
STLMT10J ──> STLMT20J ──> STLMT30J ──> STLMT40J
(Extract)    (Match)      (Reconcile)  (Report)
```

## 6. Data Flow

```
Network Files ──> SORT/Merge ──> STLMT100 ──> VSAM KSDS
                                                  │
Card Requests ──> SORT ──> PICRD100 ──> DB2       │
                                                  │
              STLMT200 (Match) <── VSAM + Acquirer Files
                     │
              STLMT300 (Reconcile) ──> Summary VSAM
                     │
              STLMT400 (Report) ──> Management Reports
                                          │
                                     SAS Analytics
```

## 7. Key Design Decisions

1. **Settlement has no DB2** - Uses VSAM only for simplicity and performance
2. **PI uses DB2** - Relational model for complex card lifecycle queries
3. **Sequential matching** - Sorted TXN-ID merge for settlement matching
4. **Luhn algorithm** - Card number generation with check digit validation
5. **COMMAREA-based CICS** - Pseudo-conversational online model
