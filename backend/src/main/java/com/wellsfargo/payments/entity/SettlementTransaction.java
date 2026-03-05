package com.wellsfargo.payments.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * JPA Entity mapping COBOL copybook CPYSTL.cpy / DB2 table SETTLEMENT_TRANSACTION.
 * Mirrors the 18-column settlement transaction record from mainframe.
 */
@Entity
@Table(name = "settlement_transaction", indexes = {
    @Index(name = "idx_stl_txn", columnList = "txnId"),
    @Index(name = "idx_stl_status", columnList = "settleStatus"),
    @Index(name = "idx_stl_network", columnList = "networkId"),
    @Index(name = "idx_stl_date", columnList = "settleDate")
})
public class SettlementTransaction {

    @Id
    @Column(name = "settle_id", length = 20)
    private String settleId;

    @Column(name = "txn_id", length = 20, nullable = false)
    private String txnId;

    @Column(name = "card_number", length = 16, nullable = false)
    private String cardNumber;

    @Column(name = "account_number", length = 12)
    private String accountNumber;

    @Column(name = "txn_type", length = 2)
    private String txnType;

    @Column(name = "txn_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal txnAmount;

    @Column(name = "txn_date")
    private LocalDate txnDate;

    @Column(name = "merchant_id", length = 15)
    private String merchantId;

    @Column(name = "merchant_name", length = 40)
    private String merchantName;

    @Column(name = "acquirer_id", length = 11)
    private String acquirerId;

    @Column(name = "issuer_id", length = 11)
    private String issuerId;

    @Column(name = "network_id", length = 4, nullable = false)
    private String networkId;

    @Column(name = "interchange_fee", precision = 15, scale = 2)
    private BigDecimal interchangeFee = BigDecimal.ZERO;

    @Column(name = "settle_status", length = 2, nullable = false)
    private String settleStatus = "PE";

    @Column(name = "settle_date")
    private LocalDate settleDate;

    @Column(name = "batch_seq_num")
    private Integer batchSeqNum;

    @Column(name = "created_timestamp")
    private LocalDateTime createdTimestamp;

    @PrePersist
    protected void onCreate() {
        createdTimestamp = LocalDateTime.now();
    }

    public String getSettleId() { return settleId; }
    public void setSettleId(String settleId) { this.settleId = settleId; }

    public String getTxnId() { return txnId; }
    public void setTxnId(String txnId) { this.txnId = txnId; }

    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getTxnType() { return txnType; }
    public void setTxnType(String txnType) { this.txnType = txnType; }

    public BigDecimal getTxnAmount() { return txnAmount; }
    public void setTxnAmount(BigDecimal txnAmount) { this.txnAmount = txnAmount; }

    public LocalDate getTxnDate() { return txnDate; }
    public void setTxnDate(LocalDate txnDate) { this.txnDate = txnDate; }

    public String getMerchantId() { return merchantId; }
    public void setMerchantId(String merchantId) { this.merchantId = merchantId; }

    public String getMerchantName() { return merchantName; }
    public void setMerchantName(String merchantName) { this.merchantName = merchantName; }

    public String getAcquirerId() { return acquirerId; }
    public void setAcquirerId(String acquirerId) { this.acquirerId = acquirerId; }

    public String getIssuerId() { return issuerId; }
    public void setIssuerId(String issuerId) { this.issuerId = issuerId; }

    public String getNetworkId() { return networkId; }
    public void setNetworkId(String networkId) { this.networkId = networkId; }

    public BigDecimal getInterchangeFee() { return interchangeFee; }
    public void setInterchangeFee(BigDecimal interchangeFee) { this.interchangeFee = interchangeFee; }

    public String getSettleStatus() { return settleStatus; }
    public void setSettleStatus(String settleStatus) { this.settleStatus = settleStatus; }

    public LocalDate getSettleDate() { return settleDate; }
    public void setSettleDate(LocalDate settleDate) { this.settleDate = settleDate; }

    public Integer getBatchSeqNum() { return batchSeqNum; }
    public void setBatchSeqNum(Integer batchSeqNum) { this.batchSeqNum = batchSeqNum; }

    public LocalDateTime getCreatedTimestamp() { return createdTimestamp; }
    public void setCreatedTimestamp(LocalDateTime createdTimestamp) { this.createdTimestamp = createdTimestamp; }
}
