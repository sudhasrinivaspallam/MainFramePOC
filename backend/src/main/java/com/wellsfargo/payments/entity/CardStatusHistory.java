package com.wellsfargo.payments.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * JPA Entity mapping COBOL copybook CPYHIST.cpy / DB2 table CARD_STATUS_HISTORY.
 * Tracks every status change for audit trail - mirrors PICRD300 history writes.
 */
@Entity
@Table(name = "card_status_history", indexes = {
    @Index(name = "idx_hist_card", columnList = "cardNumber")
})
public class CardStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "history_id")
    private Long historyId;

    @Column(name = "card_number", length = 16, nullable = false)
    private String cardNumber;

    @Column(name = "previous_status", length = 2)
    private String previousStatus;

    @Column(name = "new_status", length = 2, nullable = false)
    private String newStatus;

    @Column(name = "reason_code", length = 10)
    private String reasonCode;

    @Column(name = "requestor_id", length = 10)
    private String requestorId;

    @Column(name = "status_date")
    private LocalDate statusDate;

    @Column(name = "created_timestamp")
    private LocalDateTime createdTimestamp;

    @PrePersist
    protected void onCreate() {
        createdTimestamp = LocalDateTime.now();
        if (statusDate == null) statusDate = LocalDate.now();
    }

    public Long getHistoryId() { return historyId; }
    public void setHistoryId(Long historyId) { this.historyId = historyId; }

    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }

    public String getPreviousStatus() { return previousStatus; }
    public void setPreviousStatus(String previousStatus) { this.previousStatus = previousStatus; }

    public String getNewStatus() { return newStatus; }
    public void setNewStatus(String newStatus) { this.newStatus = newStatus; }

    public String getReasonCode() { return reasonCode; }
    public void setReasonCode(String reasonCode) { this.reasonCode = reasonCode; }

    public String getRequestorId() { return requestorId; }
    public void setRequestorId(String requestorId) { this.requestorId = requestorId; }

    public LocalDate getStatusDate() { return statusDate; }
    public void setStatusDate(LocalDate statusDate) { this.statusDate = statusDate; }

    public LocalDateTime getCreatedTimestamp() { return createdTimestamp; }
    public void setCreatedTimestamp(LocalDateTime createdTimestamp) { this.createdTimestamp = createdTimestamp; }
}
