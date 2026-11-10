create_project -in_memory -part xc7z010clg400-1
read_verilog [glob rtl/*.v]
synth_design -top lutalm_mul_s8 -part xc7z010clg400-1 -mode out_of_context -max_dsp 0
report_utilization
close_project
exit
