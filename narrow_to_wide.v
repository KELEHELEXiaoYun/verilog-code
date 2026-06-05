module narrow_to_wide #(

) (
    input clk2x,
    input clk1x,

    input [15:0] data16,

    output reg [31:0] data32_clk1x

);

    reg  [15:0] data16_tmp;
    wire [31:0] data32_clk1x_nxt;

    always @(posedge clk2x) begin
        data16_tmp <= data16;
    end

    assign data32_clk1x_nxt = {data16[15:0], data16_tmp[15:0]};

    always @(posedge clk1x) begin
        data32_clk1x <= data32_clk1x_nxt;
    end

endmodule
