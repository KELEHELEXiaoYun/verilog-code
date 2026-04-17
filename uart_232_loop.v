module top_uart (
    input clk,            // 系统时钟，比如50MHz
    input rst_n,          // 异步复位，低电平有效

    input uart_rxd,       // UART接收数据线
    output uart_txd       // UART发送数据线

);

    // <<< 内部连接信号定义，相当于模块间的“飞线”
    wire [7:0] uart_data; // 从接收模块传到环回模块的数据线
    wire uart_done;       // 从接收模块传到环回模块的“接收完成”脉冲信号
    wire send_en;         // 从环回模块传到发送模块的“启动发送”脉冲信号
    wire tx_busy;         // 从发送模块传到环回模块的“发送中忙”状态信号
    wire [7:0] send_data; // 从环回模块传到发送模块的数据线
    
    // <<< 实例化接收模块
    uart_recv u_uart_recv(
        .clk (clk),
        .rst_n (rst_n),
        .uart_rxd (uart_rxd),        // 连接外部输入引脚
        .uart_data (uart_data),      // 输出给内部信号 uart_data
        .uart_done (uart_done)       // 输出给内部信号 uart_done
    );

    // <<< 实例化环回控制模块
    uart_loop u_uart_loop (
        .clk (clk),
        .rst_n (rst_n),
        .recv_done (uart_done),      // 接收来自 u_uart_recv 的完成信号
        .recv_data (uart_data),      // 接收来自 u_uart_recv 的数据
        .tx_busy (tx_busy),          // 接收来自 u_uart_send 的忙状态
        .send_en (send_en),          // 输出启动信号给 u_uart_send
        .send_data (send_data)       // 输出数据给 u_uart_send
    );

    // <<< 实例化发送模块
    uart_send u_uart_send (
        .clk (clk),
        .rst_n (rst_n),
        .uart_en (send_en),          // 接收来自 u_uart_loop 的启动脉冲
        .uart_din (send_data),       // 接收来自 u_uart_loop 的数据
        .uart_txd (uart_txd),        // 连接到外部输出引脚
        .tx_busy (tx_busy)           // 输出忙状态给 u_uart_loop
    );
    
endmodule



