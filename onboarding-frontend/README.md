# Business Banking Onboarding Portal

React 18 and TypeScript prototype that replaces a conversational CICS/BMS onboarding flow with a guided, role-based web experience.

## Included workflows

- Six-step onboarding wizard with validation and versioned draft saves
- Business profile, contacts, beneficial ownership, products, compliance, and document collection
- Review and submission with maker-checker separation
- Approver queue with approve, return, and reject decisions
- Application inquiry, filters, sensitive-data masking, and audit timeline
- Relationship Manager, Operations Analyst, Approver, and Auditor demo roles
- LocalStorage persistence and resettable sample data
- Accessible error summaries, focus handling, semantic forms, keyboard operation, and responsive layouts

## Run locally

```bash
npm install
npm run dev
```

Vite serves the portal at `http://localhost:5173` by default.

## Validate

```bash
npm run lint
npm run build
```

## Demo roles

Use the role selector in the header:

- **Jordan Lee — Relationship Manager:** create, edit, and submit owned drafts
- **Morgan Patel — Operations Analyst:** create and edit operational drafts
- **Casey Nguyen — Approver:** review submitted applications and make decisions
- **Taylor Brooks — Auditor:** read-only inquiry with masked tax identifiers

The prototype is frontend-only. LocalStorage simulates persistence and the document step records checklist completion without uploading files.
