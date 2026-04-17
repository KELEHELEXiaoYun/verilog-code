`timescale 1ns / 1ps

module corrected_based_on_provided_tb;

    reg clk;
    reg in;
    reg reset;
    wire [7:0] out_byte;
    wire done;

    // 实例化被测试的模块
    top_module uut (
        .clk(clk),
        .in(in),
        .reset(reset),
        .out_byte(out_byte),
        .done(done)
    );

    // 时钟生成：25MHz (40ns周期)
    always #20 clk = ~clk;

    initial begin
        // 初始化
        clk = 0;
        in = 1;  // 空闲状态为高电平
        reset = 0;

        // 复位
        #100 reset = 1;
        #40 reset = 0;

        // 等待一段时间，确保进入空闲状态
        #100;

        // 测试1: 发送字节 0xA5 (10100101)
        // LSB first，所以比特顺序为: 1, 0, 1, 0, 0, 1, 0, 1
        $display("Test 1: Sending 0xA5 (LSB first: 1,0,1,0,0,1,0,1)");
        
        // 开始位（低电平）
        in = 0;
        #40;  // 1个时钟周期

        // 发送8个数据位 (LSB first)
        in = 1; #40;  // bit 0
        in = 0; #40;  // bit 1
        in = 1; #40;  // bit 2
        in = 0; #40;  // bit 3
        in = 0; #40;  // bit 4
        in = 1; #40;  // bit 5
        in = 0; #40;  // bit 6
        in = 1; #40;  // bit 7

        // 停止位（高电平）
        in = 1;
        #40;

        // 等待接收完成
        #100;
        if (done) begin
            $display("✓ 接收完成！ done=%b, out_byte=%h (预期: %h)", done, out_byte, 8'hA5);
            if (out_byte == 8'hA5) begin
                $display("✓ 数据正确！");
            end else begin
                $display("✗ 数据错误！期望 0xA5，但得到 0x%h", out_byte);
            end
        end else begin
            $display("✗ 接收失败！done=%b", done);
        end

        #200;

        // 测试2: 发送字节 0x42 (01000010, LSB: 0,1,0,0,0,0,1,0)
        $display("\nTest 2: Sending 0x42 (LSB first: 0,1,0,0,0,0,1,0)");
        
        // 开始位
        in = 0;
        #40;

        // 发送8个数据位 (LSB first)
        in = 0; #40;  // bit 0
        in = 1; #40;  // bit 1
        in = 0; #40;  // bit 2
        in = 0; #40;  // bit 3
        in = 0; #40;  // bit 4
        in = 0; #40;  // bit 5
        in = 1; #40;  // bit 6
        in = 0; #40;  // bit 7

        // 停止位
        in = 1;
        #40;

        // 等待接收完成
        #100;
        if (done) begin
            $display("✓ 接收完成！ done=%b, out_byte=%h (预期: %h)", done, out_byte, 8'h42);
            if (out_byte == 8'h42) begin
                $display("✓ 数据正确！");
            end else begin
                $display("✗ 数据错误！期望 0x42，但得到 0x%h", out_byte);
            end
        end else begin
            $display("✗ 接收失败！done=%b", done);
        end

        #200;

        // 测试3: 错误的停止位（低电平）
        $display("\nTest 3: Sending with incorrect stop bit (should error)");
        
        // 开始位
        in = 0;
        #40;

        // 发送8个数据位
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;
        in = 1; #40;

        // 错误的停止位（低电平）
        in = 0;
        #40;

        // 等待
        #200;
        $display("✗ 停止位错误，应进入错误状态");

        #200;
        $finish;
    end

endmodule
