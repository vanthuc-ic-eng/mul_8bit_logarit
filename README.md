# Low-Power Approximate Logarithmic Multiplier Architectures for Edge Computing
**Repository:** `mul_8bit_logarit`  
**Author:** NGUYEN VAN THUC (Student ID: 24161421) - Lead of Team Conquerors  
**Affiliation:** Ho Chi Minh City University of Technology and Education (HCMUTE)  
**Target Platform:** Digilent Zybo Z7 (AMD Zynq-7000 `xc7z010clg400-1`)  
**Target ASIC Library:** Nangate 45-nm Open Cell Library (`normal.lib`)  

---

## 1. Project Overview & Architecture Lineage

This repository contains the official, industrial-grade implementation of 8-bit signed multiplier architectures developed for the Design Contest 2026. The project delivers a clean, verified progression from the contest exact baseline to breakthrough Look-Up Table Approximate Logarithmic Multipliers (LUT-ALM):

| Version | Branch / Tag | Architecture Variant | Slice LUTs | Logic Levels | Critical Delay | Dynamic Power | Arithmetic MRED | ASIC 45nm Area |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Baseline** | `baseline` / `v0.0.0` | **Exact Array Multiplier (BTC)** | 150 | 10 | 9.814 ns | 4.00 mW | 0.0000% | 350.32 µm² |
| **Release 1** | `v1` / `v0.1.0` | **LUT-ALM V9-Ultra Balanced** | 62 | 8 | 7.459 ns | 1.00 mW | 3.7660% | 284.89 µm² |
| **Release 2** | `main` / `v0.1.1` | **LUT-ALM V10-Nano (Beyond-the-Box)** | **36** | **5** | **6.366 ns** | **1.00 mW** | **7.8184%** | **180.08 µm²** |

---

## 2. Active Version: `v0.1.0` (LUT-ALM V9-Ultra Balanced Multiplier)

- **Architecture:** Look-Up Table Approximate Logarithmic Multiplier (LUT-ALM) V9-Ultra Balanced (`lutalm_mul_s8`, MODE=0).
- **Mathematical Accuracy:** High-precision logarithmic approximation across all $65,536$ vectors in $[-128, 127] \times [-128, 127]$. $\text{MRED} = 3.7660\%$, $\text{MED} = 114.0757$, $\text{WCE} = 1089$ (at $A = -95, B = -95$), Exact Matches = $1,251$ ($1.91\%$).
- **FPGA Physical Implementation:** 62 Slice LUTs (**-58.7% reduction** vs. baseline 150 LUTs), 8 Logic Levels, 7.459 ns critical path ($F_{\max} = 134.07\text{ MHz}$, **+31.6% faster** than baseline), 1.00 mW dynamic power @ 100 MHz (**-75.0% dynamic power reduction**).
- **ASIC 45-nm Implementation:** 257 standard cells, 284.89 µm² area (**-18.7% reduction** vs. baseline 350.32 µm²), 1.040 ns delay, 53.64 µW total dynamic power.
- **Verification Deliverables:**
  - `reports/Bang_tra_cuu_65536_vectors.xlsx` — Full 65,536-vector lookup workbook with color conditional formatting (Vietnamese).
  - `reports/Vector_Lookup_Table_65536.xlsx` — Full 65,536-vector lookup workbook formatted for IEEE/international contest sign-off (English).
  - `reports/simulation_vectors.csv` — Bit-accurate hardware simulation trace generated directly from AMD Vivado Simulator (`xsim`).

---

## 3. Directory Layout

```
mul_8bit_logarit/
├── Makefile                          # Unified build and automation interface
├── rtl/                              # Flat RTL source files for active version
│   ├── lutalm_mul_s8_registered.v    # Registered benchmark wrapper
│   ├── lutalm_mul_s8.v               # Top combinational LUT-ALM core
│   ├── log_encoder_u8.v              # Leading-one detector & logarithmic encoder
│   ├── log_adder_u8.v                # Logarithmic adder core
│   ├── log_antilog_u16.v             # Antilogarithmic converter core
│   └── ...                           # Low-order fraction converters & primitives
├── sim/                              # Exhaustive verification testbench
│   └── tb_mul_8bit.v                 # Exhaustive 65,536-vector testbench
├── reports/                          # Complete un-truncated EDA sign-off suite
│   ├── Bang_tra_cuu_65536_vectors.xlsx# Full 65,536-vector lookup workbook (Vietnamese)
│   ├── Vector_Lookup_Table_65536.xlsx # Full 65,536-vector lookup workbook (IEEE English)
│   ├── simulation_vectors.csv        # Hardware simulation trace directly from xsim
│   ├── pnr_util.rpt                  # Post-route utilization report
│   ├── critical_path.rpt             # Post-route critical path timing report
│   ├── deep_fpga_signoff_summary.rpt # Multi-corner & thermal sign-off summary
│   └── ...                           # Multi-frequency (50/100/105/110 MHz), thermal (-40°C to 100°C)
├── scripts/                          # Automated EDA synthesis & evaluation scripts
├── constrs/                          # Pinout constraints (zybo_z7.xdc)
└── lib/                              # Nangate 45-nm standard cell library
```

---

## 4. Quick Execution Protocol

```bash
# 1. Exhaustive 65,536-vector functional verification
make sim

# 2. Complete FPGA synthesis, placement, routing & multi-corner sign-off (Vivado 2024.2)
make pnr

# 3. Standard cell ASIC synthesis & timing sign-off (Yosys + OpenSTA 45nm)
make asic

# 4. Generate all EDA summaries and multi-temperature reports
make report

# 5. Export 65,536-vector Excel lookup tables
make excel
```

---

## 5. Branch & Version Switching Protocol

To switch between architectures in this clean repository:

```bash
# Switch to Baseline Exact Multiplier (150 LUTs, 0.0000% error)
git checkout baseline
# Or: git checkout v0.0.0

# Switch to LUT-ALM V9-Ultra Balanced (62 LUTs, 3.7660% MRED)
git checkout v1
# Or: git checkout v0.1.0

# Switch to LUT-ALM V10-Nano Beyond-the-Box (36 LUTs, 7.8184% MRED, 180.08 µm² ASIC area)
git checkout main
# Or: git checkout v0.1.1
```
