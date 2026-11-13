// =============================================================================
// Module: iq_demodulator
// Description: Digital Lock-In I/Q Multiplier, 1024-Sample Moving Average LPF,
//              Baseline Tare Calibration, and Defect Alarm Detector.
// =============================================================================
module iq_demodulator #(
    parameter [15:0] DEFECT_THRESHOLD = 16'd450
) (
    input  wire               clk_27m,
    input  wire               rst_n,
    input  wire               tare_btn_n,   // Active-LOW tare button
    input  wire        [11:0] adc_sample,
    input  wire               sample_valid,
    input  wire signed [7:0]  sin_ref,
    input  wire signed [7:0]  cos_ref,
    output reg         [15:0] magnitude,
    output reg         [15:0] deviation,
    output reg                defect_alarm
);

    // Convert 12-bit offset binary (0..4095, midpoint 2048) to signed 13-bit
    wire signed [12:0] ac_signal = $signed({1'b0, adc_sample}) - 13'sd2048;

    // Multiply AC signal by quadrature references
    wire signed [20:0] prod_i = ac_signal * sin_ref;
    wire signed [20:0] prod_q = ac_signal * cos_ref;

    // Accumulate over 1024 samples (~1 ms integration window at 1 MSPS)
    reg [9:0]          acc_cnt;
    reg signed [30:0]  acc_i;
    reg signed [30:0]  acc_q;

    reg [15:0] baseline_mag;

    wire [30:0] abs_i = acc_i[30] ? (~acc_i + 31'd1) : acc_i;
    wire [30:0] abs_q = acc_q[30] ? (~acc_q + 31'd1) : acc_q;
    wire [15:0] inst_mag = abs_i[27:12] + abs_q[27:12];

    always @(posedge clk_27m or negedge rst_n) begin
        if (!rst_n) begin
            acc_cnt      <= 10'd0;
            acc_i        <= 31'sd0;
            acc_q        <= 31'sd0;
            magnitude    <= 16'd0;
            baseline_mag <= 16'd0;
            deviation    <= 16'd0;
            defect_alarm <= 1'b0;
        end else if (sample_valid) begin
            if (acc_cnt == 10'd1023) begin
                acc_cnt   <= 10'd0;
                acc_i     <= prod_i;
                acc_q     <= prod_q;
                magnitude <= inst_mag;

                if (!tare_btn_n) begin
                    baseline_mag <= inst_mag;
                end

                if (inst_mag >= baseline_mag)
                    deviation <= inst_mag - baseline_mag;
                else
                    deviation <= baseline_mag - inst_mag;

                defect_alarm <= (deviation > DEFECT_THRESHOLD);
            end else begin
                acc_cnt <= acc_cnt + 10'd1;
                acc_i   <= acc_i + prod_i;
                acc_q   <= acc_q + prod_q;
            end
        end
    end

endmodule

