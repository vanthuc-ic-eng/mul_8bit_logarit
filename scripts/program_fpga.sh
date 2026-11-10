#!/usr/bin/env bash
# ==============================================================================
# 1-CLICK JTAG HARDWARE PROGRAMMING SCRIPT FOR DIGILENT ZYBO Z-7010
# Plug in USB-JTAG cable and execute this script to program FPGA immediately.
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

BIT_FILE="${1:-bitstream/mult_8bit.bit}"

if [ ! -f "${BIT_FILE}" ]; then
    echo "=================================================================="
    echo "[!] Bitstream file not found at: ${BIT_FILE}"
    echo "    Building bitstream automatically now..."
    echo "=================================================================="
    bash "${SCRIPT_DIR}/build_bitstream.sh"
fi

echo "=================================================================="
echo ">>> EXECUTING 1-CLICK JTAG PROGRAMMING"
echo "    Board Target : Digilent Zybo Z-7010"
echo "    Bitstream    : ${BIT_FILE}"
echo "=================================================================="

vivado -mode batch -notrace -source "${SCRIPT_DIR}/program_fpga.tcl" -tclargs "${BIT_FILE}"
