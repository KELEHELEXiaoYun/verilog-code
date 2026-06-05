`timescale 1ns / 1ns

module counter_led_2_tb ();

    reg clk;
    reg reset_n;
    reg led;

    counter_led_2 counter_led_2 (
        clk,
        reset_n,
        led
    );

    defparam counter_led_2.MAX = 50_000;

    initial clk = 1;
    always #10 clk = ~clk;

    initial begin
        reset_n = 0;
        #201;
        reset_n = 1;
        #40_000_000;
        $stop;
    end

endmodule
