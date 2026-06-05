module Uart_232 (

    input clk,
    input reset_n,

    input [7:0] data,
    input [2:0] bit_set,

    input bit_send,

    output reg uart,
    output reg done

);

    parameter clk_time = 1_000_000_000;
    reg [17:0] bit_cnt, bit_time;
    reg       uart_act;
    reg [3:0] data_cnt;

    always @(*) begin
        case (bit_set)
            0:       bit_time = clk_time / 9600 / 20;
            1:       bit_time = clk_time / 19200 / 20;
            2:       bit_time = clk_time / 38400 / 20;
            3:       bit_time = clk_time / 57600 / 20;
            4:       bit_time = clk_time / 115200 / 20;
            default: bit_time = clk_time / 9600 / 20;
        endcase
    end

    //单个数据传输时间
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bit_cnt <= 0;
        end else if (bit_send) begin
            if (bit_cnt == bit_time - 1) begin
                bit_cnt <= 0;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end
    end

    //发送数据位数
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_cnt <= 0;
            uart_act <= 0;
        end else begin
            if (bit_send && !uart_act) begin
                data_cnt <= 0;
                uart_act <= 1'b1;
            end else if (uart_act && bit_cnt == bit_time - 1) begin
                if (data_cnt == 10) begin
                    uart_act <= 0;
                    data_cnt <= 0;
                end else begin
                    data_cnt <= data_cnt + 1'b1;
                end
            end
        end
    end

    //数据位逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            uart <= 1;
        end else begin
            case (data_cnt)
                0:       uart <= 1'b1;  // 空闲
                1:       uart <= 1'b0;  //  起始
                2:       uart <= data[0];
                3:       uart <= data[1];
                4:       uart <= data[2];
                5:       uart <= data[3];
                6:       uart <= data[4];
                7:       uart <= data[5];
                8:       uart <= data[6];
                9:       uart <= data[7];
                10:      uart <= 1'b1;  //停止
                default: uart <= 1;
            endcase
        end
    end


    assign done = (data_cnt == 10) && (bit_cnt == bit_time - 1);


endmodule
