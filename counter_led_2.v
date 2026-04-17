module counter_led_2(
    input clk,
    input reset_n,
    output reg led
);

    //亮0.25s 灭0.5s 亮0.75s 灭1s

    parameter MAX = 50_000_000;  // 50MHz时钟
    
    parameter TIME_ON1  = 0.25;
    parameter TIME_OFF1 = 0.5;
    parameter TIME_ON2  = 0.75;
    parameter TIME_OFF2 = 1.0;
    
    parameter T1 = MAX * TIME_ON1;
    parameter T2 = MAX* (TIME_ON1 + TIME_OFF1);
    parameter T3 =MAX * (TIME_ON1 + TIME_OFF1 + TIME_ON2);
    parameter PERIOD = MAX * (TIME_ON1 + TIME_OFF1 + TIME_ON2 + TIME_OFF2);
    
    reg [31:0] counter;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
            led <= 0;
        end else begin
            counter <= (counter == PERIOD - 1) ? 0 : counter + 1;
            led <= (counter < T1) || (counter >= T2 && counter < T3);
        end
    end

endmodule

module counter_led_2_state(
    input clk,
    input reset_n,
    output reg led
);

    parameter MAX = 50_000_000;
    reg [31:0]counter;
    reg [1:0] state,next_state;
    parameter light_1 = 0,off_1 = 1,light_2 = 2,off_2 = 3;
    parameter light_time_1 = MAX/4;
    parameter off_time_1 = MAX/2;
    parameter light_time_2 = MAX*3/4;
    parameter off_time_2 = MAX;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        counter <= 0;
        state <= light_1;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        light_1 : next_state = (counter >= light_time_1-1)?off_1:light_1;  
        off_1   : next_state = (counter >= off_time_1-1)?light_2:off_1;
        light_2 : next_state = (counter >= light_time_2-1)?off_2:light_2;
        off_2   : next_state = (counter >= off_time_2-1)?light_1:off_2;
        default : next_state = light_1; 
    endcase
end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
        end else begin
             if (state != next_state) begin  
                counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
         end
    end

always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            led <= 1'b0;
        end else begin
            case(state)
                light_1, light_2: led <= 1'b1;  
                off_1, off_2:     led <= 1'b0;  
                default:          led <= 1'b0;
            endcase
        end
    end

endmodule