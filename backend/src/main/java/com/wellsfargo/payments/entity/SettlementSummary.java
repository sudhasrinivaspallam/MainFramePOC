package com.wellsfargo.payments.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * JPA Entity mapping DB2 table SETTLEMENT_SUMMARY.
 * Stores aggregated settlement data per network per date - mirrors STLMT300 output.
 */
@Entity
@Table(name = "settlement_summary", indexes = {
    @Index(name = "idx_sum_date", columnList = "settleDate"),
    @Index(name = "idx_sum_network", columnList = "networkId")
})
public class SettlementSummary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "settle_date", nullable = false)
    private LocalDate settleDate;

    @Column(name = "network_id", length = 4, nullable = false)
    private String networkId;

    @Column(name = "total_txn_count")
    private int totalTxnCount;

    @Column(name = "total_txn_amount", precision = 15, scale = 2)
    private BigDecimal totalTxnAmount = BigDecimal.ZERO;

    @Column(name = "matched_count")
    private int matchedCount;

    @Column(name = "matched_amount", precision = 15, scale = 2)
    private BigDecimal matchedAmount = BigDecimal.ZERO;

    @Column(name = "unmatched_count")
    private int unmatchedCount;

    @Column(name = "unmatched_amount", precision = 15, scale = 2)
    private BigDecimal unmatchedAmount = BigDecimal.ZERO;

    @Column(name = "disputed_count")
    private int disputedCount;

    @Column(name = "disputed_amount", precision = 15, scale = 2)
    private BigDecimal disputedAmount = BigDecimal.ZERO;

    @Column(name = "total_fees", precision = 15, scale = 2)
    private BigDecimal totalFees = BigDecimal.ZERO;

    @Column(name = "net_settle_amount", precision = 15, scale = 2)
    private BigDecimal netSettleAmount = BigDecimal.ZERO;

    @Column(name = "recon_status", length = 2)
    private String reconStatus = "PE";

    @Column(name = "created_timestamp")
    private LocalDateTime createdTimestamp;

    @PrePersist
    protected void onCreate() {
        createdTimestamp = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public LocalDate getSettleDate() { return settleDate; }
    public void setSettleDate(LocalDate settleDate) { this.settleDate = settleDate; }

    public String getNetworkId() { return networkId; }
    public void setNetworkId(String networkId) { this.networkId = networkId; }

    public int getTotalTxnCount() { return totalTxnCount; }
    public void setTotalTxnCount(int totalTxnCount) { this.totalTxnCount = totalTxnCount; }

    public BigDecimal getTotalTxnAmount() { return totalTxnAmount; }
    public void setTotalTxnAmount(BigDecimal totalTxnAmount) { this.totalTxnAmount = totalTxnAmount; }

    public int getMatchedCount() { return matchedCount; }
    public void setMatchedCount(int matchedCount) { this.matchedCount = matchedCount; }

    public BigDecimal getMatchedAmount() { return matchedAmount; }
    public void setMatchedAmount(BigDecimal matchedAmount) { this.matchedAmount = matchedAmount; }

    public int getUnmatchedCount() { return unmatchedCount; }
    public void setUnmatchedCount(int unmatchedCount) { this.unmatchedCount = unmatchedCount; }

    public BigDecimal getUnmatchedAmount() { return unmatchedAmount; }
    public void setUnmatchedAmount(BigDecimal unmatchedAmount) { this.unmatchedAmount = unmatchedAmount; }

    public int getDisputedCount() { return disputedCount; }
    public void setDisputedCount(int disputedCount) { this.disputedCount = disputedCount; }

    public BigDecimal getDisputedAmount() { return disputedAmount; }
    public void setDisputedAmount(BigDecimal disputedAmount) { this.disputedAmount = disputedAmount; }

    public BigDecimal getTotalFees() { return totalFees; }
    public void setTotalFees(BigDecimal totalFees) { this.totalFees = totalFees; }

    public BigDecimal getNetSettleAmount() { return netSettleAmount; }
    public void setNetSettleAmount(BigDecimal netSettleAmount) { this.netSettleAmount = netSettleAmount; }

    public String getReconStatus() { return reconStatus; }
    public void setReconStatus(String reconStatus) { this.reconStatus = reconStatus; }

    public LocalDateTime getCreatedTimestamp() { return createdTimestamp; }
    public void setCreatedTimestamp(LocalDateTime createdTimestamp) { this.createdTimestamp = createdTimestamp; }
}
