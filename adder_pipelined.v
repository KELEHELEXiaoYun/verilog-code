module adder_pipelined(

    input           clk,
    input           rst_n,

    input  [63:0]   A,
    input  [63:0]   B,
    
    output [64:0]   FinalSUM ,

);
    reg  [32:0]  Lsum_d1;
    wire [32:0]  Lsum_d1_nxt,
    wire         Carry_d1;
    reg  [31:0]  Lsum_d2, Aup_d1,Bup_d1;
    reg  [32:0]  Usum_d2;
    wire [32:0]  Usum_d2_nxt;


    assign Lsum_d1_nxt = A[31:0] + B[31:0];
    assign Carry_d1    = Lsum_d1[32];
    assign Usum_d2_nxt = Carry_d1 + Aup_d1 + Bup_d1;
    assign FinalSUM    = {Usum_d2,Lsum_d2};

    always @(posedge clk or negedge) begin
        if (!rst_n) begin
            Lsum_d1 <= 'd0;
            Lsum_d2 <= 'd0;
            Aup_d1  <= 'd0;
            Bup_d1  <= 'd0;
            Usum_d2 <= 'd0;
        end else begin
            Lsum_d1 <= Lsum_d1_nxt;
            Lsum_d2 <= Lsum_d1[31:0];
            Aup_d1  <= A[63:32];
            Bup_d1  <= B[63:32];
            Usum_d2 <= Usum_d2_nxt;
        end
    end
endmodule //adder_pipelined
