package com.wellsfargo.payments.repository;

import com.wellsfargo.payments.entity.CardStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CardStatusHistoryRepository extends JpaRepository<CardStatusHistory, Long> {

    List<CardStatusHistory> findByCardNumberOrderByCreatedTimestampDesc(String cardNumber);
}
