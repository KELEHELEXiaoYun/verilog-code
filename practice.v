module led_flash (
    Clk,
    Reset_n,
    Led
);

    input Clk;
    input Reset;
    output reg Led;

    reg [24:0] counter;

    parameter MCNT = 25'd24999999;

    always @(posedge Clk or negedge Reset_n)
        if (!Reset_n) counter <= 0;
        else if (counter == MCNT) counter <= 0;
        else counter <= counter + 1'b1;

    always @(posedge Clk or negedge Reset_n)
        if (!Reset) Led <= 8'b0000_0001;
        else if (counter == MCNT) begin
            if (Led == 8'b1000_0000) Led = 8'b0000_0001;
            else Led = Led << 1;
        end

endmodule

module led_flash (
    input  clk,
    input  reset_n,
    output led
);

    reg [24:0] counter;
    parameter MAX = 25'd24999999;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n == 1) begin
            counter <= 0;
        end else if (counter == MAX) begin
            counter <= 0;
        end
    end
endmodule

module led_a (
    input  clk,
    input  rst,
    output led
);

    always @(posedge clk or negedge rst) begin

    end
endmodule

module Countbed (
    input            clk,
    input            reset,
    input            ena,
    output reg       pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);

    // 定义BCD数字的拆分
    wire [3:0] ss_ones = ss[3:0];
    wire [3:0] ss_tens = ss[7:4];
    wire [3:0] mm_ones = mm[3:0];
    wire [3:0] mm_tens = mm[7:4];
    wire [3:0] hh_ones = hh[3:0];
    wire [3:0] hh_tens = hh[7:4];

    always @(posedge clk) begin
        if (reset) begin
            // 复位到12:00 AM
            hh <= 8'h12;
            mm <= 8'h00;
            ss <= 8'h00;
            pm <= 1'b0;
        end else if (ena) begin
            // 秒计数器逻辑
            if (ss_ones == 4'd9) begin
                ss[3:0] <= 4'd0;
                if (ss_tens == 4'd5) begin
                    ss[7:4] <= 4'd0;

                    // 分钟计数器逻辑
                    if (mm_ones == 4'd9) begin
                        mm[3:0] <= 4'd0;
                        if (mm_tens == 4'd5) begin
                            mm[7:4] <= 4'd0;

                            // 小时计数器逻辑 - 只有在分和秒都是59时才递增小时
                            // 检查分钟是否为59 (BCD: 0101 1001)
                            if (mm == 8'h59) begin
                                // 检查秒是否为59 (BCD: 0101 1001)
                                if (ss == 8'h59) begin
                                    if (hh == 8'h11 && pm == 1'b0) begin
                                        // 11:59:59 AM -> 12:00:00 PM
                                        hh <= 8'h12;
                                        pm <= 1'b1;
                                    end else if (hh == 8'h11 && pm == 1'b1) begin
                                        // 11:59:59 PM -> 12:00:00 AM
                                        hh <= 8'h12;
                                        pm <= 1'b0;
                                    end else if (hh == 8'h12) begin
                                        // 12:59:59 -> 01:00:00
                                        hh <= 8'h01;
                                    end else begin
                                        // 正常小时递增
                                        if (hh_ones == 4'd9) begin
                                            hh[3:0] <= 4'd0;
                                            hh[7:4] <= hh_tens + 1'b1;
                                        end else begin
                                            hh[3:0] <= hh_ones + 1'b1;
                                        end
                                    end
                                end
                            end
                        end else begin
                            mm[7:4] <= mm_tens + 1'b1;
                        end
                    end else begin
                        mm[3:0] <= mm_ones + 1'b1;
                    end
                end else begin
                    ss[7:4] <= ss_tens + 1'b1;
                end
            end else begin
                ss[3:0] <= ss_ones + 1'b1;
            end
        end
    end

endmodule


module top_module (
    input            clk,
    input            ena,
    input            reset,
    output reg       pm,
    output reg [7:0] ss,
    output reg [7:0] mm,
    output reg [7:0] hh
);

    always @(posedge clk) begin
        if (reset) begin
            ss <= 8'h0;
            mm <= 8'h0;
            hh <= 8'h12;
            pm <= 1'h0;
        end else if (ena) begin
            if (ss == 8'h59) begin
                ss <= 8'h00;
                if (mm == 8'h59) begin
                    mm <= 8'h00;
                    if (hh == 8'h11) begin
                        hh <= 8'h12;
                        pm <= ~pm;
                    end else if (hh == 8'h12) begin
                        hh <= 8'h01;
                    end else begin
                        if (hh[3:0] == 4'h9) begin
                            hh[3:0] <= 4'h0;
                            hh[7:4] <= hh[7:4] + 1;
                        end else begin
                            hh[3:0] <= hh[3:0] + 1;
                        end
                    end
                end else begin
                    if (mm[3:0] == 4'h9) begin
                        mm[3:0] <= 4'h0;
                        mm[7:4] <= mm[7:4] + 1;
                    end else begin
                        mm[3:0] <= mm[3:0] + 1;
                    end
                end
            end else begin
                if (ss[3:0] == 4'h9) begin
                    ss[3:0] <= 4'h0;
                    ss[7:4] <= ss[7:4] + 1;
                end else begin
                    ss[3:0] <= ss[3:0] + 1;
                end
            end
        end
    end

endmodule

module uart_232 (
    input        clk,
    input        reset_n,
    input        send_ena,
    input  [2:0] bits_set,
    input  [7:0] data,
    output       uart_tx,
    output       done
);

    reg [17:0] bits_sel;
    reg [17:0] bits_cnt;
    reg [ 3:0] uart_cnt;
    reg        tx_active;
    always @(*) begin
        case (bits_set)
            0:       bits_sel = 1_000_000_000 / 9600 / 20;  // 假设时钟频率为1GHz
            1:       bits_sel = 1_000_000_000 / 19200 / 20;
            2:       bits_sel = 1_000_000_000 / 38400 / 20;
            3:       bits_sel = 1_000_000_000 / 57600 / 20;
            4:       bits_sel = 1_000_000_000 / 115200 / 20;  // 修正：改为4
            default: bits_sel = 1_000_000_000 / 9600 / 20;
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bits_cnt <= 0;
        end else begin
            if (send_ena) begin
                if (cnt_ena == bits_sel - 1) begin
                    bits_cnt <= 0;
                end else begin
                    bits_cnt <= bits_cnt + 1'b1;
                end
            end
        end
    end


    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_active <= 0;
            uart_cnt  <= 0;
        end else if (send_ena && !tx_active) begin
            tx_active <= 1;
            bits_cnt  <= 0;
            if (bits_cnt == bits_sel - 1) begin
                if (uart_cnt == 10) begin
                    uart_cnt  <= 0;
                    tx_active <= 0;
                end else begin
                    uart_cnt <= uart_cnt + 1'b1;
                end
            end
        end else begin
            uart_cnt  <= 0;
            tx_active <= 0;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            uart_tx <= 1;
        end else if (tx_active) begin
            case (uart_cnt)
                0:       uart_tx <= 1'b1;  // 空闲位
                1:       uart_tx <= 1'b0;  // 起始位
                2:       uart_tx <= data[0];  // 数据位0 (LSB)
                3:       uart_tx <= data[1];  // 数据位1
                4:       uart_tx <= data[2];  // 数据位2
                5:       uart_tx <= data[3];  // 数据位3
                6:       uart_tx <= data[4];  // 数据位4
                7:       uart_tx <= data[5];  // 数据位5
                8:       uart_tx <= data[6];  // 数据位6
                9:       uart_tx <= data[7];  // 数据位7 (MSB)
                10:      uart_tx <= 1'b1;  // 停止位
                default: uart_tx = 1;
            endcase
        end
    end

    assign done = (uart_cnt == 10) && (bits_cnt == bits_sel - 1);

endmodule
