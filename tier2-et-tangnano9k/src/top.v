// =============================================================================
// Module: top
// Description: Top-level Eddy Current Testing (ET) FPGA pipeline for
//              Sipeed Tang Nano 9K (Gowin GW1NR-LV9QN88PC6/I5).
// =============================================================================
module top (
    input  wire       clk_27m,       // Pin 52: 27 MHz on-board crystal
    input  wire       rst_n,         // Pin 4:  Button S1 (Active LOW reset)
    input  wire       tare_btn_n,    // Pin 3:  Button S2 (Active LOW tare/calibrate)
    output wire       coil_drive,    // Pin 25: 100 kHz excitation to LC tank
    output wire       adc_cs_n,      // Pin 26: SPI ADC CS#
    output wire       adc_sclk,      // Pin 27: SPI ADC SCLK
    input  wire       adc_miso,      // Pin 28: SPI ADC DOUT/MISO
    output wire       buzzer_out,    // Pin 29: Active Buzzer alert output
    output wire [5:0] led_n          // Pins 10..16: On-board 6 LEDs (Active LOW)
);

    wire signed [7:0] sin_ref;
    wire signed [7:0] cos_ref;
    wire [11:0]       adc_sample;
    wire              sample_valid;
    wire [15:0]       magnitude;
    wire [15:0]       deviation;
    wire              defect_alarm;

    // 1. 100 kHz NCO & Quadrature Reference Generator
    nco_100khz u_nco (
        .clk_27m    (clk_27m),
        .rst_n      (rst_n),
        .coil_drive (coil_drive),
        .sin_ref    (sin_ref),
        .cos_ref    (cos_ref)
    );

    // 2. 12-bit 1 MSPS SPI ADC Interface
    spi_adc_reader u_adc (
        .clk_27m      (clk_27m),
        .rst_n        (rst_n),
        .adc_cs_n     (adc_cs_n),
        .adc_sclk     (adc_sclk),
        .adc_miso     (adc_miso),
        .sample_data  (adc_sample),
        .sample_valid (sample_valid)
    );

    // 3. Digital Lock-In I/Q Demodulator & LPF
    iq_demodulator #(
        .DEFECT_THRESHOLD(16'd450)
    ) u_demod (
        .clk_27m      (clk_27m),
        .rst_n        (rst_n),
        .tare_btn_n   (tare_btn_n),
        .adc_sample   (adc_sample),
        .sample_valid (sample_valid),
        .sin_ref      (sin_ref),
        .cos_ref      (cos_ref),
        .magnitude    (magnitude),
        .deviation    (deviation),
        .defect_alarm (defect_alarm)
    );

    assign buzzer_out = defect_alarm;

    // Bar-graph visualization on the 6 active-LOW on-board LEDs
    assign led_n[0] = ~(deviation > 16'd75);
    assign led_n[1] = ~(deviation > 16'd150);
    assign led_n[2] = ~(deviation > 16'd225);
    assign led_n[3] = ~(deviation > 16'd300);
    assign led_n[4] = ~(deviation > 16'd375);
    assign led_n[5] = ~defect_alarm;

endmodule

