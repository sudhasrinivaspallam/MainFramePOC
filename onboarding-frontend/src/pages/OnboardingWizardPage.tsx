import {
  AlertTriangle,
  ArrowLeft,
  ArrowRight,
  Check,
  CheckCircle2,
  Circle,
  FileCheck2,
  Plus,
  Save,
  Trash2,
} from "lucide-react";
import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ErrorSummary } from "../components/ErrorSummary";
import { StatusBadge } from "../components/StatusBadge";
import { canEdit } from "../lib/permissions";
import {
  STEP_ORDER,
  validateApplication,
  validateStep,
} from "../lib/validation";
import { useOnboarding } from "../state/useOnboarding";
import type {
  Address,
  BusinessApplication,
  ComplianceProfile,
  Contact,
  DocumentChecklist,
  ProductSelection,
  StepId,
  ValidationErrors,
} from "../types";

const STEPS: { id: StepId; label: string; description: string }[] = [
  {
    id: "business",
    label: "Business profile",
    description: "Entity, tax, and address information",
  },
  {
    id: "ownership",
    label: "Contacts & ownership",
    description: "Primary contact and controlling persons",
  },
  {
    id: "products",
    label: "Products & activity",
    description: "Services and expected account usage",
  },
  {
    id: "compliance",
    label: "Compliance & tax",
    description: "KYC, tax, and risk questions",
  },
  {
    id: "documents",
    label: "Documents",
    description: "Required evidence and authorizations",
  },
  {
    id: "review",
    label: "Review & submit",
    description: "Validate and send for approval",
  },
];

const entityTypes = [
  "Corporation",
  "Limited Liability Company",
  "Partnership",
  "Professional Corporation",
  "Nonprofit",
  "Sole Proprietorship",
];

const bankingProducts = [
  "Business Checking",
  "Business Savings",
  "Treasury Management",
  "Commercial Card",
  "Merchant Services",
  "Business Line of Credit",
];

function calculateRiskLevel(
  application: BusinessApplication,
): BusinessApplication["riskLevel"] {
  if (application.compliance.highRiskActivity === "YES") return "HIGH";
  if (
    application.compliance.foreignOperations === "YES" ||
    application.products.expectedBalance >= 500000
  ) {
    return "MEDIUM";
  }
  return "LOW";
}

const transactionChannels = ["Online", "ACH", "Wire", "Card", "Check", "Cash"];

function Field({
  id,
  label,
  error,
  hint,
  required,
  children,
}: {
  id: string;
  label: string;
  error?: string;
  hint?: string;
  required?: boolean;
  children: ReactNode;
}) {
  return (
    <div className={`form-field ${error ? "form-field-error" : ""}`} id={id}>
      <label htmlFor={`${id}-input`}>
        {label}
        {required && (
          <span className="required-mark" aria-label="required">
            *
          </span>
        )}
      </label>
      {children}
      {hint && !error && <span className="field-hint">{hint}</span>}
      {error && (
        <span className="field-error" id={`${id}-error`}>
          {error}
        </span>
      )}
    </div>
  );
}

function Question({
  id,
  legend,
  value,
  error,
  onChange,
}: {
  id: string;
  legend: string;
  value: string;
  error?: string;
  onChange: (value: "YES" | "NO") => void;
}) {
  return (
    <fieldset className={`question-field ${error ? "form-field-error" : ""}`} id={id}>
      <legend>
        {legend}
        <span className="required-mark" aria-label="required">
          *
        </span>
      </legend>
      <div className="segmented-options">
        {(["YES", "NO"] as const).map((option) => (
          <label key={option}>
            <input
              type="radio"
              name={id}
              value={option}
              checked={value === option}
              onChange={() => onChange(option)}
            />
            <span>{option === "YES" ? "Yes" : "No"}</span>
          </label>
        ))}
      </div>
      {error && <span className="field-error">{error}</span>}
    </fieldset>
  );
}

