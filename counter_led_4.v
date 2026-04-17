module counter_led_4(
    input clk,
    input reset_n,
    input [7:0]ctrl,
    input [31:0]Time,
    output reg led
);

    //让 LED 灯按照指定的亮灭模式亮灭，
   // 亮灭模式未知，
    //由用户随机指定。
    //8个变化状态为4一个循环，
    //每个变化状态的时间值可以根据不同的应用场景选择

    reg [31:0] counter;
    reg [2:0] counter_ctrl;
    wire  next_counter;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
        end else if(counter == Time - 1) begin
            counter <= 0;
        end else begin
            counter <= counter +1'b1;
        end
    end

    assign next_counter = counter == Time - 1;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)begin
            counter_ctrl <= 0;
        end else if(counter_ctrl == 3'd7 && next_counter) begin
            counter_ctrl <= 0;
        end else if(next_counter) begin
            counter_ctrl <= counter_ctrl + 1'b1;
        end
    end

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