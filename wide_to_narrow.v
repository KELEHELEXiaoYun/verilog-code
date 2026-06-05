module wide_to_narrow #(

) (

    input clk2x,
    input clk1x,

    input [31:0] datain,

    output reg [15:0] dataout_clk2x

);

    reg  [31:0] datain_sync;
    wire [15:0] dataout_clk2x_nxt;

    always @(posedge clk2x) begin
        datain_sync <= datain;
    end

    assign dataout_clk2x_nxt = !clk1x ? datain_sync[15:0] : datain_sync[31:16];

    always @(posedge clk2x) begin
        dataout_clk2x <= dataout_clk2x_nxt;
    end


endmodule
