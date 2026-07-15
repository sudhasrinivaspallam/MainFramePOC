import type {
  BusinessApplication,
  StepId,
  ValidationErrors,
} from "../types";

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const taxIdPattern = /^\d{2}-\d{7}$/;

export const STEP_ORDER: StepId[] = [
  "business",
  "ownership",
  "products",
  "compliance",
  "documents",
  "review",
];

export function validateStep(
  application: BusinessApplication,
  step: StepId,
): ValidationErrors {
  const errors: ValidationErrors = {};

  if (step === "business") {
    if (!application.business.legalName.trim()) {
      errors.legalName = "Legal business name is required.";
    }
    if (!application.business.entityType) {
      errors.entityType = "Select an entity type.";
    }
    if (!taxIdPattern.test(application.business.taxId)) {
      errors.taxId = "Enter the tax ID as 12-3456789.";
    }
    if (!application.business.formationDate) {
      errors.formationDate = "Formation date is required.";
    }
    if (!application.business.industry.trim()) {
      errors.industry = "Industry description is required.";
    }
    const address = application.business.registeredAddress;
    if (!address.line1.trim()) errors.addressLine1 = "Address is required.";
    if (!address.city.trim()) errors.city = "City is required.";
    if (!address.state.trim()) errors.state = "State is required.";
    if (!/^\d{5}(-\d{4})?$/.test(address.postalCode)) {
      errors.postalCode = "Enter a valid US ZIP code.";
    }
  }

  if (step === "ownership") {
    if (!application.contact.firstName.trim()) {
      errors.contactFirstName = "Primary contact first name is required.";
    }
    if (!application.contact.lastName.trim()) {
      errors.contactLastName = "Primary contact last name is required.";
    }
    if (!emailPattern.test(application.contact.email)) {
      errors.contactEmail = "Enter a valid email address.";
    }
    if (!application.contact.phone.trim()) {
      errors.contactPhone = "Phone number is required.";
    }
    if (application.owners.some((owner) => !owner.name.trim())) {
      errors.owners = "Each beneficial owner must have a name.";
    }
    const total = application.owners.reduce(
      (sum, owner) => sum + Number(owner.ownershipPercent || 0),
      0,
    );
    if (total !== 100) {
      errors.ownershipTotal = `Ownership must total 100%; current total is ${total}%.`;
    }
    if (!application.owners.some((owner) => owner.isController)) {
      errors.controller = "Identify at least one controlling person.";
    }
  }

  if (step === "products") {
    if (application.products.products.length === 0) {
      errors.products = "Select at least one banking product.";
    }
    if (application.products.expectedBalance <= 0) {
      errors.expectedBalance = "Expected balance must be greater than zero.";
    }
    if (application.products.monthlyTransactions <= 0) {
      errors.monthlyTransactions =
        "Expected monthly transactions must be greater than zero.";
    }
    if (application.products.channels.length === 0) {
      errors.channels = "Select at least one transaction channel.";
    }
  }

  if (step === "compliance") {
    if (!application.compliance.sourceOfFunds) {
      errors.sourceOfFunds = "Source of funds is required.";
    }
    if (!application.compliance.taxClassification) {
      errors.taxClassification = "Tax classification is required.";
    }
    if (!application.compliance.pepExposure) {
      errors.pepExposure = "Answer the politically exposed person question.";
    }
    if (!application.compliance.foreignOperations) {
      errors.foreignOperations = "Answer the foreign operations question.";
    }
    if (!application.compliance.highRiskActivity) {
      errors.highRiskActivity = "Answer the high-risk activity question.";
    }
  }

  if (step === "documents") {
    const documents = application.documents;
    if (!documents.formationDocument) {
      errors.formationDocument = "Formation document is required.";
    }
    if (!documents.taxDocument) {
      errors.taxDocument = "Tax documentation is required.";
    }
    if (!documents.ownerIdentification) {
      errors.ownerIdentification = "Owner identification is required.";
    }
    if (!documents.bankingResolution) {
      errors.bankingResolution = "Banking resolution is required.";
    }
  }

  if (step === "review" && !application.attestation) {
    errors.attestation = "Confirm the attestation before submission.";
  }

  return errors;
}

export function validateApplication(
  application: BusinessApplication,
): ValidationErrors {
  return STEP_ORDER.reduce(
    (allErrors, step) => ({
      ...allErrors,
      ...validateStep(application, step),
    }),
    {},
  );
}
