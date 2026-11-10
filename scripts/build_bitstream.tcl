# ==============================================================================
# VIVADO BITSTREAM GENERATION SCRIPT FOR DIGILENT ZYBO Z-7010
# Target Part: xc7z010clg400-1
# Generates physical .bit file for JTAG programming onto hardware board
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================

set_param general.maxThreads 2

set output_dir "bitstream"
file mkdir $output_dir

if {[info exists env(DUT_TYPE)]} {
    set dut_type $env(DUT_TYPE)
} else {
    # Check if core RTL exists; if not, use baseline
    if {[file exists "rtl/lutalm_mul_s8.v"]} {
        set dut_type "lutalm"
    } else {
        set dut_type "baseline"
    }
}

puts "\n=================================================================="
puts ">>> BUILDING BITSTREAM FOR ZYBO Z-7010 (xc7z010clg400-1)"
puts ">>> Multiplier Architecture: $dut_type"
puts ">>> Output Directory:        $output_dir"
puts "=================================================================="

create_project -in_memory -part xc7z010clg400-1

# Read all RTL files directly in rtl/
set rtl_files [glob -nocomplain rtl/*.v]
read_verilog $rtl_files

# Read physical constraints
read_xdc constrs/zybo_z7.xdc

# 1. Synthesis with board top wrapper
if {$dut_type eq "baseline"} {
    puts "\n--> [1/5] Synthesizing Top Board Wrapper with Baseline Multiplier..."
    synth_design -top top_board_test -part xc7z010clg400-1 -verilog_define USE_BASELINE_DUT=1 -max_dsp 0
} else {
    puts "\n--> [1/5] Synthesizing Top Board Wrapper with LUT-ALM Multiplier..."
    synth_design -top top_board_test -part xc7z010clg400-1 -max_dsp 0
}

# 2. Logic Optimization
puts "\n--> [2/5] Running Logic Optimization (opt_design)..."
opt_design

# 3. Placement
puts "\n--> [3/5] Running Physical Placement (place_design)..."
place_design

# 4. Routing
puts "\n--> [4/5] Running Physical Routing (route_design)..."
route_design

# 5. Reports & Bitstream Generation
puts "\n--> [5/5] Generating Physical Reports & Bitstream..."
report_utilization -file "${output_dir}/board_utilization.rpt"
report_timing_summary -file "${output_dir}/board_timing.rpt"

set bit_file "${output_dir}/mult_8bit.bit"
write_bitstream -force $bit_file

puts "\n=================================================================="
puts ">>> SUCCESS: BITSTREAM GENERATED SUCCESSFULLY!"
puts ">>> Output File: [file normalize $bit_file]"
puts ">>> Size:        [file size $bit_file] bytes"
puts ">>> Ready to program onto board using: ./scripts/program_fpga.sh"
puts "==================================================================\n"

close_project
exit 0
