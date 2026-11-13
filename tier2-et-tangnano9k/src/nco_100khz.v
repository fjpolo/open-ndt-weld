// =============================================================================
// Module: nco_100khz
// Description: Generates 100 kHz LC Tank excitation clock and synchronous
//              8-bit signed Sine / Cosine quadrature references from 27 MHz clk.
//              27 MHz / 270 cycles = 100.000 kHz exact carrier frequency.
// =============================================================================
module nco_100khz (
    input  wire        clk_27m,
    input  wire        rst_n,
    output reg         coil_drive,
    output reg  signed [7:0] sin_ref,
    output reg  signed [7:0] cos_ref
);

    // 270 ticks per 100 kHz period (0..269)
    reg [8:0] period_cnt;

    always @(posedge clk_27m or negedge rst_n) begin
        if (!rst_n) begin
            period_cnt <= 9'd0;
            coil_drive <= 1'b0;
        end else begin
            if (period_cnt == 9'd269)
                period_cnt <= 9'd0;
            else
                period_cnt <= period_cnt + 9'd1;

            // 50% duty cycle 100 kHz square wave excitation
            coil_drive <= (period_cnt < 9'd135) ? 1'b1 : 1'b0;
        end
    end

    // Map 0..269 into 16 discrete phase quadrants (approx 17 ticks per bin)
    wire [3:0] phase_idx = period_cnt[8:4];

    always @(*) begin
        case (phase_idx)
            4'd0:  begin sin_ref =   8'sd0;    cos_ref =   8'sd127;  end
            4'd1:  begin sin_ref =   8'sd49;   cos_ref =   8'sd117;  end
            4'd2:  begin sin_ref =   8'sd90;   cos_ref =   8'sd90;   end
            4'd3:  begin sin_ref =   8'sd117;  cos_ref =   8'sd49;   end
            4'd4:  begin sin_ref =   8'sd127;  cos_ref =   8'sd0;    end
            4'd5:  begin sin_ref =   8'sd117;  cos_ref =  -8'sd49;   end
            4'd6:  begin sin_ref =   8'sd90;   cos_ref =  -8'sd90;   end
            4'd7:  begin sin_ref =   8'sd49;   cos_ref =  -8'sd117;  end
            4'd8:  begin sin_ref =   8'sd0;    cos_ref =  -8'sd127;  end
            4'd9:  begin sin_ref =  -8'sd49;   cos_ref =  -8'sd117;  end
            4'd10: begin sin_ref =  -8'sd90;   cos_ref =  -8'sd90;   end
            4'd11: begin sin_ref =  -8'sd117;  cos_ref =  -8'sd49;   end
            4'd12: begin sin_ref =  -8'sd127;  cos_ref =   8'sd0;    end
            4'd13: begin sin_ref =  -8'sd117;  cos_ref =   8'sd49;   end
            4'd14: begin sin_ref =  -8'sd90;   cos_ref =   8'sd90;   end
            default: begin sin_ref = -8'sd49;  cos_ref =   8'sd117;  end
        endcase
    end

endmodule

