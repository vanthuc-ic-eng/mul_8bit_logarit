# ==============================================================================
# Script tao Vivado Project .xpr cho mult_8bit (Version v3 - LUT-ALM V8)
# Part: xc7z010clg400-1 (Zybo Z7-10)
# ==============================================================================

set proj_dir "vivado"
set proj_name "mult8bit_v3"

# Tao thu muc neu chua co
file mkdir $proj_dir

# Tao project
create_project -force $proj_name $proj_dir -part xc7z010clg400-1

# Add toan bo RTL Verilog
set rtl_files [glob -nocomplain rtl/*.v]
add_files -norecurse $rtl_files

# Add constraints (neu co)
set xdc_files [glob -nocomplain constrs/*.xdc]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 -norecurse $xdc_files
}

# Dat Top-level module:
# Co 2 lua chon top:
# 1. lutalm_mul_s8 (DUT thuan toan hoc de xem so do khoi phep nhan)
# 2. lutalm_mul_s8_registered (Co thanh ghi DFF dau vao/ra)
# 3. top_board_test (Mach test tren board Zybo)
set_property top lutalm_mul_s8 [current_fileset]

# Set generic mac dinh cho v3: TRUNC_BITS=4, QUAD_CURV=0, USE_CARRY=1
set_property generic {TRUNC_BITS=4 QUAD_CURV=0 USE_CARRY=1} [current_fileset]

update_compile_order -fileset sources_1
puts "\n>>> DA TAO XONG VIVADO PROJECT: $proj_dir/$proj_name.xpr"
puts ">>> Top module duoc chon: lutalm_mul_s8"
