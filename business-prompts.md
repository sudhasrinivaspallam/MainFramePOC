# Business-Level Prompts Playbook

A self-contained, copy-paste library of **business-language** prompts for driving
Devin through this demo. Every prompt is written in plain functional language —
no COBOL, copybook, JCL, DB2, VSAM, or file names — so that a business analyst
can hand them to Devin as-is. The engineering artifacts (program names, record
layouts, job chains) are things Devin discovers and produces on its own.

- **Part A** builds the mainframe debit-card platform from a business brief.
- **Part B** migrates that platform to .NET microservices + React + PostgreSQL.

Each prompt sits in a fenced code block, followed by a one-line *Why it works*
caption.

> **Branding note:** The Wells Fargo theme in Part B uses primary red
> `#D71E28` and gold/yellow accent `#FFCD41`. These hex values are
> **approximations** — replace them with the official Wells Fargo brand guide
> values if you have access to it.

---

## Part A — Build the Mainframe Debit-Card Platform

### A.1 — Domain & context brief

```
You are building a debit-card management platform for a retail bank, in the
style of a traditional mainframe batch-and-online system. There are two
business areas:

1. Plastic Issuance — the full life of a debit or prepaid card: issuing new
   cards, activating them, changing their status, and renewing them before
   they expire. Bank agents can also look a card up and update its details in
   real time.
2. Settlement — every day the bank receives transaction files from the card
   networks, matches them against the acquirers' confirmations, reconciles the
   totals, and produces management reports.

Start by proposing the overall shape of the system: the business entities, the
daily processing cycle for each area, and the reports each area produces.
Keep money precise to the cent and keep a full audit trail of every status
change. Do not write code yet — give me the design first.
```
*Why it works:* it frames scope, entities, and guardrails in business terms and asks for a plan first, so Devin aligns on the domain before producing artifacts.

### A.2 — Card lifecycle rules

```
Implement the card lifecycle. A card moves through these states: New →
Active → Blocked → Closed, and a card can also expire. Encode the allowed
transitions (for example, only an Active card can be blocked; a blocked card
can be unblocked back to Active; a card in any live state can be closed) and
reject any transition that is not allowed. Every state change must be written
to an immutable audit history that records the old state, the new state, who
requested it, and when. Show me the transition rules before you build them.
```
*Why it works:* it states the state machine and audit requirement as business rules, letting Devin derive the validation matrix and history records without being told the table names.

### A.3 — Card issuance with checksum validation

```
Build the daily card-issuance process. It reads a batch of new-card requests,
validates each one (account present, customer present, valid card type), and
issues a card number that passes the standard card-number checksum used by the
payments industry. If a request is invalid or a card number collides, do not
fail the whole run — reject just that record, write it to a reject report with
the reason, and keep processing the rest. At the end, print a summary with the
counts of records read, cards issued, and records rejected.
```
*Why it works:* "standard card-number checksum" points Devin at the Luhn algorithm without naming it, and "reject-and-report, don't fail the run" captures the batch-resilience rule precisely.

### A.4 — Online inquiry screen

```
Add an online inquiry function a bank agent uses to look up a single card by
its number and immediately see the customer, the card type, the current status,
the balance, the daily limit, and the key dates. Show the status using plain
words a customer-service agent would understand (for example "Active",
"Blocked", "Closed") rather than internal codes. The screen should let the
agent look up one card, read the result, and exit cleanly.
```
*Why it works:* it describes the agent's real-time task and the plain-word status labels, so Devin builds the lookup and the code-to-label translation without being handed the screen layout.

### A.5 — Settlement matching

```
Build the settlement matching process. Each day it takes the bank's settlement
records and the acquirers' confirmation records and matches them by transaction.
For each transaction decide one of three outcomes: matched (found on both sides
with the same amount), disputed (found on both sides but the amounts differ),
or unmatched (present on only one side). The files are large, so use an
efficient approach that does not depend on holding everything in memory at once.
Produce per-network and per-status reconciliation totals.
```
*Why it works:* the matched/disputed/unmatched outcomes and "efficient for large files" nudge Devin toward the sorted-merge algorithm and the per-network/per-status breakdown, all stated as business outcomes.

### A.6 — Daily schedule & dependencies

```
Define the daily schedule that runs these processes in the correct order, with
each step depending on the previous one succeeding. If any step fails, the
downstream steps must not run, and the operations team must be alerted. Lay out
the dependency chain for both business areas and describe what happens on a
failure at each point.
```
*Why it works:* "must not run if the prior step failed" plus "alert ops" is exactly the success-gated dependency behavior a scheduler enforces, expressed without naming the scheduler.

### A.7 — Laptop-runnable demo variant

```
Produce a version of the whole platform that a reviewer can run end-to-end on a
plain laptop with no bank infrastructure — no mainframe, no external database.
Include a small set of realistic sample data and two scripts: one that builds
everything and one that runs the full daily cycle for both business areas from
start to finish, printing the reports at the end. Keep the business logic
identical to the real version so the outputs can be compared.
```
*Why it works:* it asks for a self-contained, runnable demo with sample data and build/run scripts, giving Devin a verifiable target while preserving business-logic parity.

---

## Part B — Migrate to .NET Microservices + React + PostgreSQL

