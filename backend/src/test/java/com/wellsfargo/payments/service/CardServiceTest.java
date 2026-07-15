package com.wellsfargo.payments.service;

import com.wellsfargo.payments.entity.CardMaster;
import com.wellsfargo.payments.entity.CardStatusHistory;
import com.wellsfargo.payments.repository.CardMasterRepository;
import com.wellsfargo.payments.repository.CardStatusHistoryRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CardServiceTest {

    @Mock
    private CardMasterRepository cardRepo;

    @Mock
    private CardStatusHistoryRepository historyRepo;

    @Test
    void hotlistActionBlocksActiveCardLikePicrd300() {
        CardMaster card = new CardMaster();
        card.setCardNumber("4000120000001008");
        card.setCardStatus("AC");

        when(cardRepo.findById(card.getCardNumber())).thenReturn(Optional.of(card));
        when(cardRepo.save(any(CardMaster.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CardService service = new CardService(cardRepo, historyRepo);
        CardMaster updated = service.updateCardStatus(card.getCardNumber(), "HL", "FRAUD", "OPS001");

        assertEquals("BL", updated.getCardStatus());

        ArgumentCaptor<CardStatusHistory> historyCaptor = ArgumentCaptor.forClass(CardStatusHistory.class);
        verify(historyRepo).save(historyCaptor.capture());
        assertEquals("AC", historyCaptor.getValue().getPreviousStatus());
        assertEquals("BL", historyCaptor.getValue().getNewStatus());
        assertEquals("FRAUD", historyCaptor.getValue().getReasonCode());
        assertEquals("OPS001", historyCaptor.getValue().getRequestorId());
    }

    @Test
    void hotlistActionRejectsNonActiveCardLikePicrd300() {
        CardMaster card = new CardMaster();
        card.setCardNumber("4000120000001016");
        card.setCardStatus("BL");

        when(cardRepo.findById(card.getCardNumber())).thenReturn(Optional.of(card));

        CardService service = new CardService(cardRepo, historyRepo);

        assertThrows(
            IllegalStateException.class,
            () -> service.updateCardStatus(card.getCardNumber(), "HL", "FRAUD", "OPS001")
        );
        verify(cardRepo, never()).save(any(CardMaster.class));
        verify(historyRepo, never()).save(any(CardStatusHistory.class));
    }

    @Test
    void issueCardRejectsTheSameRequiredFieldsAsPicrd100() {
        CardService service = new CardService(cardRepo, historyRepo);

        CardMaster invalidCardType = validIssuanceRequest();
        invalidCardType.setCardType("CR");
        CardMaster missingAccount = validIssuanceRequest();
        missingAccount.setAccountNumber(" ");
        CardMaster missingCustomer = validIssuanceRequest();
        missingCustomer.setCustomerId(null);
        CardMaster missingFirstName = validIssuanceRequest();
        missingFirstName.setFirstName("");
        CardMaster missingLastName = validIssuanceRequest();
        missingLastName.setLastName(" ");

        assertThrows(IllegalArgumentException.class, () -> service.issueCard(invalidCardType));
        assertThrows(IllegalArgumentException.class, () -> service.issueCard(missingAccount));
        assertThrows(IllegalArgumentException.class, () -> service.issueCard(missingCustomer));
        assertThrows(IllegalArgumentException.class, () -> service.issueCard(missingFirstName));
        assertThrows(IllegalArgumentException.class, () -> service.issueCard(missingLastName));
        verify(cardRepo, never()).save(any(CardMaster.class));
        verify(historyRepo, never()).save(any(CardStatusHistory.class));
    }

    private CardMaster validIssuanceRequest() {
        CardMaster card = new CardMaster();
        card.setCardType("DB");
        card.setAccountNumber("100000000001");
        card.setCustomerId("CUST000001");
        card.setFirstName("JOHN");
        card.setLastName("SMITH");
        return card;
    }
}
