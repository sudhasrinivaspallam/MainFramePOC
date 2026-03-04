#!/bin/bash
###################################################################
# RUN.SH - Execute the complete Plastic Issuance & Settlement    #
#           pipeline end-to-end.                                  #
# Usage: Run from the LOCAL directory                             #
#   cd LOCAL && bash run.sh                                       #
###################################################################

set -e

export PATH=/ucrt64/bin:$PATH

BIN_DIR="BIN"
DATA_DIR="DATA"
OUTPUT_DIR="OUTPUT"

# Ensure directories exist
mkdir -p "$DATA_DIR" "$OUTPUT_DIR"

echo "========================================"
echo " MainFrame POC - End-to-End Execution"
echo "========================================"
echo ""

run_program() {
    local PGM=$1
    local DESC=$2
    local INPUT=$3

    echo "----------------------------------------"
    echo " Running: $PGM - $DESC"
    echo "----------------------------------------"

    if [ ! -f "$BIN_DIR/$PGM" ]; then
        echo "[ERROR] $PGM binary not found. Run build.sh first."
        return 1
    fi

    if [ -n "$INPUT" ]; then
        "$BIN_DIR/$PGM" < "$INPUT"
    else
        "$BIN_DIR/$PGM"
    fi

    RC=$?
    if [ $RC -ne 0 ]; then
        echo "[WARNING] $PGM exited with RC=$RC"
    else
        echo "[OK] $PGM completed successfully"
    fi
    echo ""
    return 0
}

# ================================================================
# PHASE 1: PLASTIC ISSUANCE
# ================================================================
echo ""
echo "============ PHASE 1: PLASTIC ISSUANCE ============"
echo ""

# Step 1: Load test data (creates CARDMAST.dat)
run_program "PILOAD0" "Load Test Card Data"

# Step 2: Generate all test input data files
run_program "GENDATA" "Generate Test Input Data"

# Step 3: Issue new cards (batch - reads CARDINP.dat)
run_program "PICRD100" "Card Issuance"

# Step 4: Activate cards (batch - reads ACTVINP.dat)
run_program "PICRD200" "Card Activation"

# Step 5: Card status updates (batch - reads STSINP.dat)
run_program "PICRD300" "Card Status Update"

# Step 6: Card renewal (batch - no input needed)
run_program "PICRD400" "Card Renewal"

# Step 7: Card inquiry (interactive - uses stdin input file)
run_program "PIONL100" "Card Inquiry" "$DATA_DIR/INQINP.dat"

# Step 8: Card update (interactive - uses stdin input file)
run_program "PIONL200" "Card Update" "$DATA_DIR/UPDINP.dat"

# ================================================================
# PHASE 2: SETTLEMENT
# ================================================================
echo ""
echo "============ PHASE 2: SETTLEMENT ============"
echo ""

# Step 9: Network extract (processes TXN input)
run_program "STLMT100" "Network Extract"

# Step 10: Sort VSAM to sequential
run_program "STLSORT" "Sort Settlement VSAM to Sequential"

# Step 11: Transaction matching
run_program "STLMT200" "Transaction Matching"

# Step 12: Net settlement calculation
run_program "STLMT300" "Net Settlement"

# Step 13: Management report + SAS feed
run_program "STLMT400" "Management Report"

# ================================================================
# SUMMARY
# ================================================================
echo ""
echo "========================================"
echo " Pipeline Complete"
echo "========================================"
echo ""
echo "Output files:"
ls -la "$OUTPUT_DIR"/ 2>/dev/null || echo "  (no output files)"
echo ""
echo "Data files:"
ls -la "$DATA_DIR"/ 2>/dev/null || echo "  (no data files)"
