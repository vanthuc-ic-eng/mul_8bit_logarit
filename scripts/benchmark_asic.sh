#!/usr/bin/env bash
# ==============================================================================
# UNIVERSAL ASIC SYNTHESIS & STA/POWER BENCHMARK (Yosys + OpenSTA + Nangate 45nm)
# Target Library: Nangate 45nm typical (lib/nangate45/normal.lib)
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

TOP_MODULE="${TOP_MODULE:-exact_mul_s8}"
DESIGN_NAME="${DESIGN_NAME:-baseline}"
MODE_VAL="${MODE_VAL:-2}"
OPERAND_ISOLATION="${OPERAND_ISOLATION:-1}"
TRUNC_BITS="${TRUNC_BITS:-4}"
QUAD_CURV="${QUAD_CURV:-0}"
REPORT_DIR="${REPORT_DIR:-reports}"
LIB="${ROOT_DIR}/lib/nangate45/normal.lib"

mkdir -p "${REPORT_DIR}" build

echo "=================================================================="
echo ">>> PROFILING ASIC (Nangate 45nm): ${DESIGN_NAME} (${TOP_MODULE})"
echo ">>> Parameters: TRUNC=${TRUNC_BITS} | QUAD=${QUAD_CURV}"
echo ">>> Output Dir: ${REPORT_DIR}"
echo "=================================================================="

if [ ! -f "${LIB}" ]; then
    echo "ERROR: Nangate 45nm library not found at ${LIB}" >&2
    exit 1
fi

YS_SCRIPT="build/synth_asic_${DESIGN_NAME}.ys"
NETLIST="build/netlist_${DESIGN_NAME}.v"

# Collect all verilog files under rtl/ (excluding board test top)
mapfile -t RTL_FILES < <(find rtl -maxdepth 1 -type f -name "*.v" ! -name "top_board_test.v" | sort)

{
    echo "# Yosys synthesis script for ${DESIGN_NAME}"
    for f in "${RTL_FILES[@]}"; do
        echo "read_verilog ${f}"
    done
    CHPARAMS=""
    if [ "${TOP_MODULE}" != "exact_mul_s8" ]; then
        TOP_FILE=$(grep -l -E "\bmodule\s+${TOP_MODULE}\b" "${RTL_FILES[@]}" 2>/dev/null | head -n 1 || true)
        if [ -n "${TOP_FILE}" ] && [ -f "${TOP_FILE}" ]; then
            if grep -q "parameter.*MODE" "${TOP_FILE}"; then
                CHPARAMS="${CHPARAMS} -chparam MODE ${MODE_VAL}"
            fi
            if grep -q "parameter.*OPERAND_ISOLATION" "${TOP_FILE}"; then
                CHPARAMS="${CHPARAMS} -chparam OPERAND_ISOLATION ${OPERAND_ISOLATION}"
            fi
            if grep -q "parameter.*TRUNC_BITS" "${TOP_FILE}"; then
                CHPARAMS="${CHPARAMS} -chparam TRUNC_BITS ${TRUNC_BITS}"
            fi
            if grep -q "parameter.*QUAD_CURV" "${TOP_FILE}"; then
                CHPARAMS="${CHPARAMS} -chparam QUAD_CURV ${QUAD_CURV}"
            fi
        fi
    fi

    if [ -n "${CHPARAMS}" ]; then
        echo "hierarchy -check -top ${TOP_MODULE}${CHPARAMS}"
    else
        echo "hierarchy -check -top ${TOP_MODULE}"
    fi
    echo "synth -top ${TOP_MODULE} -flatten"
    echo "opt -purge"
    echo "opt"
    echo "abc -liberty ${LIB}"
    echo "clean"
    echo "tee -o ${REPORT_DIR}/asic_stat.rpt stat -liberty ${LIB}"
    echo "write_verilog -noattr -noexpr ${NETLIST}"
} > "${YS_SCRIPT}"

# 1. Run Logic Synthesis
yosys -s "${YS_SCRIPT}" > "${REPORT_DIR}/yosys_synth.log" 2>&1

CELLS=$(grep "Number of cells:" "${REPORT_DIR}/asic_stat.rpt" | awk '{print $NF}')
AREA=$(grep "Chip area for module" "${REPORT_DIR}/asic_stat.rpt" | awk '{print $NF}')

echo "[PASS] ASIC Synthesis Successful: ${DESIGN_NAME}"
echo "       Cells: ${CELLS}"
echo "       Area : ${AREA} um^2"

# 2. Run OpenSTA Static Timing & Power Analysis (if sta is available)
if command -v sta >/dev/null 2>&1; then
    STA_SCRIPT="build/sta_${DESIGN_NAME}.tcl"
    cat << STA_EOF > "${STA_SCRIPT}"
read_liberty ${LIB}
read_verilog ${NETLIST}
link_design ${TOP_MODULE}
create_clock -name clk -period 10.0
set_input_delay -clock clk 0.0 [all_inputs]
set_output_delay -clock clk 0.0 [all_outputs]
report_checks -path_delay max -format full > ${REPORT_DIR}/asic_timing.rpt
report_power > ${REPORT_DIR}/asic_power.rpt
exit
STA_EOF

    sta "${STA_SCRIPT}" > "${REPORT_DIR}/opensta.log" 2>&1

    DELAY=$(grep -E "\s+[0-9\.]+\s+data arrival time" "${REPORT_DIR}/asic_timing.rpt" | head -n 1 | awk '{print $1}')
    TOTAL_PWR=$(grep -E "^Total\s+" "${REPORT_DIR}/asic_power.rpt" | awk '{printf "%.2f", $5 * 1000000}')
    DYN_PWR=$(grep -E "^Total\s+" "${REPORT_DIR}/asic_power.rpt" | awk '{printf "%.2f", ($2 + $3) * 1000000}')
    LEAK_PWR=$(grep -E "^Total\s+" "${REPORT_DIR}/asic_power.rpt" | awk '{printf "%.2f", $4 * 1000000}')

    echo "       STA Delay  : ${DELAY} ns"
    echo "       Total Power: ${TOTAL_PWR} uW (Dyn: ${DYN_PWR} uW, Leak: ${LEAK_PWR} uW)"
fi

echo "=================================================================="
