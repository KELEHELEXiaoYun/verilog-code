module counter_led_6_tb();

reg clk;
reg reset_n;
reg [7:0] ctrl;
reg [31:0] Time;
wire led;

counter_led_6 counter_led_6 (clk,reset_n,ctrl,Time,led);

initial clk = 1;
always #10 clk = ~clk;

initial begin
reset_n = 0;
#201;
reset_n = 1;
ctrl = 8'b1001_1100;
Time = 50_000;
#40_000_000;
ctrl = 8'b1100_1010;
Time = 100_000;
#40_000_000;
$stop;
end


endmodule