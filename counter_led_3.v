module counter_led_3(
    input clk,
    input reset_n,
    input  [7:0] ctrl,
    output reg led
);

    //让 LED 灯按照指定的亮灭模式亮灭，亮灭模式未知，
    //由用户随机指定。以 0.25 秒为一个变化周期，
    //8个变化状态为一个循环。

    parameter MAX = 50_000_000;
    parameter TIME = MAX/4;
    reg [31:0] counter;
    reg [2:0] counter_ctrl;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
            counter_ctrl <= 0;
        end else if(counter == TIME - 1)begin
            counter <= 0; 
            if(counter_ctrl == 3'd7)begin
                counter_ctrl <= 0;
            end else begin
                counter_ctrl <= counter_ctrl +1'b1;
            end
        end else begin
            counter <= counter + 1'b1;
        end
    end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n)begin
        led <= 0;
    end else begin
    case(counter_ctrl) 
        3'd0 : led <= ctrl[0];
        3'd1 : led <= ctrl[1];
        3'd2 : led <= ctrl[2];
        3'd3 : led <= ctrl[3];
        3'd4 : led <= ctrl[4];
        3'd5 : led <= ctrl[5];
        3'd6 : led <= ctrl[6];
        3'd7 : led <= ctrl[7];
        default: led <= 0;
    endcase
end
end
endmodule

//计数器分离方法
module counter_led_3_dob(
    input clk,
    input reset_n,
    input [7:0] ctrl,
    output reg led
);

    //让 LED 灯按照指定的亮灭模式亮灭，亮灭模式未知，
    //由用户随机指定。以 0.25 秒为一个变化周期，
    //8个变化状态为一个循环。

    parameter MAX = 50_000_000;
    parameter TIME = MAX/4;
    reg [31:0] counter;
    reg [2:0] counter_1;
    wire counter_overflow;  // 添加溢出信号

    // 0.25秒计数器 
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
        end else if(counter == TIME - 1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    // 生成溢出信号
    assign counter_overflow = (counter == TIME - 1);

    // 状态计数器 
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter_1 <= 0;
        end else if(counter_overflow) begin
            if(counter_1 == 3'd7 && counter_overflow) begin
                counter_1 <= 0;
            end else begin
                counter_1 <= counter_1 + 1'b1;
            end
        end
    end

   
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            led <= 0;
        end else begin
            case(counter_1) 
                3'd0 : led <= ctrl[0];
                3'd1 : led <= ctrl[1];
                3'd2 : led <= ctrl[2];
                3'd3 : led <= ctrl[3];
                3'd4 : led <= ctrl[4];
                3'd5 : led <= ctrl[5];
                3'd6 : led <= ctrl[6];
                3'd7 : led <= ctrl[7];
                default: led <= 0;
            endcase
        end
    end

endmodule