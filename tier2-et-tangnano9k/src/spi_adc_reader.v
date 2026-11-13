// =============================================================================
// Module: spi_adc_reader
// Description: 1 MSPS 12-bit SPI ADC controller (ADS7883 / ADC121S101)
//              SCLK = 13.5 MHz (27 MHz / 2). 16 SCLK frame + 2 cycle CS high.
// =============================================================================
module spi_adc_reader (
    input  wire        clk_27m,
    input  wire        rst_n,
    output reg         adc_cs_n,
    output reg         adc_sclk,
    input  wire        adc_miso,
    output reg  [11:0] sample_data,
    output reg         sample_valid
);

    reg [5:0] state_cnt; // 0..35 (36 ticks @ 27 MHz = 750 kSPS - 1 MSPS)
    reg [15:0] shift_reg;

    always @(posedge clk_27m or negedge rst_n) begin
        if (!rst_n) begin
            state_cnt    <= 6'd0;
            adc_cs_n     <= 1'b1;
            adc_sclk     <= 1'b1;
            shift_reg    <= 16'd0;
            sample_data  <= 12'd2048;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0;

            if (state_cnt == 6'd35) begin
                state_cnt <= 6'd0;
            end else begin
                state_cnt <= state_cnt + 6'd1;
            end

            if (state_cnt < 6'd32) begin
                adc_cs_n <= 1'b0;
                adc_sclk <= ~state_cnt[0];
                if (state_cnt[0] == 1'b1) begin
                    shift_reg <= {shift_reg[14:0], adc_miso};
                end
            end else begin
                adc_cs_n <= 1'b1;
                adc_sclk <= 1'b1;
                if (state_cnt == 6'd32) begin
                    // ADS7883 / ADC121S101: 2 leading zeros, 12 data bits, 2 trailing zeros
                    sample_data  <= shift_reg[13:2];
                    sample_valid <= 1'b1;
                end
            end
        end
    end

endmodule

