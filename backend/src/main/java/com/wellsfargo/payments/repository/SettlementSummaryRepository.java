package com.wellsfargo.payments.repository;

import com.wellsfargo.payments.entity.SettlementSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SettlementSummaryRepository extends JpaRepository<SettlementSummary, Long> {

    List<SettlementSummary> findBySettleDate(LocalDate settleDate);

    List<SettlementSummary> findBySettleDateAndNetworkId(LocalDate settleDate, String networkId);

    void deleteBySettleDate(LocalDate settleDate);
}
