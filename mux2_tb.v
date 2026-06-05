`timescale 1ns / 1ns
module mux2_tb ();

    reg  s_a;
    reg  s_b;
    reg  select;
    wire out;

    mux2 mux2_inst0 (
        .a     (s_a),
        .b     (s_b),
        .select(select),
        .out   (out)
    );

    initial begin
        s_a    = 0;
        s_b    = 0;
        select = 0;
        #200;
        s_a    = 0;
        s_b    = 0;
        select = 1;
        #200;
        s_a    = 0;
        s_b    = 1;
        select = 0;
        #200;
        s_a    = 0;
        s_b    = 1;
        select = 1;
        #200;
        s_a    = 0;
        s_b    = 0;
        select = 0;
        #200;
        s_a    = 0;
        s_b    = 0;
        select = 1;
        #200;
        s_a    = 0;
        s_b    = 1;
        select = 0;
        #200;
        s_a    = 0;
        s_b    = 1;
        select = 1;
        #200;
        $stop;
    end
endmodule