export default function OnboardingWizardPage() {
  const { id, step: stepParam } = useParams();
  const navigate = useNavigate();
  const {
    currentUser,
    findApplication,
    saveApplication: persistApplication,
  } = useOnboarding();
  const storedApplication = id ? findApplication(id) : undefined;
  const initialApplication = useRef(storedApplication);
  const [draft, setDraft] = useState<BusinessApplication | undefined>(
    initialApplication.current
      ? structuredClone(initialApplication.current)
      : undefined,
  );
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [saveState, setSaveState] = useState<
    "idle" | "saving" | "saved" | "error"
  >("idle");
  const pageHeadingRef = useRef<HTMLHeadingElement>(null);

  const currentStep = STEP_ORDER.includes(stepParam as StepId)
    ? (stepParam as StepId)
    : "business";
  const stepIndex = STEP_ORDER.indexOf(currentStep);

  useEffect(() => {
    pageHeadingRef.current?.focus();
  }, [currentStep]);

  const editable = draft ? canEdit(currentUser, draft) : false;

  const stepStatus = useMemo(() => {
    if (!draft) return new Map<StepId, "complete" | "current" | "upcoming">();
    return new Map(
      STEP_ORDER.map((step) => [
        step,
        step === currentStep
          ? "current"
          : draft.completedSteps.includes(step)
            ? "complete"
            : "upcoming",
      ]),
    );
  }, [currentStep, draft]);

  if (!draft) {
    return (
      <div className="centered-state">
        <AlertTriangle size={34} aria-hidden="true" />
        <h1>Application not found</h1>
        <p>The requested application is unavailable or may have been removed.</p>
        <Link className="button button-primary" to="/onboarding/inquiry">
          Go to inquiry
        </Link>
      </div>
    );
  }

  if (!editable) {
    return (
      <div className="centered-state">
        <FileCheck2 size={34} aria-hidden="true" />
        <h1>This application is read only</h1>
        <p>
          Application {draft.id} cannot be edited by your current role or in
          its current status.
        </p>
        <Link
          className="button button-primary"
          to={`/onboarding/${draft.id}`}
        >
          View application
        </Link>
      </div>
    );
  }

  const updateDraft = (next: BusinessApplication) => {
    setDraft(next);
    setSaveState("idle");
  };

  const saveDraft = (auditDetail?: string) => {
    setSaveState("saving");
    try {
      const saved = persistApplication(
        { ...draft, riskLevel: calculateRiskLevel(draft) },
        auditDetail,
      );
      setDraft(saved);
      setSaveState("saved");
      window.setTimeout(() => setSaveState("idle"), 2400);
      return saved;
    } catch {
      setSaveState("error");
      return draft;
    }
  };

  const goToStep = (step: StepId) => {
    saveDraft();
    navigate(`/onboarding/${draft.id}/edit/${step}`);
  };

  const continueToNextStep = () => {
    const nextErrors = validateStep(draft, currentStep);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    const completedSteps = draft.completedSteps.includes(currentStep)
      ? draft.completedSteps
      : [...draft.completedSteps, currentStep];
    const nextStep = STEP_ORDER[Math.min(stepIndex + 1, STEP_ORDER.length - 1)];
    const nextDraft = {
      ...draft,
      completedSteps,
      currentStep: nextStep,
      riskLevel: calculateRiskLevel(draft),
    };
    setDraft(nextDraft);
    const saved = persistApplication(
      nextDraft,
      `${STEPS[stepIndex].label} completed`,
    );
    setDraft(saved);
    setErrors({});
    navigate(`/onboarding/${draft.id}/edit/${nextStep}`);
  };

  const goBack = () => {
    if (stepIndex === 0) {
      saveDraft();
      navigate("/onboarding");
      return;
    }
    goToStep(STEP_ORDER[stepIndex - 1]);
  };

  const submitApplication = () => {
    const nextErrors = validateApplication(draft);
    if (Object.keys(nextErrors).length > 0) {
      const firstInvalidStep =
        STEP_ORDER.find(
          (step) => Object.keys(validateStep(draft, step)).length > 0,
        ) ?? "review";
      if (firstInvalidStep !== "review") {
        setErrors({});
        navigate(`/onboarding/${draft.id}/edit/${firstInvalidStep}`);
        return;
      }
      setErrors(nextErrors);
      return;
    }

    const timestamp = new Date().toISOString();
    const submitted: BusinessApplication = {
      ...draft,
      riskLevel: calculateRiskLevel(draft),
      status: "SUBMITTED",
      submittedAt: timestamp,
      updatedAt: timestamp,
      completedSteps: [...STEP_ORDER],
    };
    persistApplication(submitted, "Submitted for approval");
    navigate(`/onboarding/${draft.id}`);
  };

  const updateBusiness = (
    field: keyof BusinessApplication["business"],
    value: string,
  ) => {
    updateDraft({
      ...draft,
      business: { ...draft.business, [field]: value },
    });
  };

  const updateAddress = (field: keyof Address, value: string) => {
    updateDraft({
      ...draft,
      business: {
        ...draft.business,
        registeredAddress: {
          ...draft.business.registeredAddress,
          [field]: value,
        },
      },
    });
  };

  const updateContact = (field: keyof Contact, value: string) => {
    updateDraft({
      ...draft,
      contact: { ...draft.contact, [field]: value },
    });
  };

  const updateProducts = (
    field: keyof ProductSelection,
    value: ProductSelection[keyof ProductSelection],
  ) => {
    updateDraft({
      ...draft,
      products: { ...draft.products, [field]: value },
    });
  };

  const updateCompliance = (
    field: keyof ComplianceProfile,
    value: ComplianceProfile[keyof ComplianceProfile],
  ) => {
    updateDraft({
      ...draft,
      compliance: { ...draft.compliance, [field]: value },
    });
  };

  const updateDocument = (
    field: keyof DocumentChecklist,
    value: boolean,
  ) => {
    updateDraft({
      ...draft,
      documents: { ...draft.documents, [field]: value },
    });
  };

  return (
    <div className="wizard-page">
      <div className="wizard-utility">
        <Link to="/onboarding" className="back-link">
          <ArrowLeft size={16} aria-hidden="true" />
          Dashboard
        </Link>
        <div className="application-identity">
          <span className="mono">{draft.id}</span>
          <StatusBadge status={draft.status} />
        </div>
      </div>

      {draft.status === "RETURNED" && draft.returnReason && (
        <div className="return-banner" role="status">
          <AlertTriangle size={20} aria-hidden="true" />
          <div>
            <strong>Returned for changes</strong>
            <p>{draft.returnReason}</p>
          </div>
        </div>
      )}

      <div className="wizard-layout">
        <aside className="wizard-sidebar" aria-label="Application progress">
          <div className="wizard-sidebar-heading">
            <span className="eyebrow">Application progress</span>
            <strong>
              {draft.business.legalName || "New business application"}
            </strong>
          </div>
          <ol className="wizard-steps">
            {STEPS.map((step, index) => {
              const status = stepStatus.get(step.id);
              const accessible =
                status === "complete" ||
                status === "current" ||
                index <= stepIndex + 1;
              return (
                <li
                  key={step.id}
                  className={`wizard-step wizard-step-${status}`}
                >
                  <button
                    type="button"
                    onClick={() => goToStep(step.id)}
                    disabled={!accessible}
                    aria-current={status === "current" ? "step" : undefined}
                  >
                    <span className="step-marker" aria-hidden="true">
                      {status === "complete" ? (
                        <Check size={15} />
                      ) : status === "current" ? (
                        index + 1
                      ) : (
                        <Circle size={13} />
                      )}
                    </span>
                    <span>
                      <strong>{step.label}</strong>
                      <small>{step.description}</small>
                    </span>
                  </button>
                </li>
              );
            })}
          </ol>
          <div className="save-status" aria-live="polite">
            {saveState === "saving" && "Saving draft…"}
            {saveState === "saved" && (
              <>
                <CheckCircle2 size={15} aria-hidden="true" />
                Draft saved
              </>
            )}
            {saveState === "error" && "Draft save failed. Try again."}
            {saveState === "idle" && `Version ${draft.version}`}
          </div>
        </aside>

        <section className="wizard-content">
          <div className="wizard-heading">
            <span className="step-count">
              Step {stepIndex + 1} of {STEPS.length}
            </span>
            <h1 ref={pageHeadingRef} tabIndex={-1}>
              {STEPS[stepIndex].label}
            </h1>
            <p>{STEPS[stepIndex].description}</p>
          </div>

          <ErrorSummary errors={errors} />

          <div className="wizard-form">
            {currentStep === "business" && (
              <>
                <FormSection
                  title="Legal business information"
                  description="Use the details shown on formation and tax documents."
                >
                  <div className="form-grid">
                    <Field
                      id="legalName"
                      label="Legal business name"
                      required
                      error={errors.legalName}
                    >
                      <input
                        id="legalName-input"
                        value={draft.business.legalName}
                        aria-invalid={Boolean(errors.legalName)}
                        aria-describedby={
                          errors.legalName ? "legalName-error" : undefined
                        }
                        onChange={(event) =>
                          updateBusiness("legalName", event.target.value)
                        }
                      />
                    </Field>
                    <Field id="dbaName" label="Doing business as (optional)">
                      <input
                        id="dbaName-input"
                        value={draft.business.dbaName}
                        onChange={(event) =>
                          updateBusiness("dbaName", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="entityType"
                      label="Entity type"
                      required
                      error={errors.entityType}
                    >
                      <select
                        id="entityType-input"
                        value={draft.business.entityType}
                        onChange={(event) =>
                          updateBusiness("entityType", event.target.value)
                        }
                      >
                        <option value="">Select entity type</option>
                        {entityTypes.map((type) => (
                          <option key={type}>{type}</option>
                        ))}
                      </select>
                    </Field>
                    <Field
                      id="taxId"
                      label="Federal tax ID"
                      required
                      hint="Format: 12-3456789"
                      error={errors.taxId}
                    >
                      <input
                        id="taxId-input"
                        inputMode="numeric"
                        value={draft.business.taxId}
                        onChange={(event) =>
                          updateBusiness("taxId", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="formationDate"
                      label="Formation date"
                      required
                      error={errors.formationDate}
                    >
                      <input
                        id="formationDate-input"
                        type="date"
                        max={new Date().toISOString().split("T")[0]}
                        value={draft.business.formationDate}
                        onChange={(event) =>
                          updateBusiness("formationDate", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="industry"
                      label="Industry / business activity"
                      required
                      error={errors.industry}
                    >
                      <input
                        id="industry-input"
                        value={draft.business.industry}
                        onChange={(event) =>
                          updateBusiness("industry", event.target.value)
                        }
                      />
                    </Field>
                    <Field id="website" label="Business website (optional)">
                      <input
                        id="website-input"
                        type="url"
                        value={draft.business.website}
                        placeholder="https://"
                        onChange={(event) =>
                          updateBusiness("website", event.target.value)
                        }
                      />
                    </Field>
                  </div>
                </FormSection>
                <FormSection
                  title="Registered address"
                  description="Enter the primary legal address for the business."
                >
                  <div className="form-grid">
                    <Field
                      id="addressLine1"
                      label="Address line 1"
                      required
                      error={errors.addressLine1}
                    >
                      <input
                        id="addressLine1-input"
                        value={draft.business.registeredAddress.line1}
                        onChange={(event) =>
                          updateAddress("line1", event.target.value)
                        }
                      />
                    </Field>
                    <Field id="addressLine2" label="Address line 2 (optional)">
                      <input
                        id="addressLine2-input"
                        value={draft.business.registeredAddress.line2}
                        onChange={(event) =>
                          updateAddress("line2", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="city"
                      label="City"
                      required
                      error={errors.city}
                    >
                      <input
                        id="city-input"
                        value={draft.business.registeredAddress.city}
                        onChange={(event) =>
                          updateAddress("city", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="state"
                      label="State"
                      required
                      error={errors.state}
                    >
                      <input
                        id="state-input"
                        maxLength={2}
                        value={draft.business.registeredAddress.state}
                        onChange={(event) =>
                          updateAddress("state", event.target.value.toUpperCase())
                        }
                      />
                    </Field>
                    <Field
                      id="postalCode"
                      label="ZIP code"
                      required
                      error={errors.postalCode}
                    >
                      <input
                        id="postalCode-input"
                        inputMode="numeric"
                        value={draft.business.registeredAddress.postalCode}
                        onChange={(event) =>
                          updateAddress("postalCode", event.target.value)
                        }
                      />
                    </Field>
                  </div>
                </FormSection>
              </>
            )}

            {currentStep === "ownership" && (
              <>
                <FormSection
                  title="Primary business contact"
                  description="This person will receive onboarding communications."
                >
                  <div className="form-grid">
                    <Field
                      id="contactFirstName"
                      label="First name"
                      required
                      error={errors.contactFirstName}
                    >
                      <input
                        id="contactFirstName-input"
                        value={draft.contact.firstName}
                        onChange={(event) =>
                          updateContact("firstName", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="contactLastName"
                      label="Last name"
                      required
                      error={errors.contactLastName}
                    >
                      <input
                        id="contactLastName-input"
                        value={draft.contact.lastName}
                        onChange={(event) =>
                          updateContact("lastName", event.target.value)
                        }
                      />
                    </Field>
                    <Field id="contactTitle" label="Title">
                      <input
                        id="contactTitle-input"
                        value={draft.contact.title}
                        onChange={(event) =>
                          updateContact("title", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="contactEmail"
                      label="Email address"
                      required
                      error={errors.contactEmail}
                    >
                      <input
                        id="contactEmail-input"
                        type="email"
                        value={draft.contact.email}
                        onChange={(event) =>
                          updateContact("email", event.target.value)
                        }
                      />
                    </Field>
                    <Field
                      id="contactPhone"
                      label="Phone number"
                      required
                      error={errors.contactPhone}
                    >
                      <input
                        id="contactPhone-input"
                        type="tel"
                        value={draft.contact.phone}
                        onChange={(event) =>
                          updateContact("phone", event.target.value)
                        }
                      />
                    </Field>
                  </div>
                </FormSection>
                <FormSection
                  title="Beneficial owners"
                  description="List owners and identify at least one controlling person."
                >
                  <div id="owners">
                    {draft.owners.map((owner, index) => (
                      <div className="owner-card" key={owner.id}>
                        <div className="owner-card-heading">
                          <h3>Owner {index + 1}</h3>
                          {draft.owners.length > 1 && (
                            <button
                              type="button"
                              className="icon-text-button danger-text"
                              onClick={() =>
                                updateDraft({
                                  ...draft,
                                  owners: draft.owners.filter(
                                    (item) => item.id !== owner.id,
                                  ),
                                })
                              }
                            >
                              <Trash2 size={15} aria-hidden="true" />
                              Remove
                            </button>
                          )}
                        </div>
                        <div className="form-grid owner-grid">
                          <Field id={`owner-name-${index}`} label="Full name" required>
                            <input
                              id={`owner-name-${index}-input`}
                              value={owner.name}
                              onChange={(event) =>
                                updateDraft({
                                  ...draft,
                                  owners: draft.owners.map((item) =>
                                    item.id === owner.id
                                      ? { ...item, name: event.target.value }
                                      : item,
                                  ),
                                })
                              }
                            />
                          </Field>
                          <Field id={`owner-title-${index}`} label="Title">
                            <input
                              id={`owner-title-${index}-input`}
                              value={owner.title}
                              onChange={(event) =>
                                updateDraft({
                                  ...draft,
                                  owners: draft.owners.map((item) =>
                                    item.id === owner.id
                                      ? { ...item, title: event.target.value }
                                      : item,
                                  ),
                                })
                              }
                            />
                          </Field>
                          <Field
                            id={`owner-percent-${index}`}
                            label="Ownership percentage"
                            required
                          >
                            <div className="input-suffix">
                              <input
                                id={`owner-percent-${index}-input`}
                                type="number"
                                min="0"
                                max="100"
                                value={owner.ownershipPercent}
                                onChange={(event) =>
                                  updateDraft({
                                    ...draft,
                                    owners: draft.owners.map((item) =>
                                      item.id === owner.id
                                        ? {
                                            ...item,
                                            ownershipPercent: Number(
                                              event.target.value,
                                            ),
                                          }
                                        : item,
                                    ),
                                  })
                                }
                              />
                              <span>%</span>
                            </div>
                          </Field>
                          <label className="checkbox-card compact-checkbox">
                            <input
                              type="checkbox"
                              checked={owner.isController}
                              onChange={(event) =>
                                updateDraft({
                                  ...draft,
                                  owners: draft.owners.map((item) =>
                                    item.id === owner.id
                                      ? {
                                          ...item,
                                          isController: event.target.checked,
                                        }
                                      : item,
                                  ),
                                })
                              }
                            />
                            <span>
                              <strong>Controlling person</strong>
                              <small>Has significant management authority</small>
                            </span>
                          </label>
                        </div>
                      </div>
                    ))}
                    {(errors.owners ||
                      errors.ownershipTotal ||
                      errors.controller) && (
                      <div className="field-error owner-errors">
                        {errors.owners ||
                          errors.ownershipTotal ||
                          errors.controller}
                      </div>
                    )}
                    <button
                      type="button"
                      className="button button-tertiary"
                      onClick={() =>
                        updateDraft({
                          ...draft,
                          owners: [
                            ...draft.owners,
                            {
                              id: crypto.randomUUID(),
                              name: "",
                              title: "",
                              ownershipPercent: 0,
                              isController: false,
                            },
                          ],
                        })
                      }
                    >
                      <Plus size={17} aria-hidden="true" />
                      Add beneficial owner
                    </button>
                  </div>
                </FormSection>
              </>
            )}

            {currentStep === "products" && (
              <>
                <FormSection
                  title="Requested products"
                  description="Select every product included in this onboarding request."
                >
                  <div className="checkbox-grid" id="products">
                    {bankingProducts.map((product) => (
                      <label className="checkbox-card" key={product}>
                        <input
                          type="checkbox"
                          checked={draft.products.products.includes(product)}
                          onChange={(event) =>
                            updateProducts(
                              "products",
                              event.target.checked
                                ? [...draft.products.products, product]
                                : draft.products.products.filter(
                                    (item) => item !== product,
                                  ),
                            )
                          }
                        />
                        <span>
                          <strong>{product}</strong>
                          <small>Include in the client relationship</small>
                        </span>
                      </label>
                    ))}
                  </div>
                  {errors.products && (
                    <span className="field-error">{errors.products}</span>
                  )}
                </FormSection>
                <FormSection
                  title="Expected account activity"
                  description="Provide reasonable estimates for risk and service planning."
                >
                  <div className="form-grid">
                    <Field
                      id="expectedBalance"
                      label="Expected average balance"
                      required
                      error={errors.expectedBalance}
                    >
                      <div className="input-prefix">
                        <span>$</span>
                        <input
                          id="expectedBalance-input"
                          type="number"
                          min="0"
                          value={draft.products.expectedBalance || ""}
                          onChange={(event) =>
                            updateProducts(
                              "expectedBalance",
                              Number(event.target.value),
                            )
                          }
                        />
                      </div>
                    </Field>
                    <Field
                      id="monthlyTransactions"
                      label="Monthly transaction count"
                      required
                      error={errors.monthlyTransactions}
                    >
                      <input
                        id="monthlyTransactions-input"
                        type="number"
                        min="0"
                        value={draft.products.monthlyTransactions || ""}
                        onChange={(event) =>
                          updateProducts(
                            "monthlyTransactions",
                            Number(event.target.value),
                          )
                        }
                      />
                    </Field>
                    <Field
                      id="countries"
                      label="Countries of operation"
                      hint="Separate multiple countries with commas."
                    >
                      <input
                        id="countries-input"
                        value={draft.products.countries}
                        onChange={(event) =>
                          updateProducts("countries", event.target.value)
                        }
                      />
                    </Field>
                  </div>
                  <fieldset className="checkbox-fieldset" id="channels">
                    <legend>
                      Expected transaction channels
                      <span className="required-mark" aria-label="required">
                        *
                      </span>
                    </legend>
                    <div className="inline-checkboxes">
                      {transactionChannels.map((channel) => (
                        <label key={channel}>
                          <input
                            type="checkbox"
                            checked={draft.products.channels.includes(channel)}
                            onChange={(event) =>
                              updateProducts(
                                "channels",
                                event.target.checked
                                  ? [...draft.products.channels, channel]
                                  : draft.products.channels.filter(
                                      (item) => item !== channel,
                                    ),
                              )
                            }
                          />
                          {channel}
                        </label>
                      ))}
                    </div>
                    {errors.channels && (
                      <span className="field-error">{errors.channels}</span>
                    )}
                  </fieldset>
                </FormSection>
              </>
            )}

            {currentStep === "compliance" && (
              <>
                <FormSection
                  title="Tax and source of funds"
                  description="These answers support customer identification and due diligence."
                >
                  <div className="form-grid">
                    <Field
                      id="sourceOfFunds"
                      label="Primary source of funds"
                      required
                      error={errors.sourceOfFunds}
                    >
                      <select
                        id="sourceOfFunds-input"
                        value={draft.compliance.sourceOfFunds}
                        onChange={(event) =>
                          updateCompliance("sourceOfFunds", event.target.value)
                        }
                      >
                        <option value="">Select source</option>
                        <option>Operating revenue</option>
                        <option>Investor capital</option>
                        <option>Loan proceeds</option>
                        <option>Donations or grants</option>
                        <option>Asset sale</option>
                      </select>
                    </Field>
                    <Field
                      id="taxClassification"
                      label="Federal tax classification"
                      required
                      error={errors.taxClassification}
                    >
                      <select
                        id="taxClassification-input"
                        value={draft.compliance.taxClassification}
                        onChange={(event) =>
                          updateCompliance(
                            "taxClassification",
                            event.target.value,
                          )
                        }
                      >
                        <option value="">Select classification</option>
                        <option>C Corporation</option>
                        <option>S Corporation</option>
                        <option>Partnership</option>
                        <option>Disregarded entity</option>
                        <option>Tax exempt</option>
                      </select>
                    </Field>
                  </div>
                </FormSection>
                <FormSection
                  title="Risk screening"
                  description="Answer every question. “Yes” responses may require enhanced review."
                >
                  <div className="question-stack">
                    <Question
                      id="pepExposure"
                      legend="Is any owner or controller a politically exposed person?"
                      value={draft.compliance.pepExposure}
                      error={errors.pepExposure}
                      onChange={(value) =>
                        updateCompliance("pepExposure", value)
                      }
                    />
                    <Question
                      id="foreignOperations"
                      legend="Does the business operate or transact outside the United States?"
                      value={draft.compliance.foreignOperations}
                      error={errors.foreignOperations}
                      onChange={(value) =>
                        updateCompliance("foreignOperations", value)
                      }
                    />
                    <Question
                      id="highRiskActivity"
                      legend="Does the business engage in cash-intensive, money service, gambling, or digital asset activity?"
                      value={draft.compliance.highRiskActivity}
                      error={errors.highRiskActivity}
                      onChange={(value) =>
                        updateCompliance("highRiskActivity", value)
                      }
                    />
                  </div>
                  <Field
                    id="complianceNotes"
                    label="Additional context (optional)"
                    hint="Do not enter full identification numbers in notes."
                  >
                    <textarea
                      id="complianceNotes-input"
                      rows={4}
                      value={draft.compliance.notes}
                      onChange={(event) =>
                        updateCompliance("notes", event.target.value)
                      }
                    />
                  </Field>
                </FormSection>
              </>
            )}

            {currentStep === "documents" && (
              <FormSection
                title="Required documents"
                description="This prototype simulates verified document uploads."
              >
                <div className="document-list">
                  {(
                    [
                      [
                        "formationDocument",
                        "Formation document",
                        "Articles of incorporation, organization, or equivalent",
                      ],
                      [
                        "taxDocument",
                        "Tax documentation",
                        "IRS confirmation or current W-9",
                      ],
                      [
                        "ownerIdentification",
                        "Beneficial-owner identification",
                        "Valid identification for each required owner",
                      ],
                      [
                        "bankingResolution",
                        "Banking resolution",
                        "Authorization to establish and operate accounts",
                      ],
                    ] as const
                  ).map(([field, label, description]) => {
                    const checked = draft.documents[field];
                    return (
                      <label
                        className={`document-item ${
                          checked ? "document-complete" : ""
                        }`}
                        key={field}
                        id={field}
                      >
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={(event) =>
                            updateDocument(field, event.target.checked)
                          }
                        />
                        <span className="document-icon">
                          {checked ? (
                            <CheckCircle2 size={21} aria-hidden="true" />
                          ) : (
                            <FileCheck2 size={21} aria-hidden="true" />
                          )}
                        </span>
                        <span className="document-copy">
                          <strong>{label}</strong>
                          <small>{description}</small>
                        </span>
                        <span className="document-action">
                          {checked ? "Verified" : "Mark received"}
                        </span>
                      </label>
                    );
                  })}
                </div>
                {Object.values(errors).length > 0 && (
                  <p className="field-error">
                    Mark every required document as received before continuing.
                  </p>
                )}
                <div className="info-callout">
                  <AlertTriangle size={18} aria-hidden="true" />
                  <p>
                    Production implementation should use encrypted upload,
                    malware scanning, document classification, and retention
                    controls. No files are uploaded in this demonstration.
                  </p>
                </div>
              </FormSection>
            )}

            {currentStep === "review" && (
              <>
                <ReviewSections application={draft} onEdit={goToStep} />
                <FormSection
                  title="Attestation"
                  description="Confirm the application before sending it to an approver."
                >
                  <label
                    className={`attestation-card ${
                      errors.attestation ? "form-field-error" : ""
                    }`}
                    id="attestation"
                  >
                    <input
                      type="checkbox"
                      checked={draft.attestation}
                      onChange={(event) =>
                        updateDraft({
                          ...draft,
                          attestation: event.target.checked,
                        })
                      }
                    />
                    <span>
                      I confirm that I reviewed this application and that the
                      information provided is complete and supported by the
                      required evidence.
                    </span>
                  </label>
                  {errors.attestation && (
                    <span className="field-error">{errors.attestation}</span>
                  )}
                  <div className="maker-checker-note">
                    <FileCheck2 size={19} aria-hidden="true" />
                    After submission, this version becomes read only and must
                    be decided by an authorized approver.
                  </div>
                </FormSection>
              </>
            )}
          </div>

          <div className="wizard-actions">
            <button
              type="button"
              className="button button-secondary"
              onClick={goBack}
            >
              <ArrowLeft size={17} aria-hidden="true" />
              {stepIndex === 0 ? "Save and exit" : "Back"}
            </button>
            <div>
              <button
                type="button"
                className="button button-tertiary"
                onClick={() => saveDraft("Draft manually saved")}
              >
                <Save size={17} aria-hidden="true" />
                Save draft
              </button>
              {currentStep === "review" ? (
                <button
                  type="button"
                  className="button button-primary"
                  onClick={submitApplication}
                >
                  Submit for approval
                  <ArrowRight size={17} aria-hidden="true" />
                </button>
              ) : (
                <button
                  type="button"
                  className="button button-primary"
                  onClick={continueToNextStep}
                >
                  Save and continue
                  <ArrowRight size={17} aria-hidden="true" />
                </button>
              )}
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

function FormSection({
  title,
  description,
  children,
}: {
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <section className="form-section">
      <div className="form-section-heading">
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      <div className="form-section-body">{children}</div>
    </section>
  );
}

function ReviewSections({
  application,
  onEdit,
}: {
  application: BusinessApplication;
  onEdit: (step: StepId) => void;
}) {
  const sections: {
    step: StepId;
    title: string;
    details: string[];
  }[] = [
    {
      step: "business",
      title: "Business profile",
      details: [
        application.business.legalName || "Legal name missing",
        application.business.entityType || "Entity type missing",
        application.business.taxId || "Tax ID missing",
        [
          application.business.registeredAddress.city,
          application.business.registeredAddress.state,
        ]
          .filter(Boolean)
          .join(", ") || "Address incomplete",
      ],
    },
    {
      step: "ownership",
      title: "Contacts and ownership",
      details: [
        `${application.contact.firstName} ${application.contact.lastName}`.trim() ||
          "Primary contact missing",
        application.contact.email || "Email missing",
        `${application.owners.length} beneficial owner${
          application.owners.length === 1 ? "" : "s"
        }`,
        `${application.owners.reduce(
          (sum, owner) => sum + Number(owner.ownershipPercent),
          0,
        )}% ownership documented`,
      ],
    },
    {
      step: "products",
      title: "Products and activity",
      details: [
        application.products.products.join(", ") || "No products selected",
        `${application.products.monthlyTransactions.toLocaleString()} monthly transactions`,
        application.products.channels.join(", ") || "Channels missing",
      ],
    },
    {
      step: "compliance",
      title: "Compliance and tax",
      details: [
        application.compliance.sourceOfFunds || "Source of funds missing",
        application.compliance.taxClassification ||
          "Tax classification missing",
        `Foreign operations: ${
          application.compliance.foreignOperations || "Not answered"
        }`,
        `High-risk activity: ${
          application.compliance.highRiskActivity || "Not answered"
        }`,
      ],
    },
    {
      step: "documents",
      title: "Documents",
      details: [
        `${
          Object.values(application.documents).filter(Boolean).length
        } of 4 required documents verified`,
      ],
    },
  ];

  return (
    <div className="review-section-list">
      {sections.map((section) => {
        const sectionErrors = validateStep(application, section.step);
        const complete = Object.keys(sectionErrors).length === 0;
        return (
          <section className="review-section-card" key={section.step}>
            <div className="review-section-heading">
              <span
                className={`review-status ${complete ? "complete" : "attention"}`}
              >
                {complete ? (
                  <CheckCircle2 size={18} aria-hidden="true" />
                ) : (
                  <AlertTriangle size={18} aria-hidden="true" />
                )}
              </span>
              <div>
                <h2>{section.title}</h2>
                <span>{complete ? "Complete" : "Needs attention"}</span>
              </div>
              <button
                type="button"
                className="text-link"
                onClick={() => onEdit(section.step)}
              >
                Edit
              </button>
            </div>
            <ul>
              {section.details.map((detail) => (
                <li key={detail}>{detail}</li>
              ))}
            </ul>
          </section>
        );
      })}
    </div>
  );
}
