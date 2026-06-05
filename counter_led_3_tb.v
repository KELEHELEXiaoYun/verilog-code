module counter_led_3_tb ();

    reg        clk;
    reg        reset_n;
    reg  [7:0] ctrl;
    wire       led;

    counter_led_3 counter_led_3 (
        clk,
        reset_n,
        ctrl,
        led
    );
    defparam counter_led_3.MAX = 50_000;

    initial clk = 1;
    always #10 clk = ~clk;

    initial begin
        reset_n = 0;
        #201;
        reset_n = 1;
        ctrl    = 8'b1001_1100;
        #40_000_000;
        ctrl = 8'b1100_1010;
        #40_000_000;
        $stop;
    end


endmodule
