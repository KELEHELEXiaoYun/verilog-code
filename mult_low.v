module mult_low #(
    parameter M = 4,
    parameter N = 4
) (

    input clk,
    input rst_n,

    input         data_rdy,
    input [N-1:0] mult1,
    input [M-1:0] mult2,

    output           res_rdy,
    output [M+N-1:0] res

);

    reg  [31:0] cnt;

    wire [31:0] cnt_tmp = cnt == M ? 'b0 : cnt + 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 'b0;
        end else if (data_rdy) begin
            cnt <= cnt_tmp;
        end else if (cnt != 0) begin
            cnt <= cnt_tmp;
        end else begin
            cnt <= 'b0;
        end
    end

    reg [  M-1:0] mult2_shift;
    reg [M+N-1:0] mult1_shift;
    reg [M+N-1:0] mult1_acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult2_shift <= 'b0;
            mult1_shift <= 'b0;
            mult1_acc   <= 'b0;
        end else if (cnt == 'b0 && data_rdy) begin
            mult1_shift <= {{(N) {1'b0}}, mult1} << 1;
            mult2_shift <= mult2 >> 1;
            mult1_acc   <= mult2[0] ? {{(N) {1'b0}}, mult1} : 'b0;
        end else if (cnt != M) begin
            mult1_shift <= mult1_shift << 1;
            mult2_shift <= mult2_shift >> 1;
            mult1_acc   <= mult2_shift[0] ? mult1_acc + mult1_shift : mult1_acc;
        end else begin
            mult1_shift <= 'b0;
            mult2_shift <= 'b0;
            mult1_acc   <= 'b0;
        end
    end

    reg [M+N-1:0] res_r;
    reg           res_rdy_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res_r     <= 'b0;
            res_rdy_r <= 'b0;
        end else if (cnt == M) begin
            res_r     <= mult1_acc;
            res_rdy_r <= 1'b1;
        end else begin
            res_r     <= 'b0;
            res_rdy_r <= 'b0;
        end
    end

    assign res     = res_r;
    assign res_rdy = res_rdy_r;

endmodule
