# ==============================================================================
# INDUSTRIAL BENCHMARK & HARDWARE SUITE MAKEFILE (AMD ZYBO Z-7010 & NANGATE 45nm)
# Auto-detects Multiplier Architecture (Baseline vs LUT-ALM) from rtl/
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================

SHELL := /bin/bash

# --- Auto-detection of Architecture and Parameters ---
HAS_LUTALM := $(wildcard rtl/lutalm_mul_s8.v)

ifeq ($(strip $(HAS_LUTALM)),)
  ARCH       := baseline
  TOP_FPGA   := exact_mul_s8_registered
  TOP_ASIC   := exact_mul_s8
  DUT_TYPE   := baseline
  TARGET     := baseline
  TRUNC      ?= 0
  QUAD       ?= 0
  SIM_DEF    := -d EXACT_BASELINE
else
  ARCH       := lutalm
  TOP_FPGA   := lutalm_mul_s8_registered
  TOP_ASIC   := lutalm_mul_s8
  DUT_TYPE   := lutalm
  TARGET     := lutalm
  SIM_DEF    :=
  HAS_NANO   := $(shell grep -E "parameter\s+integer\s+MODE\s*=\s*2" rtl/lutalm_mul_s8.v 2>/dev/null)
  HAS_COMPACT:= $(shell grep -E "parameter\s+integer\s+MODE\s*=\s*1" rtl/lutalm_mul_s8.v 2>/dev/null)
  ifneq ($(strip $(HAS_NANO)),)
    MODE     := v10_nano
    MODE_VAL := 2
    LOW_W    ?= 1
    TRUNC    ?= 6
  else ifneq ($(strip $(HAS_COMPACT)),)
    MODE     := v9_ultra_compact
    MODE_VAL := 1
    LOW_W    ?= 2
    TRUNC    ?= 6
  else
    MODE     := v9_ultra
    MODE_VAL := 0
    LOW_W    ?= 2
    TRUNC    ?= 4
  endif
  QUAD       ?= 0
endif

USE_CARRY          ?= 1
OPERAND_ISOLATION  ?= 1
REPORT_DIR         ?= reports

# Git Metadata
GIT_TAG    := $(shell git describe --tags --exact-match 2>/dev/null || echo "")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

BIT_FILE   := bitstream/mult_8bit.bit

.PHONY: help all accuracy sim asic fpga clean \
        report report-accuracy report-func report-asic report-fpga report-timing info \
        bitstream program

# Default target
help:
	@echo "================================================================================"
	@echo "           8-BIT MULTIPLIER BENCHMARK & HARDWARE SUITE"
	@echo "================================================================================"
	@echo " Current Version:"
	@echo "   • Git Branch / Tag : $(GIT_BRANCH) $(if $(GIT_TAG),(Tag: $(GIT_TAG)),)"
	@echo "   • Architecture     : $(ARCH) (FPGA: $(TOP_FPGA) | ASIC: $(TOP_ASIC))"
	@echo "   • Parameters       : TRUNC=$(TRUNC) | QUAD=$(QUAD) | USE_CARRY=$(USE_CARRY)"
	@echo "   • Report Directory : $(REPORT_DIR)/"
	@echo "--------------------------------------------------------------------------------"
	@echo " Execution Commands (Run individual benchmark stages for this version):"
	@echo "   make sim              Run Vivado xsim RTL simulation across all 65,536 vectors"
	@echo "   make accuracy         Run exhaustive 65,536-case accuracy test (Python)"
	@echo "   make asic             Run Nangate 45nm standard cell synthesis via Yosys (1.8s)"
	@echo "   make quick-lut        Fast Vivado Synthesis to check LUT & CARRY count (~12s)"
	@echo "   make fpga             Run AMD Vivado Physical Implementation (P&R, STA, Power)"
	@echo "   make all              Run all benchmarks sequentially for this version"
	@echo ""
	@echo " Hardware On-Board Deployment & GUI Commands:"
	@echo "   make vivado           Open Vivado GUI with mult8bit_v3.xpr project"
	@echo "   make schematic        Directly launch Vivado GUI and display RTL Schematic"
	@echo "   make vivado-proj      Re-generate the Vivado .xpr project file"
	@echo "   make bitstream        Build physical .bit file for Digilent Zybo Z-7010 board"
	@echo "   make program          1-Click JTAG flash bitstream directly to board hardware"
	@echo ""
	@echo " Report Inspection Commands (View specific metrics of this version):"
	@echo "   make report           Display consolidated benchmark summary card"
	@echo "   make report-func      Generate official functional verification report (.md, .docx, .csv)"
	@echo "   make report-accuracy  Display MRED, Mean Error (MED), and Worst-Case Error"
	@echo "   make report-asic      Display standard cell count and Nangate 45nm silicon area"
	@echo "   make report-fpga      Display Slice LUTs, CARRY4, Levels, Delay, Fmax, Power"
	@echo "   make report-timing    Display critical timing path analysis (Slack, Logic/Route)"
	@echo ""
	@echo " Maintenance Commands:"
	@echo "   make clean            Wipe all build artifacts, EDA logs, reports, and bitstreams"
	@echo "   make info             Show active configuration parameters"
	@echo "================================================================================"

info:
	@echo "Version Tag     : $(GIT_TAG)"
	@echo "Branch          : $(GIT_BRANCH)"
	@echo "Commit          : $(GIT_COMMIT)"
	@echo "Architecture    : $(ARCH)"
	@echo "FPGA Top Module : $(TOP_FPGA)"
	@echo "ASIC Top Module : $(TOP_ASIC)"
	@echo "TRUNC_BITS      : $(TRUNC)"
	@echo "QUAD_CURV       : $(QUAD)"
	@echo "USE_CARRY       : $(USE_CARRY)"
	@echo "Report Dir      : $(REPORT_DIR)"

