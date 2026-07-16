package com.wellsfargo.payments.service;

import com.wellsfargo.payments.entity.SettlementTransaction;
import com.wellsfargo.payments.repository.SettlementSummaryRepository;
import com.wellsfargo.payments.repository.SettlementTransactionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SettlementServiceTest {

    @Mock
    private SettlementTransactionRepository txnRepo;

    @Mock
    private SettlementSummaryRepository summaryRepo;

    @Test
    void extractAcceptsAndNormalizesValidCobolNetworkRecord() {
        when(txnRepo.findMaxBatchSeqNum()).thenReturn(0);
        SettlementTransaction transaction = validTransaction();
        transaction.setNetworkId("MC  ");

        SettlementService service = new SettlementService(txnRepo, summaryRepo);
        Map<String, Object> result = service.extractTransactions(List.of(transaction));

        assertEquals(1, result.get("records_written"));
        assertEquals(0, result.get("records_rejected"));

        ArgumentCaptor<SettlementTransaction> transactionCaptor =
            ArgumentCaptor.forClass(SettlementTransaction.class);
        verify(txnRepo).save(transactionCaptor.capture());
        SettlementTransaction saved = transactionCaptor.getValue();
        assertEquals("MC", saved.getNetworkId());
        assertEquals("PE", saved.getSettleStatus());
        assertEquals(1, saved.getBatchSeqNum());
        assertEquals(
            LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE) + "0001",
            saved.getSettleId()
        );
    }

    @Test
    void extractRejectsTheSameInvalidFieldsAsStlmt100() {
        when(txnRepo.findMaxBatchSeqNum()).thenReturn(0);

        SettlementTransaction missingTxnId = validTransaction();
        missingTxnId.setTxnId(" ");
        SettlementTransaction missingCardNumber = validTransaction();
        missingCardNumber.setCardNumber(null);
        SettlementTransaction zeroAmount = validTransaction();
        zeroAmount.setTxnAmount(BigDecimal.ZERO);
        SettlementTransaction missingDate = validTransaction();
        missingDate.setTxnDate(null);
        SettlementTransaction invalidNetwork = validTransaction();
        invalidNetwork.setNetworkId("AMEX");

        SettlementService service = new SettlementService(txnRepo, summaryRepo);
        Map<String, Object> result = service.extractTransactions(List.of(
            missingTxnId,
            missingCardNumber,
            zeroAmount,
            missingDate,
            invalidNetwork
        ));

        assertEquals(0, result.get("records_written"));
        assertEquals(5, result.get("records_rejected"));
        verify(txnRepo, never()).save(any(SettlementTransaction.class));
    }

    private SettlementTransaction validTransaction() {
        SettlementTransaction transaction = new SettlementTransaction();
        transaction.setTxnId("TXN0000000001");
        transaction.setCardNumber("4000120000001008");
        transaction.setTxnAmount(new BigDecimal("125.50"));
        transaction.setTxnDate(LocalDate.now());
        transaction.setNetworkId("VISA");
        return transaction;
    }
}
