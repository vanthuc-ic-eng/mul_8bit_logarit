#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Universal Benchmark Summary Parser & Aggregator
Parses FPGA (Vivado), ASIC (Yosys Nangate 45nm), and Mathematical Accuracy reports.
Displays metrics specifically for the current branch/tag without cluttering.
Author: NGUYEN VAN THUC - 24161421
"""

import sys
import os
import re
import json
import csv
import subprocess
import argparse
from pathlib import Path

def get_git_info():
    tag = ""
    branch = ""
    try:
        tag = subprocess.check_output(["git", "describe", "--tags", "--exact-match"], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        pass
    try:
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        branch = "unknown"
    return tag if tag else branch

def parse_report_dir(rep_dir: Path, name=""):
    if not name:
        name = get_git_info()
        
    d = {"name": name, "dir": str(rep_dir)}
    
    # 1. Accuracy
    acc_file = rep_dir / "accuracy.json"
    if acc_file.exists():
        try:
            data = json.loads(acc_file.read_text())
            d["mred"] = f"{data.get('MRED_pct', 0.0):.4f}%"
            d["med"] = f"{data.get('MED', 0.0):.2f}"
            d["wce"] = str(data.get("WCE", 0))
            d["error_rate"] = f"{data.get('error_rate_pct', 0.0):.2f}%"
        except Exception:
            d["mred"], d["med"], d["wce"], d["error_rate"] = "N/A", "N/A", "N/A", "N/A"
    else:
        d["mred"], d["med"], d["wce"], d["error_rate"] = "N/A", "N/A", "N/A", "N/A"

    # 2. ASIC (Nangate 45nm)
    asic_file = rep_dir / "asic_stat.rpt"
    if asic_file.exists():
        txt = asic_file.read_text()
        m_c = re.search(r"Number of cells:\s+(\d+)", txt)
        d["asic_cells"] = int(m_c.group(1)) if m_c else "N/A"
        m_a = re.search(r"Chip area for module.*:\s*([\d\.]+)", txt)
        d["asic_area"] = f"{float(m_a.group(1)):.2f}" if m_a else "N/A"
    else:
        d["asic_cells"], d["asic_area"] = "N/A", "N/A"

    asic_timing_file = rep_dir / "asic_timing.rpt"
    if asic_timing_file.exists():
        txt = asic_timing_file.read_text()
        m_delay = re.search(r"([\d\.]+)\s+data arrival time", txt)
        if m_delay:
            delay = float(m_delay.group(1))
            d["asic_delay_ns"] = f"{delay:.3f}"
            d["asic_fmax_mhz"] = f"{(1000.0 / delay):.2f}"
        else:
            d["asic_delay_ns"], d["asic_fmax_mhz"] = "N/A", "N/A"
    else:
        d["asic_delay_ns"], d["asic_fmax_mhz"] = "N/A", "N/A"

    asic_power_file = rep_dir / "asic_power.rpt"
    if asic_power_file.exists():
        txt = asic_power_file.read_text()
        m_pwr = re.search(r"Total\s+([\d\.e+-]+)\s+([\d\.e+-]+)\s+([\d\.e+-]+)\s+([\d\.e+-]+)", txt)
        if m_pwr:
            p_int = float(m_pwr.group(1)) * 1e6
            p_sw  = float(m_pwr.group(2)) * 1e6
            p_leak= float(m_pwr.group(3)) * 1e6
            p_tot = float(m_pwr.group(4)) * 1e6
            p_dyn = p_int + p_sw
            d["asic_power_tot"] = f"{p_tot:.2f} µW"
            d["asic_power_dyn"] = f"{p_dyn:.2f} µW"
            d["asic_power_leak"] = f"{p_leak:.2f} µW"
        else:
            d["asic_power_tot"], d["asic_power_dyn"], d["asic_power_leak"] = "N/A", "N/A", "N/A"
    else:
        d["asic_power_tot"], d["asic_power_dyn"], d["asic_power_leak"] = "N/A", "N/A", "N/A"

    # 3. FPGA Utilization
    util_file = rep_dir / "pnr_util.rpt"
    if util_file.exists():
        txt = util_file.read_text()
        m_lut = re.search(r"Slice LUTs\*\s+\|\s+(\d+)", txt)
        if not m_lut:
            m_lut = re.search(r"LUT as Logic\s+\|\s+(\d+)", txt)
        d["slice_lut"] = int(m_lut.group(1)) if m_lut else "N/A"
        
        m_c = re.search(r"CARRY4\s+\|\s+(\d+)", txt)
        d["carry4"] = int(m_c.group(1)) if m_c else 0
        
        m_ff = re.search(r"Register as Flip Flop\s+\|\s+(\d+)", txt)
        if not m_ff:
            m_ff = re.search(r"FDCE\s+\|\s+(\d+)", txt)
        d["ff"] = int(m_ff.group(1)) if m_ff else "N/A"
        
        m_dsp = re.search(r"DSPs\s+\|\s+(\d+)", txt)
        d["dsp"] = int(m_dsp.group(1)) if m_dsp else 0
    else:
        d["slice_lut"], d["carry4"], d["ff"], d["dsp"] = "N/A", "N/A", "N/A", "N/A"

    # 4. FPGA Timing
    timing_file = rep_dir / "pnr_timing_100mhz.rpt"
    if not timing_file.exists():
        timing_files = list(rep_dir.glob("timing_*mhz.rpt"))
        if timing_files:
            timing_file = sorted(timing_files)[-1]
            
    if timing_file.exists():
        txt = timing_file.read_text()
        m_d = re.search(r"Data Path Delay:\s*([\d\.]+)ns\s+\(logic\s+([\d\.]+)ns\s+\(([\d\.]+)%\)\s+route\s+([\d\.]+)ns\s+\(([\d\.]+)%\)\)", txt)
        if m_d:
            delay = float(m_d.group(1))
            d["delay_ns"] = f"{delay:.3f}"
            d["logic_delay_ns"] = f"{float(m_d.group(2)):.3f}"
            d["fmax_mhz"] = f"{(1000.0 / delay):.2f}"
        else:
            d["delay_ns"], d["logic_delay_ns"], d["fmax_mhz"] = "N/A", "N/A", "N/A"
            
        m_lev = re.search(r"Logic Levels:\s+(\d+)", txt)
        d["levels"] = int(m_lev.group(1)) if m_lev else "N/A"
    else:
        d["delay_ns"], d["logic_delay_ns"], d["fmax_mhz"], d["levels"] = "N/A", "N/A", "N/A", "N/A"

    # 5. Dynamic Power
    for freq in [50, 100]:
        p_file = rep_dir / f"power_{freq}mhz.rpt"
        if not p_file.exists() and freq == 100:
            p_file = rep_dir / "pnr_power_100mhz.rpt"
        if p_file.exists():
            txt = p_file.read_text()
            m_dyn = re.search(r"Dynamic \(W\)\s+\|\s*([\d\.]+)", txt)
            d[f"p_dyn_{freq}mhz"] = f"{(float(m_dyn.group(1)) * 1000.0):.2f} mW" if m_dyn else "N/A"
        else:
            d[f"p_dyn_{freq}mhz"] = "N/A"

    return d

def print_accuracy(data):
    print("\n=======================================================")
    print(f" MATHEMATICAL ACCURACY REPORT [{data['name']}]")
    print("=======================================================")
    print(f" MRED (%)           : {data['mred']}")
    print(f" Mean Error (MED)   : {data['med']}")
    print(f" Worst-Case Error   : {data['wce']}")
    print(f" Error Rate (%)     : {data['error_rate']}")
    print("=======================================================\n")

def print_asic(data):
    print("\n=======================================================")
    print(f" ASIC SYNTHESIS & STA/POWER REPORT (Nangate 45nm) [{data['name']}]")
    print("=======================================================")
    print(f" Standard Cells     : {data['asic_cells']}")
    print(f" Chip Area          : {data['asic_area']} µm²")
    print(f" STA Delay (100MHz) : {data.get('asic_delay_ns', 'N/A')} ns (Fmax = {data.get('asic_fmax_mhz', 'N/A')} MHz)")
    print(f" Total Power @100M  : {data.get('asic_power_tot', 'N/A')} (Dyn: {data.get('asic_power_dyn', 'N/A')}, Leak: {data.get('asic_power_leak', 'N/A')})")
    print("=======================================================\n")

def print_fpga(data):
    print("\n=======================================================")
    print(f" FPGA P&R & TIMING REPORT (AMD Zybo Z-7010) [{data['name']}]")
    print("=======================================================")
    print(f" Slice LUTs         : {data['slice_lut']}")
    print(f" CARRY4 Primitives  : {data['carry4']}")
    print(f" Flip-Flops         : {data['ff']}")
    print(f" Logic Levels       : {data['levels']}")
    print(f" Data Path Delay    : {data['delay_ns']} ns")
    print(f" Logic Delay        : {data['logic_delay_ns']} ns")
    print(f" Max Frequency Fmax : {data['fmax_mhz']} MHz")
    print(f" Dynamic Power @100M: {data['p_dyn_100mhz']}")
    print(f" Dynamic Power @ 50M: {data['p_dyn_50mhz']}")
    print(f" DSP Blocks         : {data['dsp']}")
    print("=======================================================")
    
    deep_rpt = Path(data['dir']) / "deep_fpga_signoff_summary.rpt"
    if deep_rpt.exists():
        print("\n" + deep_rpt.read_text().strip() + "\n")

def print_summary_card(data):
    print("\n==================================================================")
    print(f" BENCHMARK REPORT: {data['name']}")
    print("==================================================================")
    print(f" • Slice LUTs (P&R)   : {data['slice_lut']}")
    print(f" • Logic Levels       : {data['levels']}")
    print(f" • Data Path Delay    : {data['delay_ns']} ns (Fmax = {data['fmax_mhz']} MHz)")
    print(f" • Dynamic Power @100M: {data['p_dyn_100mhz']} (@50M: {data['p_dyn_50mhz']})")
    print(f" • MRED (%)           : {data['mred']} (MED = {data['med']}, WCE = {data['wce']})")
    print(f" • ASIC Area (45nm)   : {data['asic_area']} µm² ({data['asic_cells']} cells)")
    print(f" • ASIC STA & Power   : {data.get('asic_delay_ns', 'N/A')} ns delay | {data.get('asic_power_tot', 'N/A')} total power")
    print(f" • DSP Blocks         : {data['dsp']}")
    print("==================================================================\n")

def main():
    parser = argparse.ArgumentParser(description="Universal Benchmark Summary Parser")
    parser.add_argument("--dir", type=str, default="reports", help="Report directory path (default: reports)")
    parser.add_argument("--show", choices=["accuracy", "asic", "fpga", "summary", "all"], default="summary")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    rep_dir = root / args.dir if not Path(args.dir).is_absolute() else Path(args.dir)

    if not rep_dir.exists():
        print(f"ERROR: Report directory not found at {rep_dir}", file=sys.stderr)
        sys.exit(1)

    data = parse_report_dir(rep_dir)
    
    if args.show == "accuracy":
        print_accuracy(data)
    elif args.show == "asic":
        print_asic(data)
    elif args.show == "fpga":
        print_fpga(data)
    elif args.show in ["summary", "all"]:
        print_summary_card(data)

if __name__ == "__main__":
    main()
