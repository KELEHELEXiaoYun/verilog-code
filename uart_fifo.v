module key #(
    parameter TIME_2ms = 10_0000 - 1
) (
    input wr_clk,
    input rst_n,

    input key_in,

    output reg key_flag,  // 检测到按键状态变化则置1一个周期
    output reg key_out    // 按键状态  1为释放 0为按下
);

    reg [16:0] cnt;
    wire key_in_d1, key_in_d2;
    wire key_change;

    assign key_change = key_in_d1 ^ key_in_d2;

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            key_in_d1 <= 1'b0;
            key_in_d2 <= 1'b0;
        end else begin
            key_in_d1 <= key_in;
            key_in_d2 <= key_in_d1;
        end
    end

    // 按键消抖逻辑 如果状态改变置零 
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 'd0;
        end else if (key_change) begin
            cnt <= 'd0;
        end else begin
            if (cnt == TIME_2ms) begin
                cnt <= cnt;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            key_flag <= 1'b0;
            key_out  <= 1'b0;
        end else if (cnt == TIME_2ms - 1) begin
            key_flag <= 1'b1;
            key_out  <= key_in_d2;
        end else begin
            key_flag <= 1'b0;
            key_out  <= key_out;
        end
    end

endmodule



module fifo_ctrl #(
    parameter WIDTH = 8
) (
    input wr_clk,
    input rd_clk,
    input rst_n,

    // 写端口 => 来自按键
    input             wr_en,  // key_flag 单周期脉冲
    input [WIDTH-1:0] din,    // 要写入的数据

    // 读端口 => 给UART
    input rd_en,  // UART发送使能

    // FIFO状态
    output             full,
    output             empty,
    output [WIDTH-1:0] dout    // 给UART的数据
);

    // 直接例化官方IP，不用自己写逻辑！
    fifo_generator_0 fifo_inst (
        .rst   (!rst_n),
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .din   (din),
        .wr_en (wr_en && !full),   // 满了就不能写
        .rd_en (rd_en && !empty),  // 空了就不能读
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );

endmodule
