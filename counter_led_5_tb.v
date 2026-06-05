module counter_led_5_tb ();

    reg        clk;
    reg        reset_n;
    reg  [7:0] Time                  [0:31];  // 32个8位时间值
    reg  [7:0] ctrl                  [ 0:7];  // 8个8位控制模式
    wire [7:0] led;  // 8位LED输出

    // 实例化被测试模块
    counter_led_5 u_counter_led_5 (
        .clk    (clk),
        .reset_n(reset_n),
        .Time   (Time),
        .ctrl   (ctrl),
        .led    (led)
    );

    // 时钟生成：50MHz (20ns周期)
    initial clk = 1;
    always #10 clk = ~clk;

    // 测试序列
    initial begin
        integer i;

        // 初始化所有信号
        reset_n = 0;
        for (i = 0; i < 32; i = i + 1) begin
            Time[i] = 8'd0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            ctrl[i] = 8'd0;
        end

        // 释放复位
        #201;
        reset_n = 1;

        // 测试场景1：所有LED使用相同的时间参数，不同的控制模式
        $display("=== 测试场景1开始 ===");
        for (i = 0; i < 32; i = i + 1) begin
            Time[i] = 8'd10;  // 较短的时间，便于观察
        end

        // 设置不同的控制模式
        ctrl[0] = 8'b10101010;  // 交替模式
        ctrl[1] = 8'b11001100;  // 两个一组交替
        ctrl[2] = 8'b11110000;  // 四个一组交替
        ctrl[3] = 8'b00001111;  // 与上一个相反
        ctrl[4] = 8'b11111111;  // 常亮
        ctrl[5] = 8'b00000000;  // 常灭
        ctrl[6] = 8'b10000001;  // 两端亮
        ctrl[7] = 8'b01011010;  // 自定义模式

        #2000;  // 运行一段时间

        // 测试场景2：不同的时间参数
        $display("=== 测试场景2开始 ===");
        for (i = 0; i < 8; i = i + 1) begin
            Time[i] = 8'd5 + i;  // 每个LED有不同的时间参数
        end
        for (i = 8; i < 32; i = i + 1) begin
            Time[i] = 8'd0;  // 未使用的设为0
        end

        // 改变一些控制模式
        ctrl[0] = 8'b01010101;  // 与场景1相反
        ctrl[3] = 8'b10100101;  // 新的自定义模式

        #2000;  // 运行一段时间

        // 测试场景3：更长的时间参数
        $display("=== 测试场景3开始 ===");
        for (i = 0; i < 8; i = i + 1) begin
            Time[i] = 8'd50 + i * 10;  // 更长且不同的时间
        end

        #5000;  // 运行更长时间

        $display("=== 测试完成 ===");
        $stop;
    end

    // 监控输出变化
    initial begin
        $monitor("时间: %t, LED状态: %b", $time, led);
    end

endmodule
