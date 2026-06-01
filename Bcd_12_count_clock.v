module bcd_counter (
    input            clk,
    input            reset,
    input            ena,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss,
    output reg       pm
);

    // 复位值：12:00:00 AM
    parameter HOUR_RST = 8'h12;
    parameter MIN_RST = 8'h00;
    parameter SEC_RST = 8'h00;
    parameter PM_RST = 1'b0;

    always @(posedge clk) begin
        if (reset) begin
            hh <= HOUR_RST;
            mm <= MIN_RST;
            ss <= SEC_RST;
            pm <= PM_RST;
        end else if (ena) begin
            // 秒逻辑
            if (ss == 8'h59) begin
                ss <= 8'h00;
                // 分逻辑
                if (mm == 8'h59) begin
                    mm <= 8'h00;
                    // 小时逻辑
                    if (hh == 8'h11) begin
                        // 11 -> 12，并且切换 AM/PM
                        hh <= 8'h12;
                        pm <= ~pm;
                    end else if (hh == 8'h12) begin
                        hh <= 8'h01;
                    end else begin
                        // hh 01~10 加 1
                        if (hh[3:0] == 4'h9) begin
                            hh[7:4] <= hh[7:4] + 1;
                            hh[3:0] <= 4'h0;
                        end else begin
                            hh[3:0] <= hh[3:0] + 1;
                        end
                    end
                end else begin
                    // 分钟加 1
                    if (mm[3:0] == 4'h9) begin
                        mm[7:4] <= mm[7:4] + 1;
                        mm[3:0] <= 4'h0;
                    end else begin
                        mm[3:0] <= mm[3:0] + 1;
                    end
                end
            end else begin
                // 秒加 1
                if (ss[3:0] == 4'h9) begin
                    ss[7:4] <= ss[7:4] + 1;
                    ss[3:0] <= 4'h0;
                end else begin
                    ss[3:0] <= ss[3:0] + 1;
                end
            end
        end
    end

endmodule










module top_module (
    input            clk,
    input            reset,
    input            ena,
    output reg       pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);

    // 内部信号定义
    wire ss_ena, mm_ena, hh_ena;

    // 秒计数器逻辑 (00-59)
    always @(posedge clk) begin
        if (reset) begin
            ss <= 8'h00;
        end else if (ena) begin
            if (ss[3:0] == 4'h9) begin
                ss[3:0] <= 4'h0;
                if (ss[7:4] == 4'h5) begin
                    ss[7:4] <= 4'h0;
                end else begin
                    ss[7:4] <= ss[7:4] + 1;
                end
            end else begin
                ss[3:0] <= ss[3:0] + 1;
            end
        end
    end

    // 分钟计数器逻辑 (00-59)
    assign mm_ena = ena && (ss == 8'h59);

    always @(posedge clk) begin
        if (reset) begin
            mm <= 8'h00;
        end else if (mm_ena) begin
            if (mm[3:0] == 4'h9) begin
                mm[3:0] <= 4'h0;
                if (mm[7:4] == 4'h5) begin
                    mm[7:4] <= 4'h0;
                end else begin
                    mm[7:4] <= mm[7:4] + 1;
                end
            end else begin
                mm[3:0] <= mm[3:0] + 1;
            end
        end
    end

    // 小时计数器逻辑 (01-12)
    assign hh_ena = mm_ena && (mm == 8'h59);

    always @(posedge clk) begin
        if (reset) begin
            hh <= 8'h12;  // 重置为12:00
            pm <= 1'b0;  // AM
        end else if (hh_ena) begin
            // 处理小时翻转
            if (hh == 8'h11) begin
                // 11:59 → 12:00，切换AM/PM
                hh <= 8'h12;
                pm <= ~pm;
            end else if (hh == 8'h12) begin
                // 12:59 → 01:00
                hh <= 8'h01;
            end else begin
                // 正常递增
                if (hh[3:0] == 4'h9) begin
                    hh[3:0] <= 4'h0;
                    hh[7:4] <= hh[7:4] + 1;
                end else begin
                    hh[3:0] <= hh[3:0] + 1;
                end
            end
        end
    end

endmodule
