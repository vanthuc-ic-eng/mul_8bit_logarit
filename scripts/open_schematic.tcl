# Open project
open_project vivado/mult8bit_v3.xpr

# Mo Elaborated Design va hien thi Schematic
synth_design -rtl -top lutalm_mul_s8 -generic TRUNC_BITS=4 -generic QUAD_CURV=0 -generic USE_CARRY=1
show_schematic [get_cells]