module uart_recv(
    input clk,
    input rst_n,
    
    input uart_rxd,          // 外部串行数据输入

    output reg [7:0] uart_data, // 接收到的并行数据输出
    output reg uart_done         // 接收完成脉冲输出
    );
    
    // <<< 参数定义，用于计算波特率
    parameter CLK_FREQ = 50_000_000; // 系统时钟频率 50MHz
    parameter UART_BPS = 115200;      // 目标波特率
    parameter BPS_CNT  = CLK_FREQ / UART_BPS; // 每一位数据所需的时钟周期数

    // <<< 寄存器定义
    reg uart_rxd_d0;          // 对uart_rxd打一拍，用于消除亚稳态
    reg uart_rxd_d1;          // 对uart_rxd_d0再打一拍，用于边沿检测
    reg rx_flag;              // 接收过程标志位，1表示正在接收
    reg [3:0] rx_cnt;         // 接收位计数器，计0-9位（起始位+8数据位+停止位）
    reg [15:0] clk_cnt;       // 波特率时钟计数器
    reg [7:0] rx_data;        // 接收数据移位寄存器

    wire start_flag;          // 检测到起始位的标志信号

    // <<< 信号同步与边沿检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b1; // 空闲时为高电平
            uart_rxd_d1 <= 1'b1;
        end else begin
           uart_rxd_d0 <= uart_rxd; // 第一级寄存
           uart_rxd_d1 <= uart_rxd_d0; // 第二级寄存
        end
    end
    
    // <<< 检测到下降沿，即起始位的到来
    assign start_flag = uart_rxd_d1 && ~uart_rxd_d0;

    // <<< 接收状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 0; // 复位时，不在接收状态
        end else if (start_flag) begin
            rx_flag <= 1'b1; // 检测到起始位，开始接收
        end else if (rx_cnt == 4'd9 && clk_cnt == BPS_CNT - 1) begin
            rx_flag <= 0; // 接收完停止位后，结束接收状态
        end
    end

    // <<< 波特率时钟计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 16'b0;
        end else if (rx_flag) begin // 仅在接收状态下计数
           if (clk_cnt == BPS_CNT - 1) begin
                clk_cnt <= 0;      // 计满一个波特率周期，清零
           end else begin
                clk_cnt <= clk_cnt + 1'b1;
           end 
        end else begin
            clk_cnt <= 16'b0; // 非接收状态，计数器清零
        end
    end

    // <<< 接收位计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 4'b0;
        end else if (rx_flag) begin
           if (clk_cnt == BPS_CNT - 1) begin // 每个波特率周期结束时，位计数+1
                rx_cnt <= rx_cnt + 1'b1;
           end
        end else begin
            rx_cnt <= 4'b0; // 非接收状态，位计数器清零
        end
    end

    // <<< 数据采样逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           rx_data <= 8'b0;
        end else if (rx_flag && clk_cnt == BPS_CNT / 2 - 1) begin // 在每个位的中心点采样
           case (rx_cnt) 
                4'd1: rx_data[0] <= uart_rxd_d1; // 第1位是数据位D0
                4'd2: rx_data[1] <= uart_rxd_d1; // 第2位是数据位D1
                4'd3: rx_data[2] <= uart_rxd_d1;
                4'd4: rx_data[3] <= uart_rxd_d1;
                4'd5: rx_data[4] <= uart_rxd_d1;
                4'd6: rx_data[5] <= uart_rxd_d1;
                4'd7: rx_data[6] <= uart_rxd_d1;
                4'd8: rx_data[7] <= uart_rxd_d1; // 第8位是数据位D7
                default: ; // 其他情况（如起始位和停止位）不做处理
           endcase 
        end
    end

    // <<< 生成接收完成脉冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           uart_done <= 0;
        end else if (rx_cnt == 4'd9 && clk_cnt == BPS_CNT / 2 - 1) begin // 在停止位中心点后一个时钟周期产生脉冲
           uart_done <= 1'b1; // 产生一个时钟周期的高脉冲
        end else begin
            uart_done <= 0; // 其他时间保持低电平
        end
    end

    // <<< 锁存并保持接收到的数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_data <= 8'b0;
        end else if (uart_done) begin // 当uart_done脉冲为高时，锁存数据
            uart_data <= rx_data; // 将移位寄存器中的数据存入最终输出寄存器
        end
        // <<< 关键修改：删除了else分支，让uart_data保持值直到下一次接收完成
    end
    
endmodule



module uart_send (
    input clk,
    input rst_n,
    
    input uart_en,             // 启动发送的脉冲信号

    input [7:0] uart_din,     // 待发送的并行数据输入
    
    output reg uart_txd,       // 串行数据输出
    output reg tx_busy         // 发送忙状态输出
    );
    
    // <<< 参数定义，与接收模块保持一致
    parameter CLK_FREQ = 50_000_000;
    parameter UART_BPS = 115200;
    parameter BPS_CNT  = CLK_FREQ / UART_BPS;

    // <<< 寄存器定义
    reg uart_en_d0;            // 对uart_en打一拍，用于边沿检测
    reg uart_en_d1;            // 对uart_en_d0再打一拍
    reg tx_flag;               // 发送过程标志位，1表示正在发送
    reg [3:0] tx_cnt;          // 发送位计数器
    reg [15:0] clk_cnt;        // 波特率时钟计数器
    reg [7:0] tx_data;         // 待发送数据锁存寄存器

    wire en_flag;              // 检测到uart_en上升沿的标志

    // <<< 启动脉冲边沿检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_en_d0 <= 1'b0;
            uart_en_d1 <= 1'b0;
        end else begin
           uart_en_d0 <= uart_en;
           uart_en_d1 <= uart_en_d0;
        end
    end
    
    assign en_flag = ~uart_en_d1 && uart_en_d0; // 检测uart_en的上升沿

    // <<< 锁存待发送数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'b0;
        end else if (en_flag) begin // 检测到启动脉冲的上升沿时，锁存数据
            tx_data <= uart_din;
        end
    end

    // <<< 发送状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_flag <= 0;
        end else if (en_flag) begin // 检测到启动脉冲，开始发送
            tx_flag <= 1'b1;
        end else if (tx_cnt == 4'd9 && clk_cnt == BPS_CNT - 1) begin // 发送完停止位后，结束发送
            tx_flag <= 0;
        end
    end

    // <<< 波特率时钟计数器 (与接收模块逻辑相同)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 16'b0;
        end else if (tx_flag) begin
           if (clk_cnt == BPS_CNT - 1) begin
                clk_cnt <= 0;
           end else begin
                clk_cnt <= clk_cnt + 1'b1;
           end 
        end else begin
            clk_cnt <= 16'b0;
        end
    end

    // <<< 发送位计数器 (与接收模块逻辑相同)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt <= 4'b0;
        end else if (tx_flag) begin
           if (clk_cnt == BPS_CNT - 1) begin
                tx_cnt <= tx_cnt + 1'b1;
           end
        end else begin
            tx_cnt <= 4'b0;
        end
    end

    // <<< 串行数据输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_txd <= 1'b1; // 空闲时，总线为高电平
        end else if (tx_flag) begin
            case (tx_cnt) 
                4'd0: uart_txd <= 1'b0;          // 发送起始位
                4'd1: uart_txd <= tx_data[0];   // 发送数据位D0
                4'd2: uart_txd <= tx_data[1];
                4'd3: uart_txd <= tx_data[2];
                4'd4: uart_txd <= tx_data[3];
                4'd5: uart_txd <= tx_data[4];
                4'd6: uart_txd <= tx_data[5];
                4'd7: uart_txd <= tx_data[6];
                4'd8: uart_txd <= tx_data[7];   // 发送数据位D7
                4'd9: uart_txd <= 1'b1;          // 发送停止位
                default: uart_txd <= 1'b1;
            endcase 
        end else begin
            uart_txd <= 1'b1; // 非发送状态，保持高电平
        end
    end

    // <<< 生成发送忙状态信号 (关键修改)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy <= 1'b0;
        end else begin
            tx_busy <= tx_flag; // tx_flag是发送状态的核心，用它来表示忙状态最直接
        end
    end
    
endmodule



module uart_loop (
    input clk,
    input rst_n,

    input recv_done,             // 接收完成脉冲输入
    input [7:0] recv_data,       // 接收到的数据输入

    input tx_busy,               // 发送器忙状态输入
    output reg send_en,           // 启动发送脉冲输出
    output reg [7:0] send_data   // 待发送数据输出
);
    
    // <<< 寄存器定义
    reg recv_done_d0;            // 对recv_done打一拍，用于边沿检测
    reg recv_done_d1;            // 对recv_done_d0再打一拍
    reg send_req;                // 发送请求标志位，1表示有数据待发送

    wire recv_done_flag;         // 检测到recv_done上升沿的标志

    // <<< 接收完成脉冲边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_done_d0 <= 0;
            recv_done_d1 <= 0;
        end else begin
           recv_done_d0 <= recv_done;
           recv_done_d1 <= recv_done_d0;
        end
    end

    assign recv_done_flag = ~recv_done_d1 && recv_done_d0; // 检测recv_done的上升沿

    // <<< 核心协调状态机 (关键修改)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_req   <= 1'b0; // 复位所有状态
            send_en    <= 1'b0;
            send_data  <= 8'b0;
        end else begin
            // 步骤 1: 检测到接收完成，立即锁存数据并“举手”请求发送
            if (recv_done_flag) begin
                send_req  <= 1'b1; // 置位发送请求
                send_data <= recv_data; // 锁存接收到的数据
            end
            // 步骤 2: 如果“举着手”且发送器空闲，则在这一周期生成启动脉冲
            else if (send_req && !tx_busy) begin
                send_en  <= 1'b1; // 生成一个单周期的启动脉冲
                send_req <= 1'b0; // 立刻“放下手”，撤销请求，防止重复触发
            end
            // 步骤 3: 其他所有时间，确保启动脉冲为低
            else begin
                send_en <= 1'b0;
            end
        end
    end

endmodule