import type {
  Address,
  BusinessApplication,
  StepId,
  UserProfile,
} from "../types";

export const USERS: UserProfile[] = [
  {
    id: "USR-RM-100",
    name: "Jordan Lee",
    role: "RELATIONSHIP_MANAGER",
    team: "Commercial Banking East",
  },
  {
    id: "USR-OPS-200",
    name: "Morgan Patel",
    role: "OPERATIONS_ANALYST",
    team: "Client Onboarding Operations",
  },
  {
    id: "USR-APR-300",
    name: "Casey Nguyen",
    role: "APPROVER",
    team: "Business Banking Risk",
  },
  {
    id: "USR-AUD-400",
    name: "Taylor Brooks",
    role: "AUDITOR",
    team: "Compliance Assurance",
  },
];

const emptyAddress = (): Address => ({
  line1: "",
  line2: "",
  city: "",
  state: "",
  postalCode: "",
  country: "United States",
});

const now = () => new Date().toISOString();

export function createEmptyApplication(
  owner: UserProfile,
): BusinessApplication {
  const timestamp = now();
  const id = `BBO-${new Date().getFullYear()}-${Math.floor(
    10000 + Math.random() * 90000,
  )}`;

  return {
    id,
    version: 1,
    status: "DRAFT",
    riskLevel: "LOW",
    ownerId: owner.id,
    ownerName: owner.name,
    createdAt: timestamp,
    updatedAt: timestamp,
    currentStep: "business",
    completedSteps: [],
    business: {
      legalName: "",
      dbaName: "",
      entityType: "",
      taxId: "",
      formationDate: "",
      industry: "",
      website: "",
      registeredAddress: emptyAddress(),
    },
    contact: {
      firstName: "",
      lastName: "",
      title: "",
      email: "",
      phone: "",
    },
    owners: [
      {
        id: crypto.randomUUID(),
        name: "",
        title: "",
        ownershipPercent: 100,
        isController: true,
      },
    ],
    products: {
      products: [],
      expectedBalance: 0,
      monthlyTransactions: 0,
      countries: "United States",
      channels: [],
    },
    compliance: {
      sourceOfFunds: "",
      taxClassification: "",
      pepExposure: "",
      foreignOperations: "",
      highRiskActivity: "",
      notes: "",
    },
    documents: {
      formationDocument: false,
      taxDocument: false,
      ownerIdentification: false,
      bankingResolution: false,
    },
    attestation: false,
    audit: [
      {
        id: crypto.randomUUID(),
        timestamp,
        actor: owner.name,
        action: "Application created",
        detail: "Draft onboarding application started.",
      },
    ],
  };
}

function completedThrough(step: StepId): StepId[] {
  const steps: StepId[] = [
    "business",
    "ownership",
    "products",
    "compliance",
    "documents",
    "review",
  ];
  return steps.slice(0, steps.indexOf(step) + 1);
}

