package com.wellsfargo.payments.service;

import com.wellsfargo.payments.entity.SettlementSummary;
import com.wellsfargo.payments.entity.SettlementTransaction;
import com.wellsfargo.payments.repository.SettlementSummaryRepository;
import com.wellsfargo.payments.repository.SettlementTransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * Settlement service - implements all COBOL settlement program logic:
 * STLMT100 (extract), STLMT200 (matching), STLMT300 (net settlement), STLMT400 (reports).
 */
@Service
public class SettlementService {

    private static final BigDecimal INTERCHANGE_RATE = new BigDecimal("0.0175");
    private static final String[] NETWORKS = {"VISA", "MC", "STAR"};
    private static final String[] MERCHANT_NAMES = {
        "AMAZON MARKETPLACE", "WALMART STORES", "TARGET CORP",
        "BEST BUY ELECTRONICS", "COSTCO WHOLESALE"
    };
    private static final String[] MERCHANT_IDS = {
        "MERCH00001", "MERCH00002", "MERCH00003", "MERCH00004", "MERCH00005"
    };

    private final SettlementTransactionRepository txnRepo;
    private final SettlementSummaryRepository summaryRepo;

    public SettlementService(SettlementTransactionRepository txnRepo, SettlementSummaryRepository summaryRepo) {
        this.txnRepo = txnRepo;
        this.summaryRepo = summaryRepo;
    }

    /**
     * STLMT100 - Extract and validate transactions.
     * Generates settle_id from YYYYMMDD + sequence, sets status to PE.
     */
    @Transactional
    public Map<String, Object> extractTransactions(List<SettlementTransaction> transactions) {
        int written = 0;
        int rejected = 0;
        int seqNum = txnRepo.findMaxBatchSeqNum() + 1;
        String datePrefix = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);

        for (SettlementTransaction txn : transactions) {
            try {
                if (txn.getTxnAmount() == null || txn.getTxnAmount().compareTo(BigDecimal.ZERO) <= 0) {
                    rejected++;
                    continue;
                }
                txn.setSettleId(datePrefix + String.format("%04d", seqNum++));
                txn.setSettleStatus("PE");
                txn.setSettleDate(LocalDate.now());
                txn.setBatchSeqNum(seqNum - 1);
                txnRepo.save(txn);
                written++;
            } catch (Exception e) {
                rejected++;
            }
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("job_name", "STLMT100");
        result.put("status", "COMPLETED");
        result.put("records_read", transactions.size());
        result.put("records_written", written);
        result.put("records_rejected", rejected);
        result.put("message", written + " transactions extracted, " + rejected + " rejected");
        return result;
    }

