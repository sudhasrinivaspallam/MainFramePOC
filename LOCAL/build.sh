#!/bin/bash
###################################################################
# BUILD.SH - Compile all LOCAL COBOL programs using GnuCOBOL     #
# Usage: Run from the LOCAL directory                             #
#   cd LOCAL && bash build.sh                                     #
###################################################################

set -e

export PATH=/ucrt64/bin:$PATH
export COB_CONFIG_DIR=/ucrt64/share/gnucobol/config
export COB_COPY_DIR=/ucrt64/share/gnucobol/copy

COBOL_DIR="COBOL"
COPY_DIR="COPYBOOK"
BIN_DIR="BIN"
COBC="cobc"

# Ensure output directory exists
mkdir -p "$BIN_DIR"

PROGRAMS=(
    "PILOAD0"
    "GENDATA"
    "PICRD100"
    "PICRD200"
    "PICRD300"
    "PICRD400"
    "PIONL100"
    "PIONL200"
    "STLMT100"
    "STLSORT"
    "STLMT200"
    "STLMT300"
    "STLMT400"
)

PASS=0
FAIL=0

echo "========================================"
echo " MainFrame POC - GnuCOBOL Build"
echo "========================================"
echo ""

for PGM in "${PROGRAMS[@]}"; do
    SRC="$COBOL_DIR/${PGM}.cbl"
    OUT="$BIN_DIR/${PGM}"

    if [ ! -f "$SRC" ]; then
        echo "[SKIP] $PGM - source not found"
        continue
    fi

    echo -n "[BUILD] ${PGM}... "
    if $COBC -x -o "$OUT" "$SRC" -I "$COPY_DIR" 2>build_err.tmp; then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "FAILED"
        cat build_err.tmp
        FAIL=$((FAIL + 1))
    fi
    rm -f build_err.tmp
done

echo ""
echo "========================================"
echo " Build Summary: $PASS passed, $FAIL failed"
echo "========================================"
exit $FAIL