# --- 2. Benchmark Execution Targets ---

sim:
	@mkdir -p $(REPORT_DIR) build
	@echo ">>> [1/4] Compiling and Running Vivado xsim Simulation (65,536 vectors)..."
	@xvlog -nolog $(SIM_DEF) rtl/*.v sim/tb_mul_8bit.v
	@xelab -nolog $(SIM_DEF) -top tb_mul_8bit -s sim_snapshot $(if $(filter baseline,$(ARCH)),,-generic_top "MODE=$(MODE_VAL)" -generic_top "OPERAND_ISOLATION=$(OPERAND_ISOLATION)")
	@xsim sim_snapshot -nolog -R | tee $(REPORT_DIR)/simulation.log
	@if [ -f $(REPORT_DIR)/simulation_vectors.csv ]; then \
		echo ">>> [2/4] Generating Exhaustive 65,536-Vector Excel Lookup Workbooks..."; \
		python3 scripts/gen_excel_lookup.py \
			--csv $(REPORT_DIR)/simulation_vectors.csv \
			--out-vn $(REPORT_DIR)/Bang_tra_cuu_65536_vectors.xlsx \
			--out-en $(REPORT_DIR)/Vector_Lookup_Table_65536.xlsx \
			--arch "$(DUT_TYPE) ($(if $(filter baseline,$(ARCH)),Baseline Exact,MODE=$(MODE_VAL)))"; \
	fi

accuracy:
	@mkdir -p $(REPORT_DIR)
	@echo ">>> [1/3] Running Exhaustive Mathematical Accuracy Verification ($(MODE))..."
	@python3 scripts/verify_accuracy.py \
		--arch $(MODE) \
		--trunc $(TRUNC) \
		--quad $(QUAD) \
		--out $(REPORT_DIR)/accuracy.json

quick-lut:
	@echo ">>> Fast Vivado Logic Synthesis (Checking LUT & CARRY count in ~12s)..."
	@vivado -mode batch -notrace -source scripts/quick_synth.tcl 2>/dev/null | grep -E "(Slice LUTs|LUT as Logic|CARRY4)"

asic:
	@mkdir -p $(REPORT_DIR) build
	@echo ">>> [2/3] Running Nangate 45nm ASIC Synthesis ($(TOP_ASIC))..."
	@TOP_MODULE=$(TOP_ASIC) \
	 DESIGN_NAME=$(TARGET) \
	 MODE_VAL=$(MODE_VAL) \
	 OPERAND_ISOLATION=$(OPERAND_ISOLATION) \
	 TRUNC_BITS=$(TRUNC) \
	 QUAD_CURV=$(QUAD) \
	 REPORT_DIR=$(REPORT_DIR) \
	 bash scripts/benchmark_asic.sh

fpga:
	@mkdir -p $(REPORT_DIR) build
	@echo ">>> [3/3] Running AMD Vivado FPGA Implementation ($(TOP_FPGA))..."
	@TOP_MODULE=$(TOP_FPGA) \
	 DESIGN_NAME=$(TARGET) \
	 MODE_VAL=$(MODE_VAL) \
	 OPERAND_ISOLATION=$(OPERAND_ISOLATION) \
	 TRUNC_BITS=$(TRUNC) \
	 QUAD_CURV=$(QUAD) \
	 USE_CARRY=$(USE_CARRY) \
	 REPORT_DIR=$(REPORT_DIR) \
	 vivado -mode batch -notrace -source scripts/benchmark_fpga.tcl > $(REPORT_DIR)/vivado_pnr.log 2>&1
	@echo "[PASS] FPGA Implementation Complete: $(REPORT_DIR)"

all: accuracy asic fpga report

# --- 3. Hardware Deployment & Vivado GUI Targets ---

vivado-proj:
	@vivado -mode batch -source scripts/create_vivado_project.tcl

vivado: vivado/mult8bit_v3.xpr
	@vivado vivado/mult8bit_v3.xpr &

schematic:
	@vivado -mode gui -source scripts/open_schematic.tcl &

bitstream:
	@bash scripts/build_bitstream.sh $(DUT_TYPE)

program:
	@bash scripts/program_fpga.sh $(BIT_FILE)

# --- 4. Report Inspection Targets ---

report-func:
	@python3 scripts/generate_functional_report.py --arch $(TARGET) --trunc $(TRUNC) --quad $(QUAD)

report-accuracy:
	@python3 scripts/parse_summary.py --dir $(REPORT_DIR) --show accuracy

report-asic:
	@python3 scripts/parse_summary.py --dir $(REPORT_DIR) --show asic

report-fpga:
	@python3 scripts/parse_summary.py --dir $(REPORT_DIR) --show fpga

report-timing:
	@if [ -f $(REPORT_DIR)/critical_path.rpt ]; then \
		cat $(REPORT_DIR)/critical_path.rpt; \
	elif [ -f $(REPORT_DIR)/pnr_timing_100mhz.rpt ]; then \
		head -n 50 $(REPORT_DIR)/pnr_timing_100mhz.rpt; \
	else \
		echo "No timing report found in $(REPORT_DIR). Run 'make fpga' first."; \
	fi

report:
	@python3 scripts/parse_summary.py --dir $(REPORT_DIR) --show summary

# --- 5. Clean Target ---

clean:
	@rm -rf build/* .Xil .xil *.jou *.log clockInfo.txt $(REPORT_DIR)/* bitstream/*
	@mkdir -p $(REPORT_DIR) build bitstream
	@echo "[OK] Cleaned all build artifacts, EDA logs, reports, and bitstreams."
