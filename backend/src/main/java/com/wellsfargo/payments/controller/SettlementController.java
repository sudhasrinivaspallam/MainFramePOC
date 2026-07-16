package com.wellsfargo.payments.controller;

import com.wellsfargo.payments.entity.SettlementSummary;
import com.wellsfargo.payments.entity.SettlementTransaction;
import com.wellsfargo.payments.service.SettlementService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST controller for settlement operations.
 * Maps to COBOL programs: STLMT100, STLMT200, STLMT300, STLMT400.
 */
@RestController
@RequestMapping("/api/settlement")
public class SettlementController {

    private final SettlementService settlementService;

    public SettlementController(SettlementService settlementService) {
        this.settlementService = settlementService;
    }

    /** Get settlement transactions with optional filters. */
    @GetMapping("/transactions")
    public List<SettlementTransaction> listTransactions(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String network) {
        return settlementService.getTransactions(status, network);
    }

    /** Get settlement summaries. */
    @GetMapping("/summaries")
    public List<SettlementSummary> listSummaries(
            @RequestParam(required = false) String settle_date) {
        return settlementService.getSummaries(settle_date);
    }

    /** STLMT100 - Extract transactions. */
    @PostMapping("/extract")
    public Map<String, Object> extractTransactions(@RequestBody List<SettlementTransaction> transactions) {
        return settlementService.extractTransactions(transactions);
    }

    /** STLMT200 - Run matching with provided acquirer confirmations. */
    @PostMapping("/match")
    public Map<String, Object> matchTransactions(@RequestBody List<Map<String, Object>> confirmations) {
        return settlementService.matchTransactions(confirmations);
    }

    /** STLMT300 - Calculate net settlement. */
    @PostMapping("/calculate")
    public Map<String, Object> calculateNetSettlement() {
        return settlementService.calculateNetSettlement();
    }

    /** STLMT400 - Get management report. */
    @GetMapping("/report")
    public Map<String, Object> getManagementReport() {
        return settlementService.generateManagementReport();
    }

    /** STLMT400 - Get CSV report. */
    @GetMapping("/report/csv")
    public ResponseEntity<String> getCsvReport() {
        String csv = settlementService.getCsvReport();
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=settlement_report.csv")
            .contentType(MediaType.parseMediaType("text/csv"))
            .body(csv);
    }

    /** Generate and extract sample transaction data. */
    @PostMapping("/generate-sample-data")
    public Map<String, Object> generateAndExtractSample() {
        List<SettlementTransaction> txns = settlementService.generateSampleTransactions();
        return settlementService.extractTransactions(txns);
    }

    /** Run matching with auto-generated acquirer confirmations. */
    @PostMapping("/run-matching")
    public Map<String, Object> runMatchingWithSample() {
        List<Map<String, Object>> confirmations = settlementService.generateSampleConfirmations();
        return settlementService.matchTransactions(confirmations);
    }
}
