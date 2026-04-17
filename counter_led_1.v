module counter_led_1(
    input clk,
    input reset_n,
    output led
);
    //亮灯0.25s 灭0.75s
    parameter MAX = 50_000_000;
    reg [31:0]counter;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            counter <= 0;
        end else if(counter == MAX) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            led <= 0;
        end else begin
            led <= (counter < MAX/4 - 1)1:0;
        end
    end

endmodule