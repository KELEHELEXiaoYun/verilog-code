module reset_synchronizer (

    input clkb,
    input rstb_in,

    output reg rstb_sync

);

    reg rstb_in_pre;

    always @(posedge clkb or negedge rstb_in) begin
        if (rstb_in) begin
            rstb_in_pre <= 1'b0;
            rstb_sync   <= 1'b0;
        end else begin
            rstb_in_pre <= 1'b1;
            rstb_sync   <= rstb_in_pre;
        end
    end

endmodule
