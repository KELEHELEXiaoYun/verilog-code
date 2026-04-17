module binary_to_gray #(
    parameter PTR = 8
) (
    
    input  [PTR:0] binary_value,
    
    output [PTR:0] gray_value

);


    generate
        genvar i;
        for (i = 0; i < (PTR); i = i + 1'b1) begin
            assign gray_value[i] = binary_value[i] ^ binary_value[i+1];
        end
    endgenerate


    assign gray_value[PTR] = binary_value[PTR];
    
    
endmodule