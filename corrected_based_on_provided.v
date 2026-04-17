// 完整的串行接收器 FSM + 数据通路
// 功能：
//   - FSM 识别串行比特流中的有效字节接收（开始位 + 8数据位 + 停止位）
//   - 数据通路在接收完成时输出正确的字节（LSB first）
//   - 当 done=1 时，out_byte 包含接收到的数据

module top_module (
    input clk,                  // 同步时钟
    input in,                   // 串行输入（LSB first）
    input reset,                // 同步复位（高有效）
    output [7:0] out_byte,      // 接收完成时输出的字节数据
    output done                 // 接收完成指示信号（在 dn 状态时为1）
);

    // ============ 状态定义 ============
    // rd (0): 空闲状态，等待开始位
    // rc (1): 接收状态，正在接收8个数据位
    // dn (2): 完成状态，接收到有效字节（停止位正确）
    // err(3): 错误状态，停止位错误
    parameter [1:0] STATE_READY = 2'b00;
    parameter [1:0] STATE_RECV  = 2'b01;
    parameter [1:0] STATE_DONE  = 2'b10;
    parameter [1:0] STATE_ERROR = 2'b11;

    // ============ 寄存器声明 ============
    reg [1:0] state, next_state;    // 当前态和下一态
    reg [7:0] data_shift;           // 移位寄存器，存储接收到的8位数据
    reg [3:0] bit_count;            // 比特计数器（0-8）

    // ============ 组合逻辑：状态转移 ============
    always @(*) begin
        next_state = state;  // 默认保持当前状态
        
        case (state)
            STATE_READY: begin
                // 空闲状态：等待开始位（in=0）
                if (in == 1'b0) begin
                    next_state = STATE_RECV;  // 检测到开始位，进入接收状态
                end
            end

            STATE_RECV: begin
                // 接收状态：接收8个数据位
                if (bit_count == 4'd8) begin
                    // 8位已接收，检查停止位
                    if (in == 1'b1) begin
                        // 停止位正确（应为高电平）
                        next_state = STATE_DONE;    
                    end else begin
                        // 停止位错误（为低电平）
                        next_state = STATE_ERROR;
                    end
                end
                // 否则继续接收
            end

            STATE_DONE: begin
                // 完成状态：准备接收下一字节
                // 检查输入以决定下一动作
                if (in == 1'b0) begin
                    // 可能是新字节的开始位
                    next_state = STATE_RECV;
                end else begin
                    // 线路空闲，回到就绪状态
                    next_state = STATE_READY;
                end
            end

            STATE_ERROR: begin
                // 错误状态：等待线路回到空闲
                if (in == 1'b1) begin
                    next_state = STATE_READY;
                end
            end
        endcase
    end

    // ============ 时序逻辑：状态更新 + 数据采样 ============
    always @(posedge clk) begin
        if (reset) begin
            // 同步复位
            state <= STATE_READY;
            bit_count <= 4'd0;
            data_shift <= 8'h00;
        end else begin
            state <= next_state;
            
            // 数据采样：在接收状态下采集输入比特
            if (state == STATE_RECV && bit_count < 4'd8) begin
                // LSB first: 第i个比特存到 data_shift[i]
                data_shift[bit_count] <= in;
                bit_count <= bit_count + 4'd1;
            end
            
            // 状态转移时重置比特计数
            if (state != STATE_RECV && next_state == STATE_RECV) begin
                bit_count <= 4'd0;
            end
            
            if (state != STATE_RECV) begin
                bit_count <= 4'd0;
            end
        end
    end

    // ============ 输出逻辑 ============
    // done: 在 STATE_DONE 时拉高一个时钟周期
    assign done = (state == STATE_DONE);

    // out_byte: 当 done=1 时有效，否则为 don't-care
    // 使用组合逻辑直接连接 data_shift
    assign out_byte = data_shift;

endmodule
