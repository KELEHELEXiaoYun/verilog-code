module counter_led_0(
    input clk,
    input reset_n,
    output led
);

    //时钟频率50MHz
    parameter MAX = 50_000_000;
    reg [25:0]counter;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter  <= 0;
        end else if(counter == MAX - 1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            led <= 0;
        end else if(counter == MAX /2- 1) begin
            led <= 1;
        end else if(counter == MAX - 1) begin
            led <= 0;
        end else begin
            led <= led;
        end
    end


endmodule