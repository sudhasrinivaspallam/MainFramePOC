package com.wellsfargo.payments.service;

import com.wellsfargo.payments.entity.CardMaster;
import com.wellsfargo.payments.entity.CardStatusHistory;
import com.wellsfargo.payments.repository.CardMasterRepository;
import com.wellsfargo.payments.repository.CardStatusHistoryRepository;
import com.wellsfargo.payments.util.LuhnUtil;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Card management service - implements all COBOL program logic:
 * PICRD100 (issuance), PICRD200 (activation), PICRD300 (status update),
 * PICRD400 (renewal), PIONL100 (inquiry), PIONL200 (update).
 */
@Service
public class CardService {

    /**
     * Valid status transitions - mirrors PICRD300.cbl EVALUATE (lines 253-306).
     * Format: "FROM-TO" pairs.
     */
    private static final Set<String> VALID_TRANSITIONS = Set.of(
        "NW-AC",  // Activate new card
        "AC-BL",  // Block active card
        "BL-AC",  // Unblock blocked card
        "AC-CL",  // Close active card
        "BL-CL",  // Close blocked card
        "NW-CL",  // Close new card
        "AC-HL"   // Hotlist active card
    );

    /**
     * Action code to target status mapping.
     */
    private static final Map<String, String> ACTION_STATUS_MAP = Map.of(
        "BL", "BL",  // Block
        "UB", "AC",  // Unblock
        "CL", "CL",  // Close
        "HL", "HL"   // Hotlist
    );

    private final CardMasterRepository cardRepo;
    private final CardStatusHistoryRepository historyRepo;
    private final AtomicInteger sequenceCounter;

    public CardService(CardMasterRepository cardRepo, CardStatusHistoryRepository historyRepo) {
        this.cardRepo = cardRepo;
        this.historyRepo = historyRepo;
        this.sequenceCounter = new AtomicInteger(100);
    }

    /**
     * Initialize sequence counter from DB once at startup.
     * Uses @PostConstruct to avoid race condition from per-call DB reads.
     */
    @PostConstruct
    private void initSequence() {
        try {
            int maxSeq = cardRepo.findMaxSequence();
            sequenceCounter.set(Math.max(maxSeq + 1, 100));
        } catch (Exception e) {
            sequenceCounter.set(100);
        }
    }

    /**
     * PICRD100 - Issue new card with Luhn validation.
     * Generates 16-digit card number: BIN(400012) + sequence(9) + check(1).
     * Uses AtomicInteger for thread-safe sequence allocation.
     */
    @Transactional
    public synchronized CardMaster issueCard(CardMaster request) {
        int seq = sequenceCounter.getAndIncrement();
        String cardNumber = LuhnUtil.generateCardNumber(seq);

        request.setCardNumber(cardNumber);
        request.setCardStatus("NW");
        request.setIssueDate(LocalDate.now());
        request.setExpiryDate(LocalDate.now().plusYears(3));

        CardMaster saved = cardRepo.save(request);

        // Record history
        CardStatusHistory history = new CardStatusHistory();
        history.setCardNumber(cardNumber);
        history.setPreviousStatus(null);
        history.setNewStatus("NW");
        history.setReasonCode("NEW");
        history.setRequestorId("SYSTEM");
        historyRepo.save(history);

        return saved;
    }

    /**
     * PICRD200 - Activate card (NW → AC).
     * Validates card exists, status is NW, and customer_id matches.
     */
    @Transactional
    public CardMaster activateCard(String cardNumber, String customerId, String pinOffset, String channel) {
        CardMaster card = cardRepo.findById(cardNumber)
            .orElseThrow(() -> new IllegalArgumentException("Card not found: " + cardNumber));

        if (!"NW".equals(card.getCardStatus())) {
            throw new IllegalStateException("Card must be in NW status to activate. Current: " + card.getCardStatus());
        }
        if (!card.getCustomerId().equals(customerId)) {
            throw new IllegalArgumentException("Customer ID does not match card record");
        }

        String prevStatus = card.getCardStatus();
        card.setCardStatus("AC");
        card.setActivationDate(LocalDate.now());
        if (pinOffset != null) card.setPinOffset(pinOffset);
        CardMaster saved = cardRepo.save(card);

        recordHistory(cardNumber, prevStatus, "AC", "ACTIVATE", channel != null ? channel : "SYSTEM");
        return saved;
    }

    /**
     * PICRD300 - Update card status with transition matrix validation.
     * Mirrors COBOL EVALUATE block (lines 253-306).
     */
    @Transactional
    public CardMaster updateCardStatus(String cardNumber, String actionCode, String reasonCode, String requestorId) {
        CardMaster card = cardRepo.findById(cardNumber)
            .orElseThrow(() -> new IllegalArgumentException("Card not found: " + cardNumber));

        String targetStatus = ACTION_STATUS_MAP.get(actionCode);
        if (targetStatus == null) {
            throw new IllegalArgumentException("Invalid action code: " + actionCode);
        }

        String transition = card.getCardStatus() + "-" + targetStatus;
        if (!VALID_TRANSITIONS.contains(transition)) {
            throw new IllegalStateException(
                "Invalid status transition: " + card.getCardStatus() + " → " + targetStatus +
                ". Allowed transitions from " + card.getCardStatus() + ": " + getAllowedTransitions(card.getCardStatus())
            );
        }

        String prevStatus = card.getCardStatus();
        card.setCardStatus(targetStatus);
        CardMaster saved = cardRepo.save(card);

        recordHistory(cardNumber, prevStatus, targetStatus, reasonCode, requestorId);
        return saved;
    }

    /**
     * PICRD400 - Renew cards expiring within cutoff window.
     * Finds AC cards with expiry_date <= today + cutoffDays.
     * Generates new card, marks old as EX.
     */
    @Transactional
    public Map<String, Object> renewCards(int cutoffDays) {
        LocalDate cutoffDate = LocalDate.now().plusDays(cutoffDays);
        List<CardMaster> expiringCards = cardRepo.findCardsForRenewal("AC", cutoffDate);

        List<Map<String, String>> renewalPairs = new ArrayList<>();

        for (CardMaster oldCard : expiringCards) {
            // Generate new card using shared sequence counter (thread-safe)
            int renewalSeq = sequenceCounter.getAndIncrement();
            String newCardNumber = LuhnUtil.generateCardNumber(renewalSeq);

            CardMaster newCard = new CardMaster();
            newCard.setCardNumber(newCardNumber);
            newCard.setCardType(oldCard.getCardType());
            newCard.setAccountNumber(oldCard.getAccountNumber());
            newCard.setCustomerId(oldCard.getCustomerId());
            newCard.setFirstName(oldCard.getFirstName());
            newCard.setLastName(oldCard.getLastName());
            newCard.setAddrLine1(oldCard.getAddrLine1());
            newCard.setAddrLine2(oldCard.getAddrLine2());
            newCard.setCity(oldCard.getCity());
            newCard.setState(oldCard.getState());
            newCard.setZipCode(oldCard.getZipCode());
            newCard.setCardStatus("NW");
            newCard.setIssueDate(LocalDate.now());
            newCard.setExpiryDate(LocalDate.now().plusYears(3));
            newCard.setDailyLimit(oldCard.getDailyLimit());
            newCard.setAvailableBalance(oldCard.getAvailableBalance());
            newCard.setBranchCode(oldCard.getBranchCode());
            cardRepo.save(newCard);

            // Mark old card as expired
            String prevStatus = oldCard.getCardStatus();
            oldCard.setCardStatus("EX");
            cardRepo.save(oldCard);

            recordHistory(oldCard.getCardNumber(), prevStatus, "EX", "RENEWAL", "BATCH");
            recordHistory(newCardNumber, null, "NW", "RENEWAL", "BATCH");

            Map<String, String> pair = new LinkedHashMap<>();
            pair.put("old_card_number", oldCard.getCardNumber());
            pair.put("new_card_number", newCardNumber);
            pair.put("old_expiry", oldCard.getExpiryDate().toString());
            pair.put("new_expiry", newCard.getExpiryDate().toString());
            pair.put("customer_name", oldCard.getFirstName() + " " + oldCard.getLastName());
            renewalPairs.add(pair);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("renewed_count", renewalPairs.size());
        result.put("renewal_pairs", renewalPairs);
        result.put("message", renewalPairs.isEmpty()
            ? "No cards found expiring within " + cutoffDays + " days"
            : renewalPairs.size() + " card(s) renewed successfully");
        return result;
    }

    /** PIONL100 - Get card by card number. */
    public Optional<CardMaster> getCard(String cardNumber) {
        return cardRepo.findById(cardNumber);
    }

    /** PIONL100 - List all cards with optional status filter. */
    public List<CardMaster> getAllCards(String status) {
        if (status != null && !status.isEmpty()) {
            return cardRepo.findByCardStatus(status);
        }
        return cardRepo.findAll();
    }

    /** PIONL100 - Search cards by query. */
    public List<CardMaster> searchCards(String query) {
        return cardRepo.searchCards(query);
    }

    /** PIONL200 - Update non-status card fields. */
    @Transactional
    public CardMaster updateCard(String cardNumber, CardMaster updates) {
        CardMaster card = cardRepo.findById(cardNumber)
            .orElseThrow(() -> new IllegalArgumentException("Card not found: " + cardNumber));

        if (updates.getFirstName() != null) card.setFirstName(updates.getFirstName());
        if (updates.getLastName() != null) card.setLastName(updates.getLastName());
        if (updates.getAddrLine1() != null) card.setAddrLine1(updates.getAddrLine1());
        if (updates.getAddrLine2() != null) card.setAddrLine2(updates.getAddrLine2());
        if (updates.getCity() != null) card.setCity(updates.getCity());
        if (updates.getState() != null) card.setState(updates.getState());
        if (updates.getZipCode() != null) card.setZipCode(updates.getZipCode());
        if (updates.getDailyLimit() != null) card.setDailyLimit(updates.getDailyLimit());
        if (updates.getAvailableBalance() != null) card.setAvailableBalance(updates.getAvailableBalance());
        if (updates.getBranchCode() != null) card.setBranchCode(updates.getBranchCode());

        return cardRepo.save(card);
    }

    /** Get card status history. */
    public List<CardStatusHistory> getCardHistory(String cardNumber) {
        return historyRepo.findByCardNumberOrderByCreatedTimestampDesc(cardNumber);
    }

    /** Batch issue multiple cards. */
    @Transactional
    public Map<String, Object> batchIssueCards(List<CardMaster> requests) {
        int written = 0;
        int rejected = 0;
        List<String> errors = new ArrayList<>();

        for (CardMaster req : requests) {
            try {
                issueCard(req);
                written++;
            } catch (Exception e) {
                rejected++;
                errors.add(e.getMessage());
            }
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("job_name", "PICRD100_BATCH");
        result.put("status", rejected == 0 ? "COMPLETED" : "COMPLETED_WITH_ERRORS");
        result.put("records_read", requests.size());
        result.put("records_written", written);
        result.put("records_rejected", rejected);
        result.put("message", written + " cards issued, " + rejected + " rejected");
        if (!errors.isEmpty()) result.put("errors", errors);
        return result;
    }

    /** Load sample data for testing/demo. */
    @Transactional
    public Map<String, Object> loadSampleData() {
        if (cardRepo.count() > 0) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("job_name", "PILOAD0");
            result.put("status", "SKIPPED");
            result.put("records_read", 0);
            result.put("records_written", 0);
            result.put("records_rejected", 0);
            result.put("message", "Sample data already loaded");
            return result;
        }

        Object[][] samples = {
            {"DB", "100000000001", "CUST000001", "JOHN", "SMITH", "123 MAIN ST", "NEW YORK", "NY", "10001", 2000.00, 15000.00},
            {"DB", "100000000002", "CUST000002", "JANE", "DOE", "456 OAK AVE", "LOS ANGELES", "CA", "90001", 5000.00, 25000.00},
            {"PP", "100000000003", "CUST000003", "ROBERT", "JOHNSON", "789 PINE RD", "CHICAGO", "IL", "60601", 1000.00, 500.00},
            {"DB", "100000000004", "CUST000004", "MARIA", "GARCIA", "321 ELM ST", "HOUSTON", "TX", "77001", 3000.00, 18000.00},
            {"DB", "100000000005", "CUST000005", "WILLIAM", "BROWN", "654 MAPLE DR", "PHOENIX", "AZ", "85001", 1500.00, 8500.00},
            {"DB", "100000000006", "CUST000006", "PATRICIA", "DAVIS", "987 CEDAR LN", "PHILADELPHIA", "PA", "19101", 4000.00, 32000.00},
            {"PP", "100000000007", "CUST000007", "JAMES", "WILSON", "147 BIRCH WAY", "SAN ANTONIO", "TX", "78201", 2500.00, 1200.00},
            {"DB", "100000000008", "CUST000008", "ELIZABETH", "MARTINEZ", "258 WALNUT CT", "SAN DIEGO", "CA", "92101", 3500.00, 22000.00},
            {"DB", "100000000009", "CUST000009", "MICHAEL", "ANDERSON", "369 SPRUCE DR", "DALLAS", "TX", "75201", 2000.00, 11000.00},
            {"DB", "100000000010", "CUST000010", "SARAH", "TAYLOR", "741 ASH BLVD", "SAN JOSE", "CA", "95101", 6000.00, 45000.00},
        };

        String[] targetStatuses = {"AC", "AC", "NW", "BL", "AC", "AC", "NW", "AC", "AC", "AC"};
        int written = 0;

        for (int i = 0; i < samples.length; i++) {
            Object[] s = samples[i];
            CardMaster card = new CardMaster();
            card.setCardType((String) s[0]);
            card.setAccountNumber((String) s[1]);
            card.setCustomerId((String) s[2]);
            card.setFirstName((String) s[3]);
            card.setLastName((String) s[4]);
            card.setAddrLine1((String) s[5]);
            card.setCity((String) s[6]);
            card.setState((String) s[7]);
            card.setZipCode((String) s[8]);
            card.setDailyLimit(BigDecimal.valueOf((Double) s[9]));
            card.setAvailableBalance(BigDecimal.valueOf((Double) s[10]));

            CardMaster issued = issueCard(card);

            // If target is AC, activate it
            if ("AC".equals(targetStatuses[i])) {
                activateCard(issued.getCardNumber(), issued.getCustomerId(), "1234", "BATCH");
            }
            // If target is BL, activate then block
            if ("BL".equals(targetStatuses[i])) {
                activateCard(issued.getCardNumber(), issued.getCustomerId(), "1234", "BATCH");
                updateCardStatus(issued.getCardNumber(), "BL", "SAMPLE", "BATCH");
            }

            // Card 8 (index 7) gets near-expiry for renewal testing
            if (i == 7) {
                issued.setExpiryDate(LocalDate.now().plusDays(30));
                cardRepo.save(issued);
            }

            written++;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("job_name", "PILOAD0");
        result.put("status", "COMPLETED");
        result.put("records_read", samples.length);
        result.put("records_written", written);
        result.put("records_rejected", 0);
        result.put("message", "Loaded " + written + " sample cards");
        return result;
    }

    /** Get dashboard statistics. */
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("total_cards", cardRepo.count());
        stats.put("active_cards", cardRepo.countByCardStatus("AC"));
        stats.put("new_cards", cardRepo.countByCardStatus("NW"));
        stats.put("blocked_cards", cardRepo.countByCardStatus("BL"));
        stats.put("expired_cards", cardRepo.countByCardStatus("EX"));
        stats.put("closed_cards", cardRepo.countByCardStatus("CL"));
        stats.put("recent_cards", cardRepo.findAll().stream().limit(5).toList());
        return stats;
    }

    private void recordHistory(String cardNumber, String prevStatus, String newStatus, String reasonCode, String requestorId) {
        CardStatusHistory h = new CardStatusHistory();
        h.setCardNumber(cardNumber);
        h.setPreviousStatus(prevStatus);
        h.setNewStatus(newStatus);
        h.setReasonCode(reasonCode);
        h.setRequestorId(requestorId);
        historyRepo.save(h);
    }

    private String getAllowedTransitions(String currentStatus) {
        List<String> allowed = new ArrayList<>();
        for (String t : VALID_TRANSITIONS) {
            if (t.startsWith(currentStatus + "-")) {
                allowed.add(t.substring(3));
            }
        }
        return String.join(", ", allowed);
    }
}
