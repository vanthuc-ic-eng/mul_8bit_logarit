# Low-Power Approximate Logarithmic Multiplier Architectures for Edge Computing
**Repository:** `mul_8bit_logarit`  
**Author:** NGUYEN VAN THUC (Student ID: 24161421) - Lead of Team Conquerors  
**Affiliation:** Ho Chi Minh City University of Technology and Education (HCMUTE)  
**Target Platform:** Digilent Zybo Z7 (AMD Zynq-7000 `xc7z010clg400-1`)  
**Target ASIC Library:** Nangate 45-nm Open Cell Library (`normal.lib`)  

---

## 1. Project Overview & Architecture Lineage

This repository contains the official, industrial-grade implementation of 8-bit signed multiplier architectures developed for the Design Contest 2026. The project delivers a clean, verified progression from the contest exact baseline to breakthrough Look-Up Table Approximate Logarithmic Multipliers (LUT-ALM):

| Version | Git Tag | Architecture Variant | Slice LUTs | Logic Levels | Critical Delay | Dynamic Power | Arithmetic MRED | ASIC 45nm Area |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Baseline** | `v0.0.0` | **Exact Array Multiplier (BTC)** | 150 | 10 | 9.814 ns | 4.00 mW | 0.0000% | 350.32 µm² |
| **Release 1** | `v0.1.0` | **LUT-ALM V9-Ultra Balanced** | 62 | 8 | 7.459 ns | 1.00 mW | 3.7660% | 284.89 µm² |
| **Release 2** | `v0.1.1` | **LUT-ALM V10 Beyond-the-Box** | 69 | 10 | 8.605 ns | 1.00 mW | 7.8184% | 247.38 µm² |

---

## 2. Active Version: `v0.0.0` (Contest Exact Baseline Multiplier)

- **Architecture:** Standard Signed 8-bit Carry-Save Array Multiplier (`exact_mul_s8`, `TheMultiplier`).
- **Mathematical Accuracy:** **100.00% exact zero-error coverage** ($65,536 / 65,536$ vectors in $[-128, 127] \times [-128, 127]$). $\text{MRED} = 0.0000\%$, $\text{MED} = 0.00$, $\text{WCE} = 0$.
- **FPGA Physical Implementation:** 150 Slice LUTs, 10 Logic Levels, 9.814 ns critical path ($F_{\max} = 101.90\text{ MHz}$), 4.00 mW dynamic power @ 100 MHz.
- **ASIC 45-nm Implementation:** 296 standard cells, 350.32 µm² area, 1.150 ns delay, 178.00 µW total power.

---

## 3. Directory Layout

```
mul_8bit_logarit/
├── Makefile                          # Unified build and automation interface
├── rtl/                              # Flat RTL source files for active version
│   ├── exact_mul_s8_registered.v     # Registered benchmark wrapper
│   ├── exact_mul_s8.v                # Top combinational exact multiplier
│   ├── TheMultiplier.v               # BTC core array multiplier
│   └── ...                           # Array adder rows and full/half adders
├── sim/                              # Exhaustive verification testbench
│   └── tb_mul_8bit.v                 # Exhaustive 65,536-vector testbench
├── reports/                          # Complete un-truncated EDA sign-off suite
│   ├── Bang_tra_cuu_65536_vectors.xlsx# Full 65,536-vector lookup workbook (Vietnamese)
│   ├── Vector_Lookup_Table_65536.xlsx # Full 65,536-vector lookup workbook (IEEE English)
│   ├── simulation_vectors.csv        # Hardware simulation trace directly from xsim
│   ├── pnr_util.rpt                  # Post-route utilization report
│   ├── critical_path.rpt             # Post-route critical path timing report
│   ├── deep_fpga_signoff_summary.rpt # Multi-corner & thermal sign-off summary
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