    /**
     * STLMT200 - Transaction matching using O(n) sequential merge algorithm.
     * Mirrors STLMT200.cbl lines 189-212.
     * Sorts both settlement and acquirer records by txn_id, then merge-walks.
     */
    @Transactional
    public Map<String, Object> matchTransactions(List<Map<String, Object>> acquirerConfirmations) {
        LocalDate settleDate = LocalDate.now();
        List<SettlementTransaction> pendingTxns = txnRepo.findByStatusOrderByTxnId("PE");

        // Sort acquirer confirmations by txn_id for O(n) merge
        acquirerConfirmations.sort(Comparator.comparing(a -> (String) a.get("txn_id")));

        int si = 0, ai = 0;
        int matchedCount = 0;
        BigDecimal matchedAmount = BigDecimal.ZERO;
        int unmatchedSettlement = 0;
        int unmatchedAcquirer = 0;
        int amountMismatch = 0;
        List<Map<String, Object>> details = new ArrayList<>();

        while (si < pendingTxns.size() && ai < acquirerConfirmations.size()) {
            SettlementTransaction stl = pendingTxns.get(si);
            Map<String, Object> acq = acquirerConfirmations.get(ai);
            String stlKey = stl.getTxnId();
            String acqKey = (String) acq.get("txn_id");

            int cmp = stlKey.compareTo(acqKey);
            if (cmp == 0) {
                // Keys match - check amounts
                BigDecimal acqAmount = new BigDecimal(acq.get("txn_amount").toString());
                if (stl.getTxnAmount().compareTo(acqAmount) == 0) {
                    stl.setSettleStatus("MT");
                    matchedCount++;
                    matchedAmount = matchedAmount.add(stl.getTxnAmount());
                } else {
                    stl.setSettleStatus("DI");
                    amountMismatch++;
                    Map<String, Object> detail = new LinkedHashMap<>();
                    detail.put("txn_id", stlKey);
                    detail.put("type", "AMOUNT_MISMATCH");
                    detail.put("settle_amount", stl.getTxnAmount());
                    detail.put("acquirer_amount", acqAmount);
                    details.add(detail);
                }
                txnRepo.save(stl);
                si++;
                ai++;
            } else if (cmp < 0) {
                // Settlement has no matching acquirer
                stl.setSettleStatus("UM");
                txnRepo.save(stl);
                unmatchedSettlement++;
                si++;
            } else {
                // Acquirer has no matching settlement
                unmatchedAcquirer++;
                ai++;
            }
        }

        // Remaining settlement records are unmatched
        while (si < pendingTxns.size()) {
            pendingTxns.get(si).setSettleStatus("UM");
            txnRepo.save(pendingTxns.get(si));
            unmatchedSettlement++;
            si++;
        }
        while (ai < acquirerConfirmations.size()) {
            unmatchedAcquirer++;
            ai++;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("matched_count", matchedCount);
        result.put("matched_amount", matchedAmount);
        result.put("unmatched_settlement_count", unmatchedSettlement);
        result.put("unmatched_acquirer_count", unmatchedAcquirer);
        result.put("amount_mismatch_count", amountMismatch);
        result.put("details", details);
        return result;
    }

    /**
     * STLMT300 - Calculate net settlement with fee aggregation.
     * Aggregates by network (VISA/MC/STAR), calculates 1.75% interchange fee.
     */
    @Transactional
    public Map<String, Object> calculateNetSettlement() {
        LocalDate settleDate = LocalDate.now();
        List<SettlementTransaction> allTxns = txnRepo.findBySettleDate(settleDate);

        // Delete existing summaries for this date
        summaryRepo.deleteBySettleDate(settleDate);

        // Group by network
        Map<String, List<SettlementTransaction>> byNetwork = allTxns.stream()
            .collect(Collectors.groupingBy(SettlementTransaction::getNetworkId));

        List<SettlementSummary> summaries = new ArrayList<>();
        BigDecimal grandTotalTxnAmount = BigDecimal.ZERO;
        int grandTotalTxnCount = 0;
        int grandTotalMatched = 0;
        BigDecimal grandTotalFees = BigDecimal.ZERO;
        BigDecimal grandTotalNet = BigDecimal.ZERO;

        for (Map.Entry<String, List<SettlementTransaction>> entry : byNetwork.entrySet()) {
            String network = entry.getKey();
            List<SettlementTransaction> netTxns = entry.getValue();

            SettlementSummary summary = new SettlementSummary();
            summary.setSettleDate(settleDate);
            summary.setNetworkId(network);
            summary.setTotalTxnCount(netTxns.size());

            BigDecimal totalAmount = netTxns.stream()
                .map(SettlementTransaction::getTxnAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
            summary.setTotalTxnAmount(totalAmount);

            List<SettlementTransaction> matched = netTxns.stream()
                .filter(t -> "MT".equals(t.getSettleStatus())).toList();
            summary.setMatchedCount(matched.size());
            summary.setMatchedAmount(matched.stream()
                .map(SettlementTransaction::getTxnAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add));

            List<SettlementTransaction> unmatched = netTxns.stream()
                .filter(t -> "UM".equals(t.getSettleStatus())).toList();
            summary.setUnmatchedCount(unmatched.size());
            summary.setUnmatchedAmount(unmatched.stream()
                .map(SettlementTransaction::getTxnAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add));

            List<SettlementTransaction> disputed = netTxns.stream()
                .filter(t -> "DI".equals(t.getSettleStatus())).toList();
            summary.setDisputedCount(disputed.size());
            summary.setDisputedAmount(disputed.stream()
                .map(SettlementTransaction::getTxnAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add));

            BigDecimal fees = summary.getMatchedAmount().multiply(INTERCHANGE_RATE)
                .setScale(2, RoundingMode.HALF_UP);
            summary.setTotalFees(fees);

            BigDecimal netAmount = summary.getMatchedAmount().subtract(fees);
            summary.setNetSettleAmount(netAmount);

            // Reconciliation status
            summary.setReconStatus(summary.getUnmatchedCount() == 0 && summary.getDisputedCount() == 0 ? "BL" : "OB");

            // Update interchange fees on matched transactions
            for (SettlementTransaction mt : matched) {
                mt.setInterchangeFee(mt.getTxnAmount().multiply(INTERCHANGE_RATE).setScale(2, RoundingMode.HALF_UP));
                txnRepo.save(mt);
            }

            summaryRepo.save(summary);
            summaries.add(summary);

            grandTotalTxnCount += summary.getTotalTxnCount();
            grandTotalTxnAmount = grandTotalTxnAmount.add(totalAmount);
            grandTotalMatched += summary.getMatchedCount();
            grandTotalFees = grandTotalFees.add(fees);
            grandTotalNet = grandTotalNet.add(netAmount);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("summaries", summaries);
        result.put("grand_total_txn_count", grandTotalTxnCount);
        result.put("grand_total_txn_amount", grandTotalTxnAmount);
        result.put("grand_total_matched_count", grandTotalMatched);
        result.put("grand_total_fees", grandTotalFees);
        result.put("grand_total_net_amount", grandTotalNet);
        return result;
    }

    /**
     * STLMT400 - Generate management report.
     */
    public Map<String, Object> generateManagementReport() {
        LocalDate settleDate = LocalDate.now();
        List<SettlementSummary> summaries = summaryRepo.findBySettleDate(settleDate);

        List<Map<String, Object>> networkDetails = new ArrayList<>();
        Map<String, Object> grandTotals = new LinkedHashMap<>();
        BigDecimal totalAmount = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        int totalTxns = 0;
        int totalMatched = 0;

        StringBuilder csv = new StringBuilder();
        csv.append("Network,Txn Count,Txn Amount,Matched,Unmatched,Disputed,Fees,Net Amount,Status\n");

        for (SettlementSummary s : summaries) {
            Map<String, Object> nd = new LinkedHashMap<>();
            nd.put("network_id", s.getNetworkId());
            nd.put("total_txn_count", s.getTotalTxnCount());
            nd.put("total_txn_amount", s.getTotalTxnAmount());
            nd.put("matched_count", s.getMatchedCount());
            nd.put("unmatched_count", s.getUnmatchedCount());
            nd.put("disputed_count", s.getDisputedCount());
            nd.put("interchange_fees", s.getTotalFees());
            nd.put("net_amount", s.getNetSettleAmount());
            nd.put("recon_status", s.getReconStatus());
            networkDetails.add(nd);

            csv.append(s.getNetworkId()).append(",")
                .append(s.getTotalTxnCount()).append(",")
                .append(s.getTotalTxnAmount()).append(",")
                .append(s.getMatchedCount()).append(",")
                .append(s.getUnmatchedCount()).append(",")
                .append(s.getDisputedCount()).append(",")
                .append(s.getTotalFees()).append(",")
                .append(s.getNetSettleAmount()).append(",")
                .append(s.getReconStatus()).append("\n");

            totalTxns += s.getTotalTxnCount();
            totalAmount = totalAmount.add(s.getTotalTxnAmount());
            totalMatched += s.getMatchedCount();
            totalFees = totalFees.add(s.getTotalFees());
            totalNet = totalNet.add(s.getNetSettleAmount());
        }

        grandTotals.put("total_txn_count", totalTxns);
        grandTotals.put("total_txn_amount", totalAmount);
        grandTotals.put("total_matched", totalMatched);
        grandTotals.put("total_fees", totalFees);
        grandTotals.put("total_net_amount", totalNet);

        Map<String, Object> report = new LinkedHashMap<>();
        report.put("report_date", settleDate.toString());
        report.put("network_details", networkDetails);
        report.put("grand_totals", grandTotals);
        report.put("csv_data", csv.toString());
        return report;
    }

    /** Get settlement transactions with optional filters. */
    public List<SettlementTransaction> getTransactions(String status, String network) {
        if (status != null && network != null) {
            return txnRepo.findBySettleStatusAndNetworkId(status, network);
        } else if (status != null) {
            return txnRepo.findBySettleStatus(status);
        } else if (network != null) {
            return txnRepo.findByNetworkId(network);
        }
        return txnRepo.findAll();
    }

    /** Get settlement summaries. */
    public List<SettlementSummary> getSummaries(String settleDate) {
        if (settleDate != null) {
            return summaryRepo.findBySettleDate(LocalDate.parse(settleDate));
        }
        return summaryRepo.findAll();
    }

    /** Generate sample transactions for testing. */
    public List<SettlementTransaction> generateSampleTransactions() {
        List<SettlementTransaction> txns = new ArrayList<>();
        ThreadLocalRandom rnd = ThreadLocalRandom.current();

        for (int i = 1; i <= 20; i++) {
            SettlementTransaction txn = new SettlementTransaction();
            txn.setTxnId(String.format("TXN%010d", i));
            txn.setCardNumber("4000120000001" + String.format("%03d", i));
            txn.setAccountNumber("10000000" + String.format("%04d", i));
            txn.setTxnType("PU");
            txn.setTxnAmount(BigDecimal.valueOf(rnd.nextDouble(10.0, 500.0)).setScale(2, RoundingMode.HALF_UP));
            txn.setTxnDate(LocalDate.now().minusDays(rnd.nextInt(0, 5)));
            int mIdx = i % MERCHANT_NAMES.length;
            txn.setMerchantId(MERCHANT_IDS[mIdx]);
            txn.setMerchantName(MERCHANT_NAMES[mIdx]);
            txn.setAcquirerId("ACQ00001");
            txn.setIssuerId("ISS00001");
            txn.setNetworkId(NETWORKS[i % NETWORKS.length]);
            txns.add(txn);
        }
        return txns;
    }

    /** Generate sample acquirer confirmations for matching. */
    public List<Map<String, Object>> generateSampleConfirmations() {
        List<SettlementTransaction> pendingTxns = txnRepo.findByStatusOrderByTxnId("PE");
        List<Map<String, Object>> confirmations = new ArrayList<>();
        ThreadLocalRandom rnd = ThreadLocalRandom.current();

        for (SettlementTransaction txn : pendingTxns) {
            double chance = rnd.nextDouble();
            if (chance < 0.1) {
                // 10% missing (unmatched)
                continue;
            }

            Map<String, Object> conf = new LinkedHashMap<>();
            conf.put("txn_id", txn.getTxnId());
            if (chance < 0.2) {
                // 10% amount mismatch
                conf.put("txn_amount", txn.getTxnAmount().add(BigDecimal.valueOf(rnd.nextDouble(1.0, 10.0)).setScale(2, RoundingMode.HALF_UP)));
            } else {
                // 80% exact match
                conf.put("txn_amount", txn.getTxnAmount());
            }
            conf.put("acquirer_id", txn.getAcquirerId());
            conf.put("confirmation_date", LocalDate.now().toString());
            confirmations.add(conf);
        }
        return confirmations;
    }

    /** Get CSV report as string. */
    public String getCsvReport() {
        Map<String, Object> report = generateManagementReport();
        return (String) report.get("csv_data");
    }

    /** Get settlement stats for dashboard. */
    public Map<String, Object> getSettlementStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("total_settlement_txns", txnRepo.count());
        stats.put("total_settlement_amount", txnRepo.sumAllTxnAmounts());
        stats.put("recent_settlements", summaryRepo.findAll().stream().limit(5).toList());
        return stats;
    }
}
