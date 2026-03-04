# Data Flow Document - Payments Division

## 1. End-to-End Data Flow

```
                    ┌─────────────────┐
                    │  Card Network   │
                    │  (VISA/MC/STAR) │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              v              v              v
     ┌────────────┐ ┌────────────┐ ┌────────────┐
     │ VISA Daily │ │  MC Daily  │ │ STAR Daily │
     │   File     │ │   File     │ │   File     │
     └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
           │              │              │
           └──────────────┼──────────────┘
                          │
                    ┌─────v─────┐
                    │  DFSORT   │
                    │  Merge    │
                    └─────┬─────┘
                          │
                    ┌─────v─────┐
                    │ STLMT100  │ ──> VSAM KSDS
                    │ (Extract) │     (Daily Trans)
                    └─────┬─────┘
                          │
              ┌───────────┴────────────┐
              │                        │
              v                        v
     ┌──────────────┐        ┌──────────────┐
     │  Settlement  │        │  Acquirer    │
     │  File (STL)  │        │  File (ACQ)  │
     └──────┬───────┘        └──────┬───────┘
            │                       │
            └───────────┬───────────┘
                        │
                  ┌─────v─────┐
                  │ STLMT200  │
                  │ (Match)   │
                  └─────┬─────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         v              v              v
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │ Matched  │  │ Unmatched│  │ Unmatched│
   │ Records  │  │   STL    │  │   ACQ    │
   └────┬─────┘  └──────────┘  └──────────┘
        │
  ┌─────v─────┐
  │ STLMT300  │ ──> Summary VSAM
  │ (Recon)   │
  └─────┬─────┘
        │
  ┌─────v─────┐
  │ STLMT400  │ ──> Management Report
  │ (Report)  │ ──> CSV Feed ──> SAS Analytics
  └───────────┘
```

## 2. PI System Data Flow

```
   ┌──────────────┐
   │ Card Request │
   │    File      │
   └──────┬───────┘
          │
    ┌─────v─────┐
    │  DFSORT   │
    │  (Sort)   │
    └─────┬─────┘
          │
    ┌─────v─────┐
    │ PICRD100  │ ──> DB2: TB_CARD_MASTER (INSERT)
    │ (Issue)   │ ──> Report: Issuance Summary
    └─────┬─────┘
          │
    ┌─────v─────┐
    │ PICRD200  │ ──> DB2: TB_CARD_MASTER (UPDATE)
    │ (Activate)│ ──> DB2: TB_CARD_STATUS_HISTORY
    └─────┬─────┘
          │
    ┌─────v─────┐
    │ PICRD300  │ ──> DB2: TB_CARD_MASTER (UPDATE)
    │ (Status)  │ ──> DB2: TB_CARD_STATUS_HISTORY
    └─────┬─────┘
          │
    ┌─────v─────┐
    │ PICRD400  │ ──> DB2: TB_CARD_MASTER (INSERT new)
    │ (Renew)   │ ──> DB2: TB_CARD_MASTER (UPDATE old)
    └───────────┘

   CICS Online:
   ┌──────────────┐     ┌──────────────┐
   │  PIONL100    │────>│    DB2       │
   │  (Inquiry)   │<────│ TB_CARD_     │
   │  Txn: PI01   │     │ MASTER       │
   └──────────────┘     └──────────────┘

   ┌──────────────┐     ┌──────────────┐
   │  PIONL200    │────>│    DB2       │
   │  (Update)    │<────│ TB_CARD_     │
   │  Txn: PI02   │     │ MASTER       │
   └──────────────┘     └──────────────┘
```

## 3. Dataset Inventory

### PI Datasets
| Dataset Name                      | Type    | Description              |
|-----------------------------------|---------|--------------------------|
| PAYMENTS.PI.CARD.REQUESTS         | PS/FB80 | Card issuance requests   |
| PAYMENTS.PI.CARD.ACTIVATE         | PS/FB80 | Activation requests      |
| PAYMENTS.PI.STATUS.CHANGES        | PS/FB80 | Status change requests   |
| PAYMENTS.PI.DAILY.REPORT          | PS/FBA133| Daily processing report |
| PAYMENTS.PI.ERROR.FILE            | PS/FB80 | Error/reject records     |

### Settlement Datasets
| Dataset Name                      | Type      | Description             |
|-----------------------------------|-----------|-------------------------|
| SETTLE.NETWORK.VISA.DAILY        | PS/FB200  | VISA network feed       |
| SETTLE.NETWORK.MC.DAILY          | PS/FB200  | MasterCard network feed |
| SETTLE.NETWORK.STAR.DAILY        | PS/FB200  | STAR network feed       |
| SETTLE.DAILY.TRANS               | VSAM/KSDS| Daily transactions      |
| SETTLE.DAILY.SUMMARY             | VSAM/KSDS| Daily summary           |
| SETTLE.MATCH.OUTPUT              | PS/FB200  | Matched records         |
| SETTLE.UNMATCH.STL               | PS/FB200  | Unmatched settlement    |
| SETTLE.UNMATCH.ACQ               | PS/FB200  | Unmatched acquirer      |
| SETTLE.SAS.FEED                  | PS/CSV    | SAS analytics feed      |
| SETTLE.DAILY.REPORT              | PS/FBA133 | Daily report            |
| SETTLE.MGMT.REPORT              | PS/FBA133 | Management report       |
| SETTLE.HISTORY.ARCHIVE           | VSAM/KSDS| Historical archive      |

## 4. Cross-System Dependencies

```
PI Batch Cycle ────────────────────> Settlement Batch Cycle
(18:00 - 22:00)                     (20:00 - 03:00)
                                          │
                                     Depends on:
                                     1. PI cycle completion
                                     2. Network file availability
                                     3. Acquirer file availability
```

## 5. Reporting Data Flow

```
STLMT400 ──> CSV Feed ──> SASRCN01.sas ──> Analytics Reports
                                            ├── Network Summary
                                            ├── Trend Analysis
                                            └── Exception Report

PICRD100-400 ──> Spool Reports ──> EZRPT01.ezt ──> Card Activity Report

STLMT300 ──> Summary VSAM ──> EZRPT02.ezt ──> Settlement Summary Report
```