export function seedApplications(): BusinessApplication[] {
  const rm = USERS[0];
  const ops = USERS[1];
  const approver = USERS[2];
  const acme = createEmptyApplication(rm);
  acme.id = "BBO-2026-10482";
  acme.status = "SUBMITTED";
  acme.riskLevel = "MEDIUM";
  acme.version = 7;
  acme.createdAt = "2026-07-08T14:30:00.000Z";
  acme.updatedAt = "2026-07-14T16:42:00.000Z";
  acme.submittedAt = "2026-07-14T16:42:00.000Z";
  acme.currentStep = "review";
  acme.completedSteps = completedThrough("review");
  acme.business = {
    legalName: "Acme Industrial Supply LLC",
    dbaName: "Acme Supply",
    entityType: "Limited Liability Company",
    taxId: "12-3456789",
    formationDate: "2018-04-12",
    industry: "Industrial supplies distribution",
    website: "https://acmesupply.example",
    registeredAddress: {
      line1: "2450 Market Street",
      line2: "Suite 600",
      city: "Philadelphia",
      state: "PA",
      postalCode: "19103",
      country: "United States",
    },
  };
  acme.contact = {
    firstName: "Elena",
    lastName: "Ramirez",
    title: "Chief Financial Officer",
    email: "elena.ramirez@acmesupply.example",
    phone: "(215) 555-0182",
  };
  acme.owners = [
    {
      id: crypto.randomUUID(),
      name: "Elena Ramirez",
      title: "Managing Member",
      ownershipPercent: 60,
      isController: true,
    },
    {
      id: crypto.randomUUID(),
      name: "Daniel Cho",
      title: "Member",
      ownershipPercent: 40,
      isController: false,
    },
  ];
  acme.products = {
    products: ["Business Checking", "Treasury Management"],
    expectedBalance: 650000,
    monthlyTransactions: 1800,
    countries: "United States, Canada",
    channels: ["Online", "ACH", "Wire"],
  };
  acme.compliance = {
    sourceOfFunds: "Operating revenue",
    taxClassification: "Partnership",
    pepExposure: "NO",
    foreignOperations: "YES",
    highRiskActivity: "NO",
    notes: "Canadian suppliers account for approximately 8% of annual payments.",
  };
  acme.documents = {
    formationDocument: true,
    taxDocument: true,
    ownerIdentification: true,
    bankingResolution: true,
  };
  acme.attestation = true;
  acme.audit.push({
    id: crypto.randomUUID(),
    timestamp: acme.submittedAt,
    actor: rm.name,
    action: "Submitted for approval",
    detail: "Application version 7 passed final validation.",
  });

  const northstar = createEmptyApplication(ops);
  northstar.id = "BBO-2026-10397";
  northstar.status = "RETURNED";
  northstar.riskLevel = "HIGH";
  northstar.version = 4;
  northstar.createdAt = "2026-07-05T11:10:00.000Z";
  northstar.updatedAt = "2026-07-13T09:15:00.000Z";
  northstar.currentStep = "compliance";
  northstar.completedSteps = completedThrough("products");
  northstar.returnReason =
    "Provide beneficial-owner identification and clarify foreign operations.";
  northstar.business.legalName = "Northstar Logistics Corporation";
  northstar.business.dbaName = "Northstar Global";
  northstar.business.entityType = "Corporation";
  northstar.business.taxId = "98-7654321";
  northstar.business.industry = "Freight transportation";
  northstar.contact = {
    firstName: "Samir",
    lastName: "Desai",
    title: "Treasurer",
    email: "samir.desai@northstar.example",
    phone: "(312) 555-0174",
  };

  const harbor = createEmptyApplication(rm);
  harbor.id = "BBO-2026-10211";
  harbor.status = "APPROVED";
  harbor.riskLevel = "LOW";
  harbor.version = 9;
  harbor.createdAt = "2026-06-21T10:05:00.000Z";
  harbor.updatedAt = "2026-07-02T15:20:00.000Z";
  harbor.submittedAt = "2026-07-01T13:12:00.000Z";
  harbor.decisionAt = "2026-07-02T15:20:00.000Z";
  harbor.currentStep = "review";
  harbor.completedSteps = completedThrough("review");
  harbor.business.legalName = "Harborview Dental Group PC";
  harbor.business.dbaName = "Harborview Dental";
  harbor.business.entityType = "Professional Corporation";
  harbor.business.taxId = "45-6789012";
  harbor.business.industry = "Dental services";
  harbor.decisionReason = "Standard-risk client; required evidence complete.";
  harbor.audit.push({
    id: crypto.randomUUID(),
    timestamp: harbor.decisionAt,
    actor: approver.name,
    action: "Application approved",
    detail: harbor.decisionReason,
  });

  const bluebird = createEmptyApplication(rm);
  bluebird.id = "BBO-2026-10526";
  bluebird.business.legalName = "Bluebird Creative Studio LLC";
  bluebird.business.dbaName = "Bluebird Studio";
  bluebird.business.entityType = "Limited Liability Company";
  bluebird.currentStep = "ownership";
  bluebird.completedSteps = ["business"];
  bluebird.updatedAt = "2026-07-15T12:06:00.000Z";

  return [acme, northstar, harbor, bluebird];
}
