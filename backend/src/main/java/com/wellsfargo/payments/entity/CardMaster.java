package com.wellsfargo.payments.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * JPA Entity mapping COBOL copybook CPYCARD.cpy / DB2 table CARD_MASTER.
 * Mirrors the 28-column card master record from mainframe DB2.
 */
@Entity
@Table(name = "card_master", indexes = {
    @Index(name = "idx_card_customer", columnList = "customerId"),
    @Index(name = "idx_card_account", columnList = "accountNumber"),
    @Index(name = "idx_card_status", columnList = "cardStatus")
})
public class CardMaster {

    @Id
    @Column(name = "card_number", length = 16)
    private String cardNumber;

    @Column(name = "card_type", length = 2, nullable = false)
    private String cardType;

    @Column(name = "account_number", length = 12, nullable = false)
    private String accountNumber;

    @Column(name = "customer_id", length = 10, nullable = false)
    private String customerId;

    @Column(name = "first_name", length = 25, nullable = false)
    private String firstName;

    @Column(name = "last_name", length = 25, nullable = false)
    private String lastName;

    @Column(name = "addr_line1", length = 40)
    private String addrLine1;

    @Column(name = "addr_line2", length = 40)
    private String addrLine2;

    @Column(name = "city", length = 25)
    private String city;

    @Column(name = "state", length = 2)
    private String state;

    @Column(name = "zip_code", length = 10)
    private String zipCode;

    @Column(name = "card_status", length = 2, nullable = false)
    private String cardStatus = "NW";

    @Column(name = "issue_date")
    private LocalDate issueDate;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "activation_date")
    private LocalDate activationDate;

    @Column(name = "last_used_date")
    private LocalDate lastUsedDate;

    @Column(name = "daily_limit", precision = 15, scale = 2)
    private BigDecimal dailyLimit = BigDecimal.ZERO;

    @Column(name = "available_balance", precision = 15, scale = 2)
    private BigDecimal availableBalance = BigDecimal.ZERO;

    @Column(name = "pin_offset", length = 4)
    private String pinOffset;

    @Column(name = "cvv_value", length = 3)
    private String cvvValue;

    @Column(name = "branch_code", length = 6)
    private String branchCode;

    @Column(name = "created_timestamp")
    private LocalDateTime createdTimestamp;

    @Column(name = "updated_timestamp")
    private LocalDateTime updatedTimestamp;

    @PrePersist
    protected void onCreate() {
        createdTimestamp = LocalDateTime.now();
        updatedTimestamp = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedTimestamp = LocalDateTime.now();
    }

    // Getters and Setters
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }

    public String getCardType() { return cardType; }
    public void setCardType(String cardType) { this.cardType = cardType; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getAddrLine1() { return addrLine1; }
    public void setAddrLine1(String addrLine1) { this.addrLine1 = addrLine1; }

    public String getAddrLine2() { return addrLine2; }
    public void setAddrLine2(String addrLine2) { this.addrLine2 = addrLine2; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getState() { return state; }
    public void setState(String state) { this.state = state; }

    public String getZipCode() { return zipCode; }
    public void setZipCode(String zipCode) { this.zipCode = zipCode; }

    public String getCardStatus() { return cardStatus; }
    public void setCardStatus(String cardStatus) { this.cardStatus = cardStatus; }

    public LocalDate getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDate issueDate) { this.issueDate = issueDate; }

    public LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(LocalDate expiryDate) { this.expiryDate = expiryDate; }

    public LocalDate getActivationDate() { return activationDate; }
    public void setActivationDate(LocalDate activationDate) { this.activationDate = activationDate; }

    public LocalDate getLastUsedDate() { return lastUsedDate; }
    public void setLastUsedDate(LocalDate lastUsedDate) { this.lastUsedDate = lastUsedDate; }

    public BigDecimal getDailyLimit() { return dailyLimit; }
    public void setDailyLimit(BigDecimal dailyLimit) { this.dailyLimit = dailyLimit; }

    public BigDecimal getAvailableBalance() { return availableBalance; }
    public void setAvailableBalance(BigDecimal availableBalance) { this.availableBalance = availableBalance; }

    public String getPinOffset() { return pinOffset; }
    public void setPinOffset(String pinOffset) { this.pinOffset = pinOffset; }

    public String getCvvValue() { return cvvValue; }
    public void setCvvValue(String cvvValue) { this.cvvValue = cvvValue; }

    public String getBranchCode() { return branchCode; }
    public void setBranchCode(String branchCode) { this.branchCode = branchCode; }

    public LocalDateTime getCreatedTimestamp() { return createdTimestamp; }
    public void setCreatedTimestamp(LocalDateTime createdTimestamp) { this.createdTimestamp = createdTimestamp; }

    public LocalDateTime getUpdatedTimestamp() { return updatedTimestamp; }
    public void setUpdatedTimestamp(LocalDateTime updatedTimestamp) { this.updatedTimestamp = updatedTimestamp; }
}
