# ==============================================================================
# UNIVERSAL FPGA PHYSICAL IMPLEMENTATION & TIMING BENCHMARK (AMD Vivado 2024.2)
# Target Part: Digilent Zybo Z-7010 (xc7z010clg400-1)
# Author: NGUYEN VAN THUC - 24161421
# Comprehensive Environmental, Thermal, Voltage Corner & Netlist Sign-off Suite
# ==============================================================================

set_param general.maxThreads 2

if {[info exists env(TOP_MODULE)]} {
    set top_module $env(TOP_MODULE)
} else {
    set top_module "exact_mul_s8_registered"
}

if {[info exists env(DESIGN_NAME)]} {
    set design_name $env(DESIGN_NAME)
} else {
    set design_name "baseline"
}

if {[info exists env(MODE_VAL)]} {
    set mode_val $env(MODE_VAL)
} else {
    set mode_val 2
}

if {[info exists env(TRUNC_BITS)]} {
    set trunc_bits $env(TRUNC_BITS)
} else {
    set trunc_bits 4
}

if {[info exists env(QUAD_CURV)]} {
    set quad_curv $env(QUAD_CURV)
} else {
    set quad_curv 0
}

if {[info exists env(USE_CARRY)]} {
    set use_carry $env(USE_CARRY)
} else {
    set use_carry 1
}

if {[info exists env(OPERAND_ISOLATION)]} {
    set op_isolation $env(OPERAND_ISOLATION)
} else {
    set op_isolation 1
}

if {[info exists env(REPORT_DIR)]} {
    set report_dir $env(REPORT_DIR)
} else {
    set report_dir "reports"
}

file mkdir $report_dir

puts "\n=================================================================="
puts ">>> PROFILING FPGA: $design_name ($top_module)"
puts ">>> Parameters: MODE=$mode_val | TRUNC=$trunc_bits | USE_CARRY=$use_carry | OP_ISOLATION=$op_isolation"
puts ">>> Output Dir: $report_dir"
puts "=================================================================="

create_project -in_memory -part xc7z010clg400-1

