module gray_to_binary #(
    parameter PTR = 8
) (

    input [PTR:0] gray_value,

    output [PTR:0] binary_value

);


    assign binary_value[PTR] = gray_value[PTR];

    generate
        genvar i;
        for (i = 0; i < (PTR); i = i + 1'b1) begin
            assign binary_value[i] = binary_value[i+1] ^ gray_value[i];
        end
    endgenerate


endmodule
