module Uart_rx #(
    parameter CLK_FREQ = 50_000_000,  // 系统时钟频率 (Hz)
    parameter BAUD_RATE = 9600        // 波特率
)(
    input  wire       Sys_clk,        // 系统时钟
    input  wire       Sys_rst_n,      // 系统复位 (低有效)
    input  wire       rx,             // UART 接收引脚
    output reg  [7:0] Po_data,        // 接收到的 8 位数据
    output reg        Po_flag         // 数据接收完成标志 (高脉冲)
);

// 计算波特率计数器最大值
localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;
localparam BAUD_CNT_HALF = BAUD_CNT_MAX / 2;

// 内部信号定义
reg [15:0] baud_cnt;    // 波特率计数器
reg [3:0]  bit_cnt;     // 位计数器 (0~9: 1起始位+8数据位+1停止位)
reg         rx_sync1;    // 同步寄存器1
reg         rx_sync2;    // 同步寄存器2 (消除亚稳态)
reg         rx_sync3;    // 同步寄存器3 (检测边沿)
reg         rx_sample;   // 采样值
reg         rx_flag;     // 接收进行中标志

// 1. 异步信号同步 (打两拍消除亚稳态)
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
        rx_sync3 <= 1'b1;
    end else begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
        rx_sync3 <= rx_sync2;
    end
end

// 2. 检测起始位 (下降沿)
wire start_flag = ~rx_sync2 & rx_sync3;

// 3. 接收状态控制
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        rx_flag <= 1'b0;
    end else if(start_flag) begin
        rx_flag <= 1'b1;
    end else if(bit_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX - 1) begin
        rx_flag <= 1'b0;
    end
end

// 4. 波特率计数器
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        baud_cnt <= 16'd0;
    end else if(rx_flag) begin
        if(baud_cnt < BAUD_CNT_MAX - 1) begin
            baud_cnt <= baud_cnt + 1'b1;
        end else begin
            baud_cnt <= 16'd0;
        end
    end else begin
        baud_cnt <= 16'd0;
    end
end

// 5. 位计数器
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        bit_cnt <= 4'd0;
    end else if(rx_flag && baud_cnt == BAUD_CNT_MAX - 1) begin
        if(bit_cnt < 4'd9) begin
            bit_cnt <= bit_cnt + 1'b1;
        end else begin
            bit_cnt <= 4'd0;
        end
    end
end

// 6. 数据采样 (在每一位的中间位置采样)
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        rx_sample <= 1'b1;
    end else if(rx_flag && baud_cnt == BAUD_CNT_HALF - 1) begin
        rx_sample <= rx_sync2;
    end
end

// 7. 数据移位与输出
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        Po_data <= 8'd0;
        Po_flag <= 1'b0;
    end else if(rx_flag && baud_cnt == BAUD_CNT_HALF - 1) begin
        case(bit_cnt)
            4'd0: ; // 起始位，不处理
            4'd1: Po_data[0] <= rx_sample;
            4'd2: Po_data[1] <= rx_sample;
            4'd3: Po_data[2] <= rx_sample;
            4'd4: Po_data[3] <= rx_sample;
            4'd5: Po_data[4] <= rx_sample;
            4'd6: Po_data[5] <= rx_sample;
            4'd7: Po_data[6] <= rx_sample;
            4'd8: Po_data[7] <= rx_sample;
            4'd9: Po_flag <= 1'b1; // 停止位，置位完成标志
            default: ;
        endcase
    end else begin
        Po_flag <= 1'b0; // 完成标志只保持一个时钟周期
    end
end

endmodule




module Uart_tx #(
    parameter CLK_FREQ = 50_000_000,  // 系统时钟频率 (Hz)
    parameter BAUD_RATE = 9600        // 波特率
)(
    input  wire       Sys_clk,        // 系统时钟
    input  wire       Sys_rst_n,      // 系统复位 (低有效)
    input  wire [7:0] Pi_data,        // 待发送的 8 位数据
    input  wire       Pi_flag,        // 发送请求标志 (高脉冲)
    output reg        tx              // UART 发送引脚
);

// 计算波特率计数器最大值
localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;

// 内部信号定义
reg [15:0] baud_cnt;    // 波特率计数器
reg [3:0]  bit_cnt;     // 位计数器 (0~10: 1起始位+8数据位+1停止位+空闲)
reg [7:0]  tx_data;     // 待发送数据缓存
reg         tx_flag;     // 发送进行中标志

