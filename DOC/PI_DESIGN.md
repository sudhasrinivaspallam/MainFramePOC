# Plastic Issuance (PI) - Design Document

## 1. Overview

The Plastic Issuance (PI) system manages the complete lifecycle of debit cards from issuance through expiry/closure. It consists of batch COBOL programs for bulk processing and CICS online transactions for real-time inquiry and updates.

## 2. Program Inventory

| Program   | Type    | Description               | DB2 | CICS |
|-----------|---------|---------------------------|-----|------|
| PICRD100  | Batch   | Card Issuance             | Yes | No   |
| PICRD200  | Batch   | Card Activation           | Yes | No   |
| PICRD300  | Batch   | Card Status Update        | Yes | No   |
| PICRD400  | Batch   | Card Renewal              | Yes | No   |
| PIONL100  | Online  | Card Inquiry              | Yes | Yes  |
| PIONL200  | Online  | Card Update               | Yes | Yes  |

## 3. DB2 Data Model

### TB_CARD_MASTER
Primary table for card information.
- **Key**: CARD_NUMBER (CHAR 16)
- **Status Codes**: NW (New), AC (Active), IN (Inactive), BL (Blocked), EX (Expired), CL (Closed)
- **Card Types**: DB (Debit), PP (Prepaid)

### TB_CARD_TRANSACTION
Transaction history for all card activities.
- **Key**: TXN_ID (CHAR 12)
- **FK**: CARD_NUMBER -> TB_CARD_MASTER

### TB_CARD_STATUS_HISTORY
Audit trail for card status changes.
- **Key**: HISTORY_ID (IDENTITY)
- **FK**: CARD_NUMBER -> TB_CARD_MASTER

## 4. Batch Program Design

### PICRD100 - Card Issuance
```
Input: Card request file (sorted by branch)
Process:
  1. Read input record
  2. Validate card type, branch, customer data
  3. Generate 16-digit card number (Luhn algorithm)
  4. Set initial status = 'NW', limits, dates
  5. INSERT into TB_CARD_MASTER
  6. Write report detail line
  7. Accumulate counts and totals
Output: Report with issuance statistics
```

### PICRD200 - Card Activation
```
Input: Activation request file
Process:
  1. Read activation request
  2. SELECT card from DB2, verify STATUS='NW'
  3. Generate PIN offset (encrypted)
  4. UPDATE STATUS='AC', set activation date
  5. INSERT status change into HISTORY table
Output: Activation report with counts
```

### PICRD300 - Card Status Update
```
Input: Status change request file
Process:
  1. Read status change request
  2. Validate transition matrix:
     AC -> BL (Block)
     AC -> IN (Inactivate)
     BL -> AC (Unblock)
     IN -> AC (Reactivate)
     AC/IN/BL -> CL (Close)
  3. UPDATE card status in DB2
  4. INSERT history record
Output: Status change report
```

### PICRD400 - Card Renewal
```
Input: None (cursor-driven from DB2)
Process:
  1. DECLARE CURSOR for cards expiring in 60 days
  2. FETCH each expiring card
  3. Generate new card number
  4. INSERT new card (STATUS='NW')
  5. UPDATE old card (STATUS='EX')
  6. COMMIT every 100 records
Output: Renewal report with counts
```

## 5. Online Transaction Design

### PIONL100 - Card Inquiry (Transaction PI01)
- **BMS Map**: PISCR01
- **Flow**: Receive card number -> DB2 SELECT -> Display card details
- **Pseudo-conversational**: Uses COMMAREA for state management

### PIONL200 - Card Update (Transaction PI02)
- **BMS Map**: PISCR02
- **Flow**: Display card -> Accept changes -> DB2 UPDATE -> Confirm
- **Updates**: Address, daily limit, monthly limit

## 6. JCL Job Flow

```
PICRD10J (Card Issuance)
  Step 1: SORT - Sort input by card type and branch
  Step 2: MAIN - Execute PICRD100 via IKJEFT01 (DB2)
  Step 3: NOTIFY - Conditional notification
         |
         v
PICRD20J (Card Activation)
  Step 1: MAIN - Execute PICRD200 via IKJEFT01 (DB2)
         |
         v
PICRD30J (Card Status Update)
  Step 1: MAIN - Execute PICRD300 via IKJEFT01 (DB2)
         |
         v
PICRD40J (Card Renewal) - Also runs monthly
  Step 1: MAIN - Execute PICRD400 via IKJEFT01 (DB2)
```

## 7. Error Handling

- All programs check SQLCODE after each DB2 operation
- SQLCODE 0 = Success, +100 = Not found, <0 = Error
- Error records written to error file with reason codes
- Programs set return codes: 0=OK, 4=Warning, 8=Error, 16=Severe
- DB2 ROLLBACK on unrecoverable errors
