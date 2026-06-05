`timescale 1ns / 1ns

module led_run_tb;
    reg        Clk;
    reg        Reset_n;
    wire [7:0] Led;

    /*    led_run
        #(
            .MCNT(24999)
         )
*/
    led_run led_run_inst0 (
        .Clk    (Clk),
        .Reset_n(Reset_n),
        .Led    (Led)
    );

    defparam led_run_inst0.MCNT = 24999;

    initial Clk = 1;
    always #10 Clk = ~Clk;

    initial begin
        Reset_n = 0;
        #201;
        Reset_n = 1;
        //       #4000000000;
        #40000000;
        $stop;
    end

endmodule
