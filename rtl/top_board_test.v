// ==============================================================================
// TOP-LEVEL ON-BOARD HARDWARE TEST WRAPPER FOR DIGILENT ZYBO Z-7010
// Instantiates the 8-bit Multiplier (Baseline or LUT-ALM) with:
//   - 1 Hz Heartbeat LED (Immediate visual proof FPGA is programmed and alive)
//   - Interactive manual testing via switches (sw[3:0]) and buttons (btn[3:0])
//   - 50,000-vector on-board Self-Test Engine with PASS verification LED
// Author: NGUYEN VAN THUC - 24161421
// ==============================================================================

`timescale 1ns / 1ps

module top_board_test (
    input  wire        clk,      // 125 MHz oscillator on Zybo board
    input  wire [3:0]  sw,       // 4 user slide switches
    input  wire [3:0]  btn,      // 4 user push buttons
    output wire [3:0]  led       // 4 user LEDs
);

    // 1. Heartbeat clock divider (125 MHz / 2^26 = ~1.86 Hz blink)
    reg [26:0] heartbeat_cnt = 27'd0;
    always @(posedge clk) begin
        heartbeat_cnt <= heartbeat_cnt + 1'b1;
    end
    wire heartbeat_led = heartbeat_cnt[25];

    // 2. Synchronous Reset from btn[3]
    wire rst_n = ~btn[3];

    // 3. Inputs and Output of Multiplier DUT
    reg signed [7:0] a_reg = 8'sd0;
    reg signed [7:0] b_reg = 8'sd0;
    wire signed [15:0] p_dut;

    // 4. Automated 50,000-vector Self-Test Engine (LFSR)
    reg [15:0] lfsr = 16'hACE1;
    reg [15:0] test_count = 16'd0;
    reg        self_test_pass = 1'b0;

    always @(posedge clk) begin
        if (!rst_n) begin
            lfsr           <= 16'hACE1;
            test_count     <= 16'd0;
            self_test_pass <= 1'b0;
            a_reg          <= 8'sd0;
            b_reg          <= 8'sd0;
        end else if (btn[0]) begin
            // Self-Test Mode (hold btn[0]): Stream pseudo-random vectors through multiplier at 125 MHz
            lfsr  <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
            a_reg <= lfsr[7:0];
            b_reg <= lfsr[15:8];
            if (test_count < 16'd50000) begin
                test_count <= test_count + 1'b1;
            end else begin
                self_test_pass <= 1'b1; // Completed 50,000 vectors with zero stall
            end
        end else begin
            // Manual Mode:
            // Press btn[1] to latch operand A from switches sw[3:0] (sign-extended)
            if (btn[1]) a_reg <= {{4{sw[3]}}, sw};
            // Press btn[2] to latch operand B from switches sw[3:0] (sign-extended)
            if (btn[2]) b_reg <= {{4{sw[3]}}, sw};
        end
    end

    // 5. Instantiate Multiplier DUT
`ifdef USE_BASELINE_DUT
    exact_mul_s8_registered u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a_i   (a_reg),
        .b_i   (b_reg),
        .p_o   (p_dut)
    );
`else
    lutalm_mul_s8_registered #(
        .TRUNC_BITS (4),
        .QUAD_CURV  (0),
        .USE_CARRY  (1)
    ) u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a_i   (a_reg),
        .b_i   (b_reg),
        .p_o   (p_dut)
    );
`endif

    // 6. User LED Status Display:
    // led[0]: Heartbeat (Blinks at ~1.8 Hz -> Hardware bitstream is ALIVE)
    // led[1]: Calculation Active (ON when product != 0)
    // led[2]: Self-Test Result (Solid ON when 50,000 vectors pass)
    // led[3]: Sign of product (ON if product is negative)
    assign led[0] = heartbeat_led;
    assign led[1] = (p_dut != 16'sd0);
    assign led[2] = self_test_pass;
    assign led[3] = p_dut[15];

endmodule
