package com.wellsfargo.payments.repository;

import com.wellsfargo.payments.entity.CardMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CardMasterRepository extends JpaRepository<CardMaster, String> {

    List<CardMaster> findByCardStatus(String cardStatus);

    List<CardMaster> findByCustomerId(String customerId);

    @Query("SELECT c FROM CardMaster c WHERE c.cardStatus = :status AND c.expiryDate <= :cutoffDate")
    List<CardMaster> findCardsForRenewal(@Param("status") String status, @Param("cutoffDate") LocalDate cutoffDate);

    @Query("SELECT c FROM CardMaster c WHERE " +
           "LOWER(c.cardNumber) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(c.customerId) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(c.firstName) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(c.lastName) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<CardMaster> searchCards(@Param("q") String query);

    @Query("SELECT COUNT(c) FROM CardMaster c")
    long countAll();

    long countByCardStatus(String cardStatus);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(c.cardNumber, 7, 9) AS int)), 99) FROM CardMaster c")
    int findMaxSequence();
}