// 1. 检测发送请求 (Pi_flag 上升沿)
reg Pi_flag_sync1;
reg Pi_flag_sync2;
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        Pi_flag_sync1 <= 1'b0;
        Pi_flag_sync2 <= 1'b0;
    end else begin
        Pi_flag_sync1 <= Pi_flag;
        Pi_flag_sync2 <= Pi_flag_sync1;
    end
end
wire pi_flag_pose = Pi_flag_sync1 & ~Pi_flag_sync2;

// 2. 发送状态控制
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end else if(pi_flag_pose) begin
        tx_flag <= 1'b1;
        tx_data <= Pi_data;
    end else if(bit_cnt == 4'd10 && baud_cnt == BAUD_CNT_MAX - 1) begin
        tx_flag <= 1'b0;
    end
end

// 3. 波特率计数器
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        baud_cnt <= 16'd0;
    end else if(tx_flag) begin
        if(baud_cnt < BAUD_CNT_MAX - 1) begin
            baud_cnt <= baud_cnt + 1'b1;
        end else begin
            baud_cnt <= 16'd0;
        end
    end else begin
        baud_cnt <= 16'd0;
    end
end

// 4. 位计数器
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        bit_cnt <= 4'd0;
    end else if(tx_flag && baud_cnt == BAUD_CNT_MAX - 1) begin
        if(bit_cnt < 4'd10) begin
            bit_cnt <= bit_cnt + 1'b1;
        end else begin
            bit_cnt <= 4'd0;
        end
    end
end

// 5. 发送数据输出
always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if(!Sys_rst_n) begin
        tx <= 1'b1; // 空闲状态为高电平
    end else if(tx_flag) begin
        case(bit_cnt)
            4'd0:  tx <= 1'b0; // 起始位
            4'd1:  tx <= tx_data[0];
            4'd2:  tx <= tx_data[1];
            4'd3:  tx <= tx_data[2];
            4'd4:  tx <= tx_data[3];
            4'd5:  tx <= tx_data[4];
            4'd6:  tx <= tx_data[5];
            4'd7:  tx <= tx_data[6];
            4'd8:  tx <= tx_data[7];
            4'd9:  tx <= 1'b1; // 停止位
            default: tx <= 1'b1;
        endcase
    end else begin
        tx <= 1'b1; // 空闲状态为高电平
    end
end

endmodule



module moduleName #(
    parameter CNT_COL_MAX = 8'd3,
    parameter CNT_ROW_MAX = 8'd4
) (

    input  wire         Sys_clk     ,
    input  wire         Sys_rst_n   ,

    input  wire         Pi_flag     ,
    input  wire [7:0]   Pi_data     ,

    output wire         Po_flag     ,
    output wire [7:0]   Po_data

);

wire    [7:0]   dout_1      ;
wire    [7:0]   dout_2      ;

reg     [7:0]   cnt_col     ;
reg     [7:0]   cnt_row     ;
reg             wr_en_1     ;
reg     [7:0]   wr_data_1   ;
reg             wr_en_2     ;
reg     [7:0]   wr_data_2   ;
reg             i_rd_en     ;
reg             dout_flag   ;
reg             sum_flag    ;

always @(posedge Sys_clk or negedge Sys_rst_n) begin
    if (Sys_rst_n == 1'b0) begin
        cnt_col <= 8'b0;
    end else if (cnt_col == CNT_COL_MAX && Po_flag == 1'b1) begin
        cnt_col <= 8'b0;
    end else if (Pi_flag == 1'b1) begin
        cnt_col <= cnt_col + 1'b1;
    end
end

always @(posedge Sys_clk or negedge Sys_rst_n ) begin
    if (Sys_rst_n == 1'b0) begin
        cnt_row <= 8'd0;
    end else if (cnt_col == CNT_COL_MAX && cnt_row == CNT_ROW_MAX && Pi_flag == 1'b1) begin
        cnt_row <= 8'b0;
    end else if (cnt_col == CNT_COL_MAX && Po_flag == 1'b1) begin
        cnt_row <= cnt_row + 1'b1;
    end
end

always @(posedge Sys_clk or negedge Sys_rst_n ) begin
    if (Sys_rst_n == 1'b0) begin
        wr_en_1 == 1'b0;
    end else if (cnt_row == 8'b0 && Pi_flag == 1'b1) begin
        wr_en_1 <= 1'b1;'
    end else 
end
endmodule