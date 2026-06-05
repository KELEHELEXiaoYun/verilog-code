module mux2 (
    a,
    b,
    select,
    out
);

    input a;
    input b;
    input select;
    output out;

    assign out = (select == 1) ? a : b;
    // assign out = selet?b:a;
endmodule
