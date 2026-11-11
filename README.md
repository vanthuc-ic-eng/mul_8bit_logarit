# Low-Power Approximate Logarithmic Multiplier Architectures for Edge Computing
**Repository:** `mul_8bit_logarit`  
**Author:** NGUYEN VAN THUC (Student ID: 24161421) - Lead of Team Conquerors  
**Affiliation:** Ho Chi Minh City University of Technology and Education (HCMUTE)  
**Target Platform:** Digilent Zybo Z7 (AMD Zynq-7000 `xc7z010clg400-1`)  
**Target ASIC Library:** Nangate 45-nm Open Cell Library (`normal.lib`)  

---

## 1. Official Contest Submission Architecture Portfolio

This repository contains the official, industrial-grade implementation of 8-bit signed multiplier architectures developed for the Design Contest 2026. The project delivers a clean, verified progression from the contest exact baseline to breakthrough Look-Up Table Approximate Logarithmic Multipliers (LUT-ALM):

| Version | Branch / Tag | Architecture Variant | Slice LUTs | CARRY4 | Critical Delay | Fmax (MHz) | Dynamic Power | Arithmetic MRED | Peak Error (WCE) | ASIC 45nm Area |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Baseline** | `baseline` / `v0.0.0` | **Exact Array Multiplier (BTC)** | 150 | 0 | 9.814 ns | 101.9 MHz | 4.00 mW | 0.0000% | 0 | 350.32 µm² |
| **Bản Nano** | `v0.1.1` / `v1.1` | **LUT-ALM V10-Nano Extreme** | **34** | **0** | **5.584 ns** | **179.1 MHz** | **1.00 mW** | **16.5127%** | **4352** | **180.08 µm²** |
| **Bản Sweet-Spot** | `v0.2.0` / `v2` | **LUT-ALM V11-Lean Flex** | **47** | **2** | **6.455 ns** | **154.9 MHz** | **1.00 mW** | **5.5861%** | **1472** | **407.78 µm²** |

---

## 2. Active Version: `v0.2.0` (LUT-ALM V11-Lean Flex Sweet-Spot Multiplier)

- **Architecture:** Look-Up Table Approximate Logarithmic Multiplier (LUT-ALM) V11-Lean Flex (`lutalm_mul_s8`, MODE=1).
- **Architectural Breakthroughs:**
  - **Fused 1's Complement Clamp:** Replaces two's complement adders with a single-gate clamp, saving ~14 LUTs at the input stage and preventing false zero errors for $A = -128$ and $B = -128$.
  - **Compact 8-to-6 Boolean LOD:** Direct priority mapping extracting 3-bit exponent and 3-bit mantissa.
  - **Zero-Cost Constant Bias Correction ($C_{in} = 1'b1$):** Connects carry-in to logic 1 on the logarithmic adder, neutralizing Mitchell's under-estimation bias with 0 additional logic overhead.
  - **Asymmetric Tail Injection:** Enforces normalized mantissa `mant_w = {1'b1, frac_w, 1'b1}`, balancing positive and negative truncation errors.
  - **Native 12-bit FPGA Antilog Shifter:** P&R optimized directly for Xilinx 7-Series slice architecture.
- **FPGA Physical Implementation (AMD Zybo Z7-10 `xc7z010clg400-1`):**
  - **47 Slice LUTs** (Dead-center of the 40–50 LUT budget; **-68.7% reduction** vs. baseline).
  - **2 CARRY4** primitives, **28 Slice Flip-Flops**.
  - **6.455 ns** critical path delay ($F_{\max} = 154.92\text{ MHz}$, **Slack = +3.492 ns** at 100 MHz, **+52.0% faster** than baseline).
  - **1.00 mW** dynamic power @ 100 MHz (**-75.0% reduction** vs. baseline).
- **ASIC 45-nm Implementation (Nangate 45nm OpenCellLibrary):**
  - **245 standard cells**, **407.78 µm²** total cell area (Combinational core: ~280 µm²).
  - **0.910 ns** STA delay ($F_{\max} = 1.099\text{ GHz}$), **77.30 µW** total power.
- **Mathematical Accuracy:**
  - Exhaustive 65,536-vector INT8 Two's Complement Sweep ($[-128, 127] \times [-128, 127]$).
  - **$\text{MRED} = 5.5861\%$** (Well below the 8.0% design contest target; -66.2% error reduction vs. v0.1.1).
  - **$\text{WCE} = 1472$** (Peak error reduced by 66.2% vs. v0.1.1's 4352).
  - **$\text{MED} = 158.47$** (Mean error distance reduced by 69.2% vs. v0.1.1).
  - Symmetric Neural Domain ($[-127, 127] \times [-127, 127]$): $\text{MRED} = 5.6070\%$, $\text{MED} = 158.31$, $\text{WCE} = 1472$.
  - Exact Zero-Error Matches: 1,156 vectors ($1.76\%$).
- **Verification Deliverables:**
  - [`reports/Bang_tra_cuu_65536_vectors.xlsx`](file:///workspace/projects/mul_8bit_logarit/reports/Bang_tra_cuu_65536_vectors.xlsx) — Full 65,536-vector lookup workbook with color conditional formatting (Vietnamese).
  - [`reports/Vector_Lookup_Table_65536.xlsx`](file:///workspace/projects/mul_8bit_logarit/reports/Vector_Lookup_Table_65536.xlsx) — Full 65,536-vector lookup workbook formatted for IEEE/international contest sign-off (English).
  - [`reports/simulation_vectors.csv`](file:///workspace/projects/mul_8bit_logarit/reports/simulation_vectors.csv) — Bit-accurate hardware simulation trace generated directly from AMD Vivado Simulator (`xsim`).
  - [`reports/simulation.log`](file:///workspace/projects/mul_8bit_logarit/reports/simulation.log) — Cycle-accurate simulation sign-off log.

---

## 3. Directory Layout

```
mul_8bit_logarit/
├── Makefile                          # Unified build and automation interface
├── rtl/                              # Flat, monolithic RTL source files
│   ├── lutalm_mul_s8.v               # Monolithic 8-bit multiplier core (MODE=0, 1, 2)
│   ├── lutalm_mul_s8_registered.v    # Registered benchmark wrapper for Reg2Reg STA
│   └── top_board_test.v              # Hardware verification on Zybo Z7-10 board
├── sim/                              # Exhaustive verification testbench
│   └── tb_mul_8bit.v                 # Exhaustive 65,536-vector testbench
├── reports/                          # Complete 47-report un-truncated EDA sign-off suite
│   ├── Bang_tra_cuu_65536_vectors.xlsx# Full 65,536-vector lookup workbook (Vietnamese)
│   ├── Vector_Lookup_Table_65536.xlsx # Full 65,536-vector lookup workbook (IEEE English)
│   ├── simulation_vectors.csv        # Hardware simulation trace directly from xsim
│   ├── simulation.log                # Cycle-accurate simulation sign-off log
│   ├── pnr_util.rpt                  # Post-route utilization report
│   ├── pnr_timing_100mhz.rpt         # Post-route STA timing report at 100 MHz
│   ├── pnr_power_100mhz.rpt          # Vector activity power report at 100 MHz
│   ├── critical_path.rpt             # Critical path timing report
│   ├── deep_fpga_signoff_summary.rpt # Multi-corner & thermal sign-off summary
│   ├── datasheet.rpt                 # Timing datasheet report
│   ├── asic_stat.rpt                 # Nangate 45nm cell utilization
│   ├── asic_timing.rpt               # Nangate 45nm STA timing report
│   ├── asic_power.rpt                # Nangate 45nm power report
│   └── ...                           # Thermal sweep (-40°C to 100°C), voltage corners
├── scripts/                          # Automated EDA synthesis & evaluation scripts
├── constrs/                          # Pinout constraints (zybo_z7.xdc)
└── lib/                              # Nangate 45-nm standard cell library
```

---

## 4. Quick Execution Protocol

```bash
# 1. Run exhaustive 65,536-vector RTL simulation & generate Excel lookup table
make sim

# 2. Run mathematical accuracy evaluation
make accuracy

# 3. Run Nangate 45-nm ASIC synthesis & STA via Yosys + OpenSTA
make asic

# 4. Run complete AMD Vivado FPGA Implementation (P&R, timing, power sweeps)
make fpga

# 5. Display consolidated PPA and accuracy metrics
make report
```
