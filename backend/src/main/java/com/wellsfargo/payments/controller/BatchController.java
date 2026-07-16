package com.wellsfargo.payments.controller;

import com.wellsfargo.payments.service.CardService;
import com.wellsfargo.payments.service.SettlementService;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * REST controller for batch pipeline operations.
 * Maps to JCL batch job orchestration - now uses Spring Batch concepts.
 */
@RestController
@RequestMapping("/api/batch")
public class BatchController {

    private final CardService cardService;
    private final SettlementService settlementService;

    public BatchController(CardService cardService, SettlementService settlementService) {
        this.cardService = cardService;
        this.settlementService = settlementService;
    }

    /** Run PI (Plastic Issuance) pipeline: PILOAD0 + PICRD400. */
    @PostMapping("/run-pi-pipeline")
    public Map<String, Object> runPIPipeline() {
        long start = System.currentTimeMillis();
        List<Map<String, Object>> jobs = new ArrayList<>();

        // Step 1: Load sample data (PILOAD0)
        Map<String, Object> loadResult = cardService.loadSampleData();
        jobs.add(loadResult);

        // Step 2: Renew expiring cards (PICRD400)
        Map<String, Object> renewResult = cardService.renewCards(60);
        Map<String, Object> renewJob = new LinkedHashMap<>();
        renewJob.put("job_name", "PICRD400");
        renewJob.put("status", "COMPLETED");
        renewJob.put("records_read", renewResult.get("renewed_count"));
        renewJob.put("records_written", renewResult.get("renewed_count"));
        renewJob.put("records_rejected", 0);
        renewJob.put("message", renewResult.get("message"));
        jobs.add(renewJob);

        long duration = System.currentTimeMillis() - start;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("pipeline_name", "PI_BATCH_CYCLE");
        result.put("status", "COMPLETED");
        result.put("jobs", jobs);
        result.put("total_duration_ms", duration);
        return result;
    }

    /** Run Settlement pipeline: STLMT100 + STLMT200 + STLMT300 + STLMT400. */
    @PostMapping("/run-settlement-pipeline")
    public Map<String, Object> runSettlementPipeline() {
        long start = System.currentTimeMillis();
        List<Map<String, Object>> jobs = new ArrayList<>();

        // Step 1: Generate and extract (STLMT100)
        var txns = settlementService.generateSampleTransactions();
        Map<String, Object> extractResult = settlementService.extractTransactions(txns);
        jobs.add(extractResult);

        // Step 2: Match transactions (STLMT200)
        var confirmations = settlementService.generateSampleConfirmations();
        Map<String, Object> matchResult = settlementService.matchTransactions(confirmations);
        Map<String, Object> matchJob = new LinkedHashMap<>();
        matchJob.put("job_name", "STLMT200");
        matchJob.put("status", "COMPLETED");
        matchJob.put("records_read", (int) matchResult.get("matched_count") + (int) matchResult.get("unmatched_settlement_count") + (int) matchResult.get("amount_mismatch_count"));
        matchJob.put("records_written", matchResult.get("matched_count"));
        matchJob.put("records_rejected", (int) matchResult.get("unmatched_settlement_count") + (int) matchResult.get("amount_mismatch_count"));
        matchJob.put("message", "Matched: " + matchResult.get("matched_count") + ", Unmatched: " + matchResult.get("unmatched_settlement_count") + ", Disputed: " + matchResult.get("amount_mismatch_count"));
        jobs.add(matchJob);

        // Step 3: Calculate net settlement (STLMT300)
        Map<String, Object> netResult = settlementService.calculateNetSettlement();
        Map<String, Object> netJob = new LinkedHashMap<>();
        netJob.put("job_name", "STLMT300");
        netJob.put("status", "COMPLETED");
        netJob.put("records_read", netResult.get("grand_total_txn_count"));
        netJob.put("records_written", netResult.get("grand_total_txn_count"));
        netJob.put("records_rejected", 0);
        netJob.put("message", "Net settlement: $" + netResult.get("grand_total_net_amount"));
        jobs.add(netJob);

        // Step 4: Generate report (STLMT400)
        Map<String, Object> report = settlementService.generateManagementReport();
        Map<String, Object> reportJob = new LinkedHashMap<>();
        reportJob.put("job_name", "STLMT400");
        reportJob.put("status", "COMPLETED");
        reportJob.put("records_read", ((List<?>) report.get("network_details")).size());
        reportJob.put("records_written", ((List<?>) report.get("network_details")).size());
        reportJob.put("records_rejected", 0);
        reportJob.put("message", "Report generated for " + report.get("report_date"));
        jobs.add(reportJob);

        long duration = System.currentTimeMillis() - start;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("pipeline_name", "SETTLEMENT_BATCH_CYCLE");
        result.put("status", "COMPLETED");
        result.put("jobs", jobs);
        result.put("total_duration_ms", duration);
        return result;
    }

    /** Run full pipeline: PI + Settlement. */
    @PostMapping("/run-full-pipeline")
    public Map<String, Object> runFullPipeline() {
        long start = System.currentTimeMillis();

        Map<String, Object> piResult = runPIPipeline();
        Map<String, Object> stlResult = runSettlementPipeline();

        List<Map<String, Object>> allJobs = new ArrayList<>();
        allJobs.addAll((List<Map<String, Object>>) piResult.get("jobs"));
        allJobs.addAll((List<Map<String, Object>>) stlResult.get("jobs"));

        long duration = System.currentTimeMillis() - start;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("pipeline_name", "FULL_BATCH_PIPELINE");
        result.put("status", "COMPLETED");
        result.put("jobs", allJobs);
        result.put("total_duration_ms", duration);
        return result;
    }

    /** Dashboard stats combining card and settlement data. */
    @GetMapping("/dashboard")
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> cardStats = cardService.getDashboardStats();
        Map<String, Object> stlStats = settlementService.getSettlementStats();

        Map<String, Object> combined = new LinkedHashMap<>(cardStats);
        combined.putAll(stlStats);
        combined.put("total_transactions", 0);
        return combined;
    }
}
