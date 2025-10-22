//=====================================================
// Digital Clock (HH:MM:SS)
// Using counters and 7-segment multiplexing
//=====================================================
module digital_clock(
    input clk,          // 100 MHz FPGA clock
    input reset,        // Active-high reset
    output [6:0] seg,   // Seven segment display segments
    output [3:0] an     // Display select lines
);

    wire clk_1hz;
    wire [5:0] sec, min;
    wire [4:0] hr;

    // 1 Hz clock divider (100 MHz input → 1 Hz output)
    clock_divider #(100_000_000) DIV (
        .clk(clk),
        .reset(reset),
        .clk_out(clk_1hz)
    );

    // Seconds counter (00–59)
    counter_60 SEC (.clk(clk_1hz), .reset(reset), .count(sec));

    // Minutes counter (00–59), increments when sec == 59
    wire min_tick = (sec == 6'd59);
    counter_60 MIN (.clk(min_tick), .reset(reset), .count(min));

    // Hours counter (00–23), increments when min == 59 and sec == 59
    wire hr_tick = (min == 6'd59 && sec == 6'd59);
    counter_24 HR (.clk(hr_tick), .reset(reset), .count(hr));

    // Display on 7-segment
    display_mux DISP (
        .clk(clk),
        .hr(hr),
        .min(min),
        .sec(sec),
        .seg(seg),
        .an(an)
    );

endmodule


//=====================================================
// Clock Divider (Generates 1Hz from FPGA clock)
//=====================================================
module clock_divider #(parameter DIVISOR = 100_000_000)(
    input clk,
    input reset,
    output reg clk_out
);
    integer count = 0;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_out <= 0;
        end else begin
            if (count == DIVISOR/2 - 1) begin
                clk_out <= ~clk_out;
                count <= 0;
            end else
                count <= count + 1;
        end
    end
endmodule


//=====================================================
// 0–59 Counter
//=====================================================
module counter_60(
    input clk,
    input reset,
    output reg [5:0] count
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 0;
        else if (count == 59)
            count <= 0;
        else
            count <= count + 1;
    end
endmodule


//=====================================================
// 0–23 Counter
//=====================================================
module counter_24(
    input clk,
    input reset,
    output reg [4:0] count
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 0;
        else if (count == 23)
            count <= 0;
        else
            count <= count + 1;
    end
endmodule


//=====================================================
// 7-segment Display Multiplexer
//=====================================================
module display_mux(
    input clk,
    input [4:0] hr,
    input [5:0] min,
    input [5:0] sec,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [1:0] sel = 0;
    reg [3:0] digit;

    // Divide clock for multiplexing (~1kHz)
    reg [15:0] refresh = 0;
    always @(posedge clk)
        refresh <= refresh + 1;

    always @(*) sel = refresh[15:14];  // 4 digits

    always @(*) begin
        case (sel)
            2'b00: digit = sec % 10;
            2'b01: digit = sec / 10;
            2'b10: digit = min % 10;
            2'b11: digit = min / 10;
        endcase

        case (sel)
            2'b00: an = 4'b1110;
            2'b01: an = 4'b1101;
            2'b10: an = 4'b1011;
            2'b11: an = 4'b0111;
        endcase
    end

    // 7-seg decoder
    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