# Read all RTL files present directly in rtl/
set rtl_files [glob -nocomplain rtl/*.v]
read_verilog $rtl_files

# ------------------------------------------------------------------------------
# 1. Synthesis (Out-of-context, DSP strictly prohibited)
# ------------------------------------------------------------------------------
set has_op_iso 0
if {[file exists "rtl/${top_module}.v"]} {
    set fp [open "rtl/${top_module}.v" "r"]
    set content [read $fp]
    close $fp
    if {[string match "*OPERAND_ISOLATION*" $content]} {
        set has_op_iso 1
    }
}

if {$top_module eq "exact_mul_s8_registered"} {
    synth_design -top $top_module -part xc7z010clg400-1 -mode out_of_context -max_dsp 0
} elseif {$has_op_iso} {
    synth_design -top $top_module -part xc7z010clg400-1 -mode out_of_context -max_dsp 0 \
        -generic MODE=$mode_val -generic TRUNC_BITS=$trunc_bits -generic QUAD_CURV=$quad_curv \
        -generic USE_CARRY=$use_carry -generic OPERAND_ISOLATION=$op_isolation
} else {
    synth_design -top $top_module -part xc7z010clg400-1 -mode out_of_context -max_dsp 0 \
        -generic MODE=$mode_val -generic TRUNC_BITS=$trunc_bits -generic QUAD_CURV=$quad_curv \
        -generic USE_CARRY=$use_carry
}

# ------------------------------------------------------------------------------
# 2. Place & Route (Physical Implementation for exact sign-off parasitics)
# ------------------------------------------------------------------------------
create_clock -period 10.000 [get_ports clk]
opt_design
place_design
route_design

# ------------------------------------------------------------------------------
# 3. Post-Route Utilization & Baseline Timing (100 MHz, Nominal PVT)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 3\] Baseline Utilization & Physical Timing Sign-Off (100 MHz)..."
report_utilization -file "${report_dir}/pnr_util.rpt"
report_utilization -hierarchical -file "${report_dir}/utilization_hierarchical.rpt"
report_timing_summary -max_paths 10 -file "${report_dir}/pnr_timing_100mhz.rpt"
report_timing -nworst 1 -max_paths 1 -path_type full_clock_expanded -file "${report_dir}/critical_path.rpt"
report_timing -delay_type min_max -max_paths 5 -file "${report_dir}/timing_paths_detailed.rpt"
report_power -file "${report_dir}/pnr_power_100mhz.rpt"

# ------------------------------------------------------------------------------
# 4. Multi-Frequency Power & Timing Survey
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 4\] Multi-Frequency Sweep..."
if {$top_module eq "exact_mul_s8_registered"} {
    set freqs {50 70}
} else {
    set freqs {50 100 105 110}
}

foreach f $freqs {
    set period [expr {1000.0 / $f}]
    create_clock -period $period [get_ports clk]
    report_timing_summary -file "${report_dir}/timing_${f}mhz.rpt"
    report_power -file "${report_dir}/power_${f}mhz.rpt"
}

# ------------------------------------------------------------------------------
# 5. Environmental & Thermal Sign-Off (Ambient Temperature Sweep: -40C to 100C)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 5\] Environmental & Thermal Sweep (-40C to 100C, Still Air, No Heatsink)..."
create_clock -period 10.000 [get_ports clk]
set ambient_temps {-40 0 25 50 85 100}
set thermal_csv [open "${report_dir}/thermal_ambient_sweep.csv" "w"]
puts $thermal_csv "Ambient_Temp_C,Junction_Temp_C,Thermal_Margin_C,Device_Static_W,Dynamic_W,Total_Power_W"

foreach temp $ambient_temps {
    set_operating_conditions -ambient_temp $temp -airflow 0 -heatsink none
    report_power -file "${report_dir}/power_thermal_${temp}C.rpt"
    
    set fp [open "${report_dir}/power_thermal_${temp}C.rpt" "r"]
    set content [read $fp]
    close $fp
    
    set junc_temp "N/A"
    set therm_margin "N/A"
    set dev_static "N/A"
    set dyn_power "N/A"
    set tot_power "N/A"
    
    regexp {Junction Temperature \(C\)\s+\|\s*([-\d\.]+)} $content match junc_temp
    regexp {Device Static \(W\)\s+\|\s*([<\d\.]+)} $content match dev_static
    regexp {Dynamic \(W\)\s+\|\s*([<\d\.]+)} $content match dyn_power
    regexp {Total On-Chip Power \(W\)\s+\|\s*([<\d\.]+)} $content match tot_power
    if {$junc_temp ne "N/A"} {
        set therm_margin [format "%.1f C" [expr {85.0 - $junc_temp}]]
    }
    
    puts $thermal_csv "${temp},${junc_temp},${therm_margin},${dev_static},${dyn_power},${tot_power}"
}
close $thermal_csv

# Reset to standard operating condition (25C ambient)
set_operating_conditions -ambient_temp 25.0 -airflow 0 -heatsink none

# ------------------------------------------------------------------------------
# 6. Supply Voltage Corner Sensitivity Analysis (Vccint = 0.95V, 1.00V, 1.05V)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 6\] Supply Voltage Corner Sensitivity Analysis..."
set v_corners {0.95 1.00 1.05}
set volt_csv [open "${report_dir}/voltage_corner_power.csv" "w"]
puts $volt_csv "Vccint_V,Total_Power_W,Dynamic_W,Static_W"

foreach v $v_corners {
    set_operating_conditions -voltage [list Vccint $v Vccaux 1.80 Vcco33 3.30]
    report_power -file "${report_dir}/power_vccint_${v}V.rpt"
    
    set fp [open "${report_dir}/power_vccint_${v}V.rpt" "r"]
    set content [read $fp]
    close $fp
    
    set tot_p "N/A"
    set dyn_p "N/A"
    set stat_p "N/A"
    regexp {Total On-Chip Power \(W\)\s+\|\s*([\d\.]+)} $content match tot_p
    regexp {Dynamic \(W\)\s+\|\s*([\d\.]+)} $content match dyn_p
    regexp {Device Static \(W\)\s+\|\s*([\d\.]+)} $content match stat_p
    
    puts $volt_csv "${v},${tot_p},${dyn_p},${stat_p}"
}
close $volt_csv

# Reset voltage to nominal
set_operating_conditions -voltage {Vccint 1.00 Vccaux 1.80 Vcco33 3.30}

# ------------------------------------------------------------------------------
# 7. Switching Activity & Glitch Analysis Survey (Toggle Rate Sweep 5% to 50%)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 7\] Switching Activity Survey (Toggle Rates 5% to 50%)..."
set toggle_rates {5.0 12.5 25.0 50.0}
set switch_csv [open "${report_dir}/switching_activity_sweep.csv" "w"]
puts $switch_csv "Toggle_Rate_pct,Dynamic_Power_W,Logic_Power_W,Signal_Power_W"

foreach tr $toggle_rates {
    set_switching_activity -default_toggle_rate $tr -default_static_probability 0.5
    report_power -file "${report_dir}/power_toggle_${tr}pct.rpt"
    
    set fp [open "${report_dir}/power_toggle_${tr}pct.rpt" "r"]
    set content [read $fp]
    close $fp
    
    set dyn_w "N/A"
    set logic_w "N/A"
    set sig_w "N/A"
    regexp {Dynamic \(W\)\s+\|\s*([<\d\.]+)} $content match dyn_w
    regexp {Slice Logic\s+\|\s*([<\d\.]+)} $content match logic_w
    regexp {Signals\s+\|\s*([<\d\.]+)} $content match sig_w
    
    puts $switch_csv "${tr},${dyn_w},${logic_w},${sig_w}"
}
close $switch_csv

# Reset switching activity to default
set_switching_activity -default_toggle_rate 12.5 -default_static_probability 0.5

# ------------------------------------------------------------------------------
# 8. Deep Netlist, Physical Complexity & Routing Analysis
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 8\] Deep Netlist & Physical Complexity Analysis..."
catch { report_design_analysis -timing -setup -hold -max_paths 5 -file "${report_dir}/design_timing_paths.rpt" }
catch { report_design_analysis -logic_level_distribution -file "${report_dir}/logic_level_distribution.rpt" }
catch { report_design_analysis -congestion -file "${report_dir}/routing_congestion.rpt" }
catch { report_high_fanout_nets -fanout_greater_than 5 -max_nets 20 -file "${report_dir}/high_fanout_nets.rpt" }
catch { report_datasheet -file "${report_dir}/datasheet.rpt" }

# ------------------------------------------------------------------------------
# 9. Consolidated Deep Sign-Off Summary Report Generation
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 9\] Generating Consolidated Deep Sign-Off Report..."
set signoff_rpt [open "${report_dir}/deep_fpga_signoff_summary.rpt" "w"]
puts $signoff_rpt "================================================================================"
puts $signoff_rpt " AMD ZYNQ-7000 FPGA DEEP PHYSICAL SIGN-OFF & ENVIRONMENTAL REPORT"
puts $signoff_rpt " Target Device : AMD Zybo Z7-10 (xc7z010clg400-1)"
puts $signoff_rpt " Design Module : $top_module ($design_name)"
puts $signoff_rpt " Generated On  : [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
puts $signoff_rpt "================================================================================\n"

puts $signoff_rpt "1. ENVIRONMENTAL & THERMAL CHARACTERIZATION (STILL AIR, NO HEATSINK):"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s | %-12s" "Ambient (C)" "Junction Tj (C)" "Thermal Margin" "Static Pwr" "Total Pwr"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/thermal_ambient_sweep.csv"]} {
    set fp [open "${report_dir}/thermal_ambient_sweep.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s | %-12s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3] [lindex $cols 5]]
    }
    close $fp
}

puts $signoff_rpt "\n2. SUPPLY VOLTAGE CORNER SENSITIVITY (VCCINT VARIATION +/-5%):"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s" "Vccint (V)" "Total Power (W)" "Dynamic (W)" "Static (W)"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/voltage_corner_power.csv"]} {
    set fp [open "${report_dir}/voltage_corner_power.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3]]
    }
    close $fp
}

puts $signoff_rpt "\n3. SWITCHING ACTIVITY / TOGGLE RATE SENSITIVITY:"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-16s" "Toggle Rate (%)" "Dynamic Pwr (W)" "Logic Pwr (W)" "Signals Pwr (W)"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/switching_activity_sweep.csv"]} {
    set fp [open "${report_dir}/switching_activity_sweep.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-16s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3]]
    }
    close $fp
}
puts $signoff_rpt "================================================================================"
close $signoff_rpt

close_project
puts "\n>>> FPGA Physical Implementation & Deep Characterization Completed: ${design_name}"
exit
