# ==============================================================================
# JTAG HARDWARE PROGRAMMING SCRIPT FOR DIGILENT ZYBO Z-7010
# Connects to Vivado hw_server via USB-JTAG and programs the .bit file directly
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================

if {[llength $argv] > 0} {
    set bit_file [lindex $argv 0]
} else {
    set bit_file "bitstream/mult_8bit.bit"
}

if {![file exists $bit_file]} {
    puts "\nERROR: Bitstream file not found at: $bit_file"
    puts "Please build the bitstream first using: make bitstream"
    exit 1
}

puts "\n=================================================================="
puts ">>> INITIALIZING JTAG PROGRAMMER (Vivado Hardware Manager)"
puts ">>> Target Bitstream: [file normalize $bit_file]"
puts "=================================================================="

open_hw_manager

# Connect to local hardware server
puts "--> Connecting to hardware server (localhost:3121)..."
if {[catch {connect_hw_server -allow_non_jtag} err]} {
    puts "ERROR: Failed to connect to hw_server: $err"
    close_hw_manager
    exit 1
}

# Scan for connected JTAG cables and boards
set hw_targets {}
if {[catch {set hw_targets [get_hw_targets]} err] || [llength $hw_targets] == 0} {
    puts "\n=================================================================="
    puts " ERROR: NO JTAG HARDWARE TARGET DETECTED!"
    puts " Please check the following:"
    puts "   1. USB-JTAG cable is plugged securely into the Zybo board (PROG/UART port)."
    puts "   2. Board POWER switch is turned ON (Red power LED is lit)."
    puts "   3. Jumper JP5 is set to JTAG mode (not QSPI/microSD)."
    puts "   4. USB cable drivers are installed on Linux (Digilent cable drivers)."
    puts "==================================================================\n"
    close_hw_manager
    exit 1
}

puts "--> Found JTAG Target: [lindex $hw_targets 0]"
open_hw_target [lindex $hw_targets 0]

# Detect FPGA Device
set hw_devices [get_hw_devices]
if {[llength $hw_devices] == 0} {
    puts "ERROR: No FPGA device found in JTAG chain!"
    close_hw_target
    close_hw_manager
    exit 1
}

# In Zynq-7000, JTAG chain has arm_dap (CPU) and xc7z010 (FPGA fabric)
set fpga_device ""
foreach dev $hw_devices {
    if {[string match -nocase "*xc7z010*" $dev] || [string match -nocase "*7z010*" $dev]} {
        set fpga_device $dev
        break
    }
}

if {$fpga_device eq ""} {
    # Default to first non-ARM device or first device
    set fpga_device [lindex $hw_devices end]
}

puts "--> Target FPGA Device: $fpga_device"
current_hw_device $fpga_device
refresh_hw_device -update_hw_probes false $fpga_device

# Assign bitstream and program device
puts "--> Programming bitstream to FPGA..."
set_property PROGRAM.FILE [file normalize $bit_file] $fpga_device

if {[catch {program_hw_devices $fpga_device} prog_err]} {
    puts "\nERROR: Programming failed: $prog_err"
    close_hw_target
    close_hw_manager
    exit 1
}

refresh_hw_device $fpga_device

puts "\n=================================================================="
puts ">>> SUCCESS: FPGA PROGRAMMED SUCCESSFULLY VIA JTAG!"
puts ">>> Multiplier circuit is now live on Zybo Z-7010 hardware."
puts ">>> Check Board Status:"
puts "    • LED 0 (Heartbeat) is blinking rhythmically at ~1.8 Hz."
puts "    • Hold Button 0 (btn[0]) to run 50,000-vector Self-Test."
puts "    • LED 2 turns solid ON when all test vectors pass!"
puts "==================================================================\n"

close_hw_target
close_hw_manager
exit 0