> **Wells Fargo theme requirement (applies to every React/UI prompt below —
> B.1, B.4, B.4a, B.5):** All React screens must follow a Wells Fargo visual
> theme — primary red `#D71E28`, gold/yellow accent `#FFCD41`, a dark-red
> header bar carrying the Wells Fargo logo, clean sans-serif typography, and
> accessible colour contrast. Status values must appear as coloured badges.
> Hex values are approximations; substitute the official Wells Fargo brand
> guide if available. Backend, data, and orchestration prompts (B.2, B.3, B.6,
> B.7) are intentionally left unthemed.

### B.1 — Migration strategy

```
We are modernizing the platform to a modern stack: .NET microservices, a React
web front end, and PostgreSQL. Propose a migration strategy that moves one
business area at a time, runs the old and new systems in parallel, and proves
they produce equivalent results before we retire the old one. The business
rules must not change during the migration — only the technology. For every
React screen in the new system, apply a Wells Fargo visual theme (primary red
#D71E28, gold/yellow accent #FFCD41, a dark-red header bar with the Wells Fargo
logo, clean sans-serif type, and accessible contrast). Give me the phased plan
and how we will demonstrate equivalence at each step.
```
*Why it works:* it sets the incremental, parallel-run, prove-equivalence strategy with unchanged business rules, and attaches the Wells Fargo theme requirement to the UI up front.

### B.2 — Data migration with exact precision *(unthemed)*

```
Migrate the platform's data into PostgreSQL. Money and other exact values must
keep their precision exactly — never store them in a way that can drift, so no
floating-point types for amounts. Preserve every audit-history record. After
loading, verify row counts and totals against the source and report any
difference to the cent.
```
*Why it works:* "never store amounts in a way that can drift / no floating-point" locks in decimal precision, and the count/total verification gives a concrete migration-correctness check.

### B.3 — Batch to background service *(unthemed)*

```
Reimplement the daily batch processes as .NET background services that produce
exactly the same outputs as today. For each process, take the existing outputs
as the reference and prove the new service's outputs match them line for line
on the same input. Keep the same validation, rejection, and summary behavior.
```
*Why it works:* it defines the batch-to-service move with output-equivalence as the acceptance test, reusing the current outputs as the oracle.

### B.4 — Green screen to REST + React

```
Replace the agent's online inquiry and update screens with a stateless REST API
plus a React web UI. Each request must stand on its own — no reliance on
server-side session state between screens. Style the React screens with the
Wells Fargo theme: primary red #D71E28, gold/yellow accent #FFCD41, a dark-red
header bar with the Wells Fargo logo, clean sans-serif typography, and
accessible contrast. Show the card status as a coloured badge (for example
green for Active, red for Blocked, grey for Closed). Keep the same lookup and
update behavior the agents rely on today.
```
*Why it works:* it maps the pseudo-conversational green screen to a stateless REST + React design and pins the Wells Fargo theme plus coloured status badges to the UI.

### B.4a — Reusable Wells Fargo React theme / component library

```
Before building individual screens, create a reusable Wells Fargo design system
for the React app so every screen looks consistent. Include: a ThemeProvider
that centralizes the palette (primary red #D71E28, gold/yellow accent #FFCD41,
dark-red header) and typography; a shared AppHeader component with the Wells
Fargo logo and dark-red bar; and shared Button, Card, Table, and StatusBadge
components that use the theme. Every other screen must be built from these
shared components. Treat the hex values as approximations to be replaced by the
official Wells Fargo brand guide if provided.
```
*Why it works:* it asks for the design-system foundation first (ThemeProvider, AppHeader, Button/Card/Table/StatusBadge), so all later screens inherit one consistent, brand-accurate look.

### B.5 — Settlement service + reconciliation dashboard

```
Move the settlement matching and reconciliation into a .NET service and add a
Wells Fargo-themed React reconciliation dashboard. The dashboard should show,
per network and per status, the counts and totals of matched, disputed, and
unmatched transactions, with clear coloured badges and totals a finance user
can act on. Use the shared Wells Fargo design system (dark-red header with the
logo, primary red #D71E28, gold/yellow accent #FFCD41, accessible contrast).
Prove the numbers equal today's reconciliation output.
```
*Why it works:* it pairs the settlement-to-service move with a themed dashboard built from the shared design system, and keeps equivalence to today's totals as the check.

### B.6 — Schedule to orchestration *(unthemed)*

```
Recreate the daily schedule as a modern orchestration that runs the services in
the same order with the same dependencies: a step only runs if the previous
step succeeded, a failure stops everything downstream, and operations gets
alerted. Preserve the exact success-gated dependency behavior we have today.
```
*Why it works:* it preserves the success-gated dependency semantics when moving from the legacy scheduler to a modern orchestrator, stated purely as behavior.

### B.7 — Continuous equivalence CI gate *(unthemed)*

```
Add a continuous-integration check that acts as a regression oracle: on every
change, it runs both the reference outputs and the new system on the same
sample data and fails the build if any output differs. This gate must stay
green throughout the migration so we always know the new system still matches
the old one.
```
*Why it works:* it turns the parallel-run equivalence idea into an automated CI gate, making "still equivalent" a build-blocking, continuously-enforced guarantee.
