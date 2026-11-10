#!/usr/bin/env bash
# ==============================================================================
# 1-CLICK BITSTREAM BUILD SCRIPT FOR DIGILENT ZYBO Z-7010
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

DUT_TYPE="${1:-}"

if [ -z "${DUT_TYPE}" ]; then
    if [ -f "rtl/lutalm_mul_s8.v" ]; then
        DUT_TYPE="lutalm"
    else
        DUT_TYPE="baseline"
    fi
fi

mkdir -p bitstream build

echo "=================================================================="
echo ">>> STARTING 1-CLICK BITSTREAM GENERATION"
echo "    Board Target : Digilent Zybo Z-7010 (xc7z010clg400-1)"
echo "    Architecture : ${DUT_TYPE}"
echo "=================================================================="

DUT_TYPE="${DUT_TYPE}" vivado -mode batch -notrace -source "${SCRIPT_DIR}/build_bitstream.tcl"

BIT_PATH="${ROOT_DIR}/bitstream/mult_8bit.bit"
if [ -f "${BIT_PATH}" ]; then
    echo -e "\n[PASS] Bitstream ready: ${BIT_PATH}"
    echo "To program onto board via JTAG, run:"
    echo "   ./scripts/program_fpga.sh"
    echo "   (or 'make program')"
else
    echo -e "\n[ERROR] Bitstream was not generated. Check Vivado logs." >&2
    exit 1
fi
