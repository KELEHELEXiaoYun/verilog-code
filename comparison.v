// 以下是原代码与修正代码的比较
// 原代码的问题已在 top_module_with_comments.v 中注释
// 修正代码在 corrected_top_module.v 中
// 这里标记主要修改部分

// 原代码模块定义（无变化）
module top_module (
    input clk,
    input in,
    input reset,
    output reg [7:0] out_byte,
    output reg done
);

// 原代码内部信号（修改：添加FSM状态，移除act）
    // 原代码：
    // reg [7:0] imm_byte;
    // reg [3:0] counter;
    // reg act;

    // 修正代码：
    // 定义FSM状态
    localparam IDLE = 2'b00;
    localparam RECEIVE = 2'b01;
    localparam STOP = 2'b10;

    reg [1:0] state, next_state;
    reg [7:0] imm_byte;
    reg [3:0] counter;

// 原代码第一个always块（修改：替换为FSM状态转换）
    // 原代码：
    // always @(posedge clk) begin
    //     if (reset) begin
    //         counter <= 0;
    //         act <= 0;
    //     end else if (in == 0) begin
    //         act <= 1;
    //         counter <= 0;
    //         if (counter >= 8 && in == 1) begin
    //             counter <= 0;
    //             act <= 0;
    //         end else begin
    //             counter <= counter + 1;
    //         end
    //     end
    // end

    // 修正代码：
    // FSM状态转换
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

// 添加：FSM下一状态逻辑
    // 修正代码新增：
    always @(*) begin
        case (state)
            IDLE: begin
                if (in == 0) begin  // 检测起始位
                    next_state = RECEIVE;
                end else begin
                    next_state = IDLE;
                end
            end
            RECEIVE: begin
                if (counter == 7) begin  // 接收完8位数据
                    next_state = STOP;
                end else begin
                    next_state = RECEIVE;
                end
            end
            STOP: begin
                if (in == 1) begin  // 停止位正确
                    next_state = IDLE;  // 返回空闲
                end else begin
                    next_state = IDLE;  // 错误，回到空闲
                end
            end
            default: next_state = IDLE;
        endcase
    end

// 原代码第二个always块（修改：数据采样逻辑）
    // 原代码：
    // always @(posedge clk) begin
    //     if (reset) begin
    //         imm_byte <= 0;
    //     end
    //     case (counter)
    //         0 : imm_byte <= 0;
    //         1 : imm_byte [0] <= in;
    //         2 : imm_byte [1] <= in;
    //         3 : imm_byte [2] <= in;
    //         4 : imm_byte [3] <= in;
    //         5 : imm_byte [4] <= in;
    //         6 : imm_byte [5] <= in;
    //         7 : imm_byte [6] <= in;
    //         8 : imm_byte [7] <= in;
    //          default : imm_byte <= imm_byte;
    //     endcase
    // end

    // 修正代码：整合到数据路径always块中

// 原代码第三个always块（修改：out_byte逻辑）
    // 原代码：
    // always @(posedge clk) begin
    //     if (reset) begin
    //         out_byte <= 0;
    //     end else if (in == 1 && counter >= 8) begin
    //         out_byte <= imm_byte;
    //     end
    // end

    // 修正代码：整合到数据路径always块中

// 原代码第四个always块（修改：done逻辑）
    // 原代码：
    // always @(posedge clk) begin
    //     if (reset) begin
    //        done <= 0;
    //     end else if (in == 1 && counter >= 8) begin
    //         done <= 1;
    //     end else begin
    //         done <= 0;
    //     end
    // end

    // 修正代码：整合到数据路径always块中

// 修正代码：统一的数据路径和计数器always块
    // 修正代码新增：
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            imm_byte <= 0;
            out_byte <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    counter <= 0;
                    done <= 0;
                    if (next_state == RECEIVE) begin
                        // 起始位后，开始接收
                    end
                end
                RECEIVE: begin
                    imm_byte[counter] <= in;  // LSB first: counter=0 是LSB
                    counter <= counter + 1;
                end
                STOP: begin
                    if (in == 1) begin
                        out_byte <= imm_byte;  // 输出接收的数据
                        done <= 1;
                    end
                    // 回到IDLE时重置
                end
            endcase
        end
    end

endmodule
