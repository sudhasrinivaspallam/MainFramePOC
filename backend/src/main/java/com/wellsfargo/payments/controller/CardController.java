package com.wellsfargo.payments.controller;

import com.wellsfargo.payments.entity.CardMaster;
import com.wellsfargo.payments.entity.CardStatusHistory;
import com.wellsfargo.payments.service.CardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST controller for card management operations.
 * Maps to COBOL programs: PICRD100, PICRD200, PICRD300, PICRD400, PIONL100, PIONL200.
 */
@RestController
@RequestMapping("/api/cards")
public class CardController {

    private final CardService cardService;

    public CardController(CardService cardService) {
        this.cardService = cardService;
    }

    /** PIONL100 - List cards with optional status filter. */
    @GetMapping
    public List<CardMaster> listCards(@RequestParam(required = false) String status) {
        return cardService.getAllCards(status);
    }

    /** PIONL100 - Search cards by query. */
    @GetMapping("/search")
    public List<CardMaster> searchCards(@RequestParam String q) {
        return cardService.searchCards(q);
    }

    /** PIONL100 - Get card by card number. */
    @GetMapping("/{cardNumber}")
    public ResponseEntity<CardMaster> getCard(@PathVariable String cardNumber) {
        return cardService.getCard(cardNumber)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    /** PICRD100 - Issue new card. */
    @PostMapping
    public CardMaster issueCard(@RequestBody CardMaster request) {
        return cardService.issueCard(request);
    }

    /** PICRD100 - Batch issue cards. */
    @PostMapping("/batch-issue")
    public Map<String, Object> batchIssueCards(@RequestBody List<CardMaster> requests) {
        return cardService.batchIssueCards(requests);
    }

    /** PICRD200 - Activate card. */
    @PutMapping("/{cardNumber}/activate")
    public CardMaster activateCard(@PathVariable String cardNumber, @RequestBody Map<String, String> body) {
        return cardService.activateCard(
            cardNumber,
            body.get("customer_id"),
            body.getOrDefault("pin_offset", "1234"),
            body.getOrDefault("activation_channel", "OL")
        );
    }

    /** PICRD300 - Update card status. */
    @PutMapping("/{cardNumber}/status")
    public CardMaster updateCardStatus(@PathVariable String cardNumber, @RequestBody Map<String, String> body) {
        return cardService.updateCardStatus(
            cardNumber,
            body.get("action_code"),
            body.getOrDefault("reason_code", "CUST"),
            body.getOrDefault("requestor_id", "SYSTEM")
        );
    }

    /** PIONL200 - Update non-status card fields. */
    @PutMapping("/{cardNumber}")
    public CardMaster updateCard(@PathVariable String cardNumber, @RequestBody CardMaster updates) {
        return cardService.updateCard(cardNumber, updates);
    }

    /** Get card status history. */
    @GetMapping("/{cardNumber}/history")
    public List<CardStatusHistory> getCardHistory(@PathVariable String cardNumber) {
        return cardService.getCardHistory(cardNumber);
    }

    /** PICRD400 - Renew expiring cards. */
    @PostMapping("/renew")
    public Map<String, Object> renewCards(@RequestParam(defaultValue = "60") int cutoff_days) {
        return cardService.renewCards(cutoff_days);
    }

    /** Load sample data. */
    @PostMapping("/load-sample-data")
    public Map<String, Object> loadSampleData() {
        return cardService.loadSampleData();
    }
}
