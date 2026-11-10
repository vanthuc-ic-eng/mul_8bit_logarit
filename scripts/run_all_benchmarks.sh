#!/usr/bin/env bash
# ==============================================================================
# 1-CLICK UNIVERSAL BENCHMARK SUITE FOR 8-BIT MULTIPLIERS
# Runs:
#   1. Exhaustive 65,536-vector Mathematical Accuracy Verification (MRED, MED, WCE)
#   2. Nangate 45nm ASIC Standard-Cell Synthesis (Yosys)
#   3. AMD Zybo Z-7010 FPGA Physical Place & Route, STA & Power (Vivado 2024.2)
#   4. Aggregated Summary Reporting (Markdown & Terminal Table)
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

DESIGN_NAME="${DESIGN_NAME:-baseline}"
ARCH_TYPE="${ARCH_TYPE:-baseline}"
TOP_MODULE_FPGA="${TOP_MODULE_FPGA:-exact_mul_s8_registered}"
TOP_MODULE_ASIC="${TOP_MODULE_ASIC:-exact_mul_s8}"
TRUNC_BITS="${TRUNC_BITS:-4}"
QUAD_CURV="${QUAD_CURV:-0}"
USE_CARRY="${USE_CARRY:-1}"
REPORT_DIR="${REPORT_DIR:-reports/${DESIGN_NAME}}"

mkdir -p "${REPORT_DIR}" build

echo "================================================================================"
echo ">>> STARTING FULL BENCHMARK SUITE FOR: ${DESIGN_NAME}"
echo "    Architecture   : ${ARCH_TYPE}"
echo "    FPGA Top Module: ${TOP_MODULE_FPGA}"
echo "    ASIC Top Module: ${TOP_MODULE_ASIC}"
echo "    TRUNC_BITS     : ${TRUNC_BITS}"
echo "    QUAD_CURV      : ${QUAD_CURV}"
echo "    USE_CARRY      : ${USE_CARRY}"
echo "    Report Dir     : ${REPORT_DIR}"
echo "================================================================================"

# Step 1: Accuracy Verification
echo -e "\n[STEP 1/3] Running Exhaustive Mathematical Accuracy Verification (65,536 cases)..."
python3 "${SCRIPT_DIR}/verify_accuracy.py" \
    --arch "${ARCH_TYPE}" \
    --trunc "${TRUNC_BITS}" \
    --quad "${QUAD_CURV}" \
    --out "${REPORT_DIR}/accuracy.json"

# Step 2: Nangate 45nm ASIC Synthesis
echo -e "\n[STEP 2/3] Running Nangate 45nm ASIC Cell Synthesis..."
TOP_MODULE="${TOP_MODULE_ASIC}" \
DESIGN_NAME="${DESIGN_NAME}" \
TRUNC_BITS="${TRUNC_BITS}" \
QUAD_CURV="${QUAD_CURV}" \
REPORT_DIR="${REPORT_DIR}" \
bash "${SCRIPT_DIR}/benchmark_asic.sh"

# Step 3: AMD Vivado FPGA Implementation (Physical P&R + STA + Power)
echo -e "\n[STEP 3/3] Running AMD Vivado FPGA Physical Place & Route (Zybo Z-7010)..."
TOP_MODULE="${TOP_MODULE_FPGA}" \
DESIGN_NAME="${DESIGN_NAME}" \
TRUNC_BITS="${TRUNC_BITS}" \
QUAD_CURV="${QUAD_CURV}" \
USE_CARRY="${USE_CARRY}" \
REPORT_DIR="${REPORT_DIR}" \
vivado -mode batch -notrace -source "${SCRIPT_DIR}/benchmark_fpga.tcl" > "${REPORT_DIR}/vivado_pnr.log" 2>&1

echo -e "\n[PASS] All Benchmarks Completed for ${DESIGN_NAME}!"

# Step 4: Aggregate Summary
python3 "${SCRIPT_DIR}/parse_summary.py"
