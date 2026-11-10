# ==============================================================================
# PHYSICAL PIN CONSTRAINTS FOR DIGILENT ZYBO Z-7010 (xc7z010clg400-1)
# Project: 8-Bit Multiplier On-Board Hardware Test
# Author: NGUYEN VAN THUC - 24161421
# ==============================================================================

# Clock 125 MHz Oscillator
# Note: Zybo Classic uses L16; Zybo Z7-10 uses K17.
# Default configured for Zybo (L16). Uncomment K17 if using Zybo Z7.
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports { clk }];
# set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];

# Switches (4 slide switches: sw[3:0])
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

# Buttons (4 push buttons: btn[3:0])
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];

# LEDs (4 user LEDs: led[3:0])
# led[0]: Heartbeat 1 Hz (Blinks continuously -> Hardware is ALIVE)
# led[1]: Calculation Active / Non-zero Result
# led[2]: On-Board Self-Test PASSED (Solid ON = All tests pass!)
# led[3]: Sign of result (ON if negative)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

# Bitstream Generation Settings
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
