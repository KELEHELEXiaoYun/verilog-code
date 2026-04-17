`timescale 1ns/1ns

module decioder_3_8_tb;
    
    reg s_a;
    reg s_b;
    reg c;
    wire [7:0] out;
    
    decoder_3_8 decoder_3_8_(
    .a(s_a),
    .b(s_b),
    .c(c),
    .out(out)
);

initial begin
    s_a = 0; s_b = 0;c = 0;
    #200;
    s_a = 0; s_b = 0;c = 1;
    #200;
    s_a = 0; s_b = 1;c = 0;
    #200;
    s_a = 0; s_b = 1;c = 1;
    #200;
    s_a = 1; s_b = 0;c = 0;
    #200;
    s_a = 1; s_b = 0;c = 1;
    #200;
    s_a = 1; s_b = 1;c = 0;
    #200;
    s_a = 1; s_b = 1;c = 1;
    #200;
    $stop;
end
endmodule