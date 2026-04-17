module  counter_led_6(
    input clk,
    input [31:0]Time,
    input [7:0]ctrl,
    input reset_n,
    output reg led
);

    //每隔 10ms，
    //让 LED 灯的一个8状态循环执行一次
    //每个状态的变化时间值小一点，
    //方便测试，比如设置为10us

    parameter TIME_10ms = 500_000;
    reg [31:0] counter;
    reg [2:0]  counter_ctrl;
    reg [31:0] counter_10ms;
    wire next_counter;
    reg  enable_cycle;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            enable_cycle <= 0;
        end else if(counter_10ms == 0) begin
            enable_cycle <= 1;
        end else if(counter_ctrl == 7 && next_counter) begin
            enable_cycle <= 0;
        end
    end
    //10ms计数器
   always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter_10ms <= 0;
        end else if(counter_10ms == TIME_10ms - 1) begin
            counter_10ms <= 0;
        end else begin
            counter_10ms <= counter_10ms + 1'b1;
        end
   end
    
    //Time计数器
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
        end else if(enable_cycle) begin 
             if(counter == Time - 1) begin
            counter <= 0;
            end else begin
            counter <= counter +1'b1;
            end
        end
    end
    assign next_counter = counter == Time - 1;

    //ctrl计数器
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter_ctrl <= 0;
        end else if(counter_ctrl == 7 && next_counter) begin
            counter_ctrl <= 0;
        end else if(next_counter) begin
            counter_ctrl <= counter_ctrl + 1'b1;
        end
    end

    //led逻辑
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
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
                    default :led <= 0;
            endcase
        end
    end

endmodule