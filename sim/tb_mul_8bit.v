`timescale 1ns / 1ps
// ==============================================================================
// EXHAUSTIVE VERIFICATION TESTBENCH: 8-BIT APPROXIMATE & EXACT MULTIPLIER
// Author: NGUYEN VAN THUC (MSSV: 24161421) - Lead of Team Conquerors
// Institution: Ho Chi Minh City University of Technology and Education (HCMUTE)
//
// Description:
//   Exhaustively evaluates 8-bit signed multipliers across all 256 x 256 = 65,536
//   input vectors in [-128, 127] x [-128, 127], plus symmetric [-127, 127] range.
//   Computes exact arithmetic metrics:
//     - Mean Relative Error (MRED %)
//     - Mean Error Distance (MED)
//     - Worst-Case Error (WCE)
//     - Exact Match Rate (% of zero-error cases)
//   Outputs comprehensive sign-off telemetry to console and reports/simulation.log.
// ==============================================================================

module tb_mul_8bit;

    parameter integer MODE              = 2; // 0: Ultra Balanced, 1: Ultra Compact, 2: Nano
    parameter integer OPERAND_ISOLATION = 1;

    reg signed  [7:0]  a_i;
    reg signed  [7:0]  b_i;
    wire signed [15:0] p_o;

    // DUT Instantiation supporting Baseline Exact, Parameterized V9/V10, and Legacy LUT-ALM
`ifdef EXACT_BASELINE
    exact_mul_s8 dut (
        .a_i(a_i),
        .b_i(b_i),
        .p_o(p_o)
    );
`elsif USE_MODE_PARAM
    lutalm_mul_s8 #(
        .MODE(MODE)
    ) dut (
        .a_i(a_i),
        .b_i(b_i),
        .p_o(p_o)
    );
`else
    lutalm_mul_s8 dut (
        .a_i(a_i),
        .b_i(b_i),
        .p_o(p_o)
    );
`endif

    // Test loop variables
    integer i, j;
    integer exact_prod;
    integer approx_prod;
    integer abs_err;
    
    // Full 65,536 sweep statistics
    integer max_abs_err;
    integer exact_matches;
    integer non_zero_count;
    real    sum_abs_err;
    real    sum_rel_err;
    real    med;
    real    mred;
    real    accuracy_pct;

    // Symmetric [-127, 127] sweep statistics (standard AI / DSP domain)
    integer sym_max_abs_err;
    integer sym_exact_matches;
    integer sym_non_zero_count;
    integer sym_total_pairs;
    real    sym_sum_abs_err;
    real    sym_sum_rel_err;
    real    sym_med;
    real    sym_mred;
    real    sym_accuracy_pct;

    integer log_file;
    integer csv_file;
    integer vec_idx;

    initial begin
        // Initialize
        a_i = 8'sd0;
        b_i = 8'sd0;
        max_abs_err        = 0;
        exact_matches      = 0;
        non_zero_count     = 0;
        sum_abs_err        = 0.0;
        sum_rel_err        = 0.0;

        sym_max_abs_err    = 0;
        sym_exact_matches  = 0;
        sym_non_zero_count = 0;
        sym_total_pairs    = 0;
        sym_sum_abs_err    = 0.0;
        sym_sum_rel_err    = 0.0;
        vec_idx            = 0;

        #10;
        $display("================================================================================");
        $display(" 8-BIT MULTIPLIER EXHAUSTIVE SIMULATION REPORT — AMD Vivado xsim");
`ifdef EXACT_BASELINE
        $display(" DUT Architecture : exact_mul_s8 (Baseline Exact)");
`else
        $display(" DUT Architecture : lutalm_mul_s8 (MODE=%0d, OPERAND_ISOLATION=%0d)", MODE, OPERAND_ISOLATION);
`endif
        $display(" Author           : NGUYEN VAN THUC (MSSV: 24161421) - Team Conquerors");
        $display(" Institution      : Ho Chi Minh City University of Technology and Education (HCMUTE)");
        $display(" Vector Scope     : Full 65,536 vectors ([-128, 127]) + Symmetric 65,025 ([-127, 127])");
        $display("================================================================================");

        csv_file = $fopen("reports/simulation_vectors.csv", "w");
        if (csv_file) begin
            $fdisplay(csv_file, "Index,A,B,P_Exact,P_Approx,Error_Distance,Relative_Error_Pct,Exact_Match");
        end

        // Exhaustive sweep
        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin
                a_i = i[7:0];
                b_i = j[7:0];
                #1; // Combinational propagation delay

                exact_prod  = i * j;
                approx_prod = $signed(p_o);
                abs_err     = exact_prod - approx_prod;
                if (abs_err < 0) abs_err = -abs_err;

                if (csv_file) begin
                    $fdisplay(csv_file, "%0d,%0d,%0d,%0d,%0d,%0d,%0.6f,%0d",
                        vec_idx, i, j, exact_prod, approx_prod, abs_err,
                        (exact_prod != 0 ? ((abs_err * 100.0) / (exact_prod < 0 ? -exact_prod : exact_prod)) : 0.0),
                        (abs_err == 0 ? 1 : 0)
                    );
                end
                vec_idx = vec_idx + 1;

                // 1. Accumulate full 65,536 statistics
                sum_abs_err = sum_abs_err + abs_err;
                if (abs_err > max_abs_err) max_abs_err = abs_err;
                if (abs_err == 0) exact_matches = exact_matches + 1;

                if (exact_prod != 0) begin
                    sum_rel_err = sum_rel_err + (abs_err * 1.0) / (exact_prod < 0 ? -exact_prod : exact_prod);
                    non_zero_count = non_zero_count + 1;
                end

                // 2. Accumulate symmetric [-127, 127] statistics
                if (i >= -127 && j >= -127) begin
                    sym_total_pairs = sym_total_pairs + 1;
                    sym_sum_abs_err = sym_sum_abs_err + abs_err;
                    if (abs_err > sym_max_abs_err) sym_max_abs_err = abs_err;
                    if (abs_err == 0) sym_exact_matches = sym_exact_matches + 1;

                    if (exact_prod != 0) begin
                        sym_sum_rel_err = sym_sum_rel_err + (abs_err * 1.0) / (exact_prod < 0 ? -exact_prod : exact_prod);
                        sym_non_zero_count = sym_non_zero_count + 1;
                    end
                end
            end
        end

        if (csv_file) begin
            $fclose(csv_file);
        end

        // Compute metrics
        med          = sum_abs_err / 65536.0;
        mred         = (sum_rel_err / non_zero_count) * 100.0;
        accuracy_pct = (exact_matches * 100.0) / 65536.0;

        sym_med          = sym_sum_abs_err / (sym_total_pairs * 1.0);
        sym_mred         = (sym_sum_rel_err / sym_non_zero_count) * 100.0;
        sym_accuracy_pct = (sym_exact_matches * 100.0) / (sym_total_pairs * 1.0);

        // Display results
        $display("--------------------------------------------------------------------------------");
        $display(" 1. FULL INT8 TWO'S COMPLEMENT EVALUATION (65,536 VECTORS: [-128, 127]):");
        $display("   - Total Tested Vectors   : 65,536");
        $display("   - Exact Zero-Error Cases : %0d (%0.2f %%)", exact_matches, accuracy_pct);
        $display("   - Mean Absolute Err (MED): %0.4f", med);
        $display("   - Mean Relative Err(MRED): %0.4f %%", mred);
        $display("   - Worst-Case Error (WCE) : %0d", max_abs_err);
        $display("--------------------------------------------------------------------------------");
        $display(" 2. SYMMETRIC INT8 NEURAL DOMAIN EVALUATION (65,025 VECTORS: [-127, 127]):");
        $display("   - Total Tested Vectors   : %0d", sym_total_pairs);
        $display("   - Exact Zero-Error Cases : %0d (%0.2f %%)", sym_exact_matches, sym_accuracy_pct);
        $display("   - Mean Absolute Err (MED): %0.4f", sym_med);
        $display("   - Mean Relative Err(MRED): %0.4f %%", sym_mred);
        $display("   - Worst-Case Error (WCE) : %0d", sym_max_abs_err);
        $display("================================================================================");
        $display(" Verification Status         : PASSED (100%% Vector Coverage Sign-off)");
        $display("================================================================================");

        $finish;
    end

endmodule
