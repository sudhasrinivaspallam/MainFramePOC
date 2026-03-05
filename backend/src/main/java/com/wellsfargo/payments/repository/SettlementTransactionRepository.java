package com.wellsfargo.payments.repository;

import com.wellsfargo.payments.entity.SettlementTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SettlementTransactionRepository extends JpaRepository<SettlementTransaction, String> {

    List<SettlementTransaction> findBySettleStatus(String settleStatus);

    List<SettlementTransaction> findByNetworkId(String networkId);

    List<SettlementTransaction> findBySettleStatusAndNetworkId(String settleStatus, String networkId);

    List<SettlementTransaction> findBySettleDate(LocalDate settleDate);

    @Query("SELECT s FROM SettlementTransaction s WHERE s.settleStatus = :status ORDER BY s.txnId ASC")
    List<SettlementTransaction> findByStatusOrderByTxnId(@Param("status") String status);

    @Query("SELECT s FROM SettlementTransaction s WHERE s.settleDate = :date AND s.settleStatus = 'MT'")
    List<SettlementTransaction> findMatchedByDate(@Param("date") LocalDate date);

    @Query("SELECT COALESCE(MAX(s.batchSeqNum), 0) FROM SettlementTransaction s")
    int findMaxBatchSeqNum();

    long countBySettleStatus(String settleStatus);

    @Query("SELECT COALESCE(SUM(s.txnAmount), 0) FROM SettlementTransaction s")
    java.math.BigDecimal sumAllTxnAmounts();
}
