export type UserRole =
  | "RELATIONSHIP_MANAGER"
  | "OPERATIONS_ANALYST"
  | "APPROVER"
  | "AUDITOR";

export type ApplicationStatus =
  | "DRAFT"
  | "RETURNED"
  | "SUBMITTED"
  | "APPROVED"
  | "REJECTED";

export type RiskLevel = "LOW" | "MEDIUM" | "HIGH";

export type StepId =
  | "business"
  | "ownership"
  | "products"
  | "compliance"
  | "documents"
  | "review";

export interface UserProfile {
  id: string;
  name: string;
  role: UserRole;
  team: string;
}

export interface Address {
  line1: string;
  line2: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
}

export interface BusinessProfile {
  legalName: string;
  dbaName: string;
  entityType: string;
  taxId: string;
  formationDate: string;
  industry: string;
  website: string;
  registeredAddress: Address;
}

export interface Contact {
  firstName: string;
  lastName: string;
  title: string;
  email: string;
  phone: string;
}

export interface BeneficialOwner {
  id: string;
  name: string;
  title: string;
  ownershipPercent: number;
  isController: boolean;
}

export interface ProductSelection {
  products: string[];
  expectedBalance: number;
  monthlyTransactions: number;
  countries: string;
  channels: string[];
}

export interface ComplianceProfile {
  sourceOfFunds: string;
  taxClassification: string;
  pepExposure: "YES" | "NO" | "";
  foreignOperations: "YES" | "NO" | "";
  highRiskActivity: "YES" | "NO" | "";
  notes: string;
}

export interface DocumentChecklist {
  formationDocument: boolean;
  taxDocument: boolean;
  ownerIdentification: boolean;
  bankingResolution: boolean;
}

export interface AuditEvent {
  id: string;
  timestamp: string;
  actor: string;
  action: string;
  detail: string;
}

export interface BusinessApplication {
  id: string;
  version: number;
  status: ApplicationStatus;
  riskLevel: RiskLevel;
  ownerId: string;
  ownerName: string;
  createdAt: string;
  updatedAt: string;
  submittedAt?: string;
  decisionAt?: string;
  currentStep: StepId;
  completedSteps: StepId[];
  returnReason?: string;
  decisionReason?: string;
  business: BusinessProfile;
  contact: Contact;
  owners: BeneficialOwner[];
  products: ProductSelection;
  compliance: ComplianceProfile;
  documents: DocumentChecklist;
  attestation: boolean;
  audit: AuditEvent[];
}

export interface ValidationErrors {
  [field: string]: string;
}
