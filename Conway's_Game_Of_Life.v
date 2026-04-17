module Conway_s_Game_Of_Life_16_16(
    input clk,
    input load,
    input [255:0] data,
    output reg [255:0] q ); 
    
    wire [17:0] two_reg [17:0];
    reg [16:1] q_next [16:1];
    reg [3:0] count;
    reg [17:0] up,down,middle;
    
    assign two_reg[0] = {q[240],q[255:240],q[255]};
    assign two_reg[1] = {q[0],q[15:0],q[15]};
    assign two_reg[2] = {q[16],q[31:16],q[31]};
    assign two_reg[3] = {q[32],q[47:32],q[47]};
    assign two_reg[4] = {q[48],q[63:48],q[63]};
    assign two_reg[5] = {q[64],q[79:64],q[79]};
    assign two_reg[6] = {q[80],q[95:80],q[95]};
    assign two_reg[7] = {q[96],q[111:96],q[111]};
    assign two_reg[8] = {q[112],q[127:112],q[127]};
    assign two_reg[9] = {q[128],q[143:128],q[143]};
    assign two_reg[10] = {q[144],q[159:144],q[159]};
    assign two_reg[11] = {q[160],q[175:160],q[175]};
    assign two_reg[12] = {q[176],q[191:176],q[191]};
    assign two_reg[13] = {q[192],q[207:192],q[207]};
    assign two_reg[14] = {q[208],q[223:208],q[223]};
    assign two_reg[15] = {q[224],q[239:224],q[239]};
    assign two_reg[16] = {q[240],q[255:240],q[255]};
    assign two_reg[17] = {q[0],q[15:0],q[15]};
	
    integer i,j;
    always @(*) begin
        for(i = 1;i < 17;i = i+1) begin
            for(j = 1;j < 17;j = j+1) begin
                up = two_reg[i-1];
                middle = two_reg[i];
                down = two_reg[i+1];
                count = up[j]+up[j+1]+up[j-1]+middle[j-1]+middle[j+1]+down[j]+down[j+1]+down[j-1];
                if(count == 2) begin
                    q_next[i][j] = two_reg[i][j];
                end else if(count == 3) begin
                    q_next[i][j] = 1; 
                end else begin
                    q_next[i][j] = 0;
                end
            end
        end
    end
    
    always @(posedge clk) begin
        if(load) begin
           q <= data; 
        end else begin
            q[15:0] <= q_next[1];
            q[31:16] <= q_next[2];
            q[47:32] <= q_next[3];
            q[63:48] <= q_next[4];
            q[79:64] <= q_next[5];
            q[95:80] <= q_next[6];
            q[111:96] <= q_next[7];
            q[127:112] <= q_next[8];
            q[143:128] <= q_next[9];
            q[159:144] <= q_next[10];
            q[175:160] <= q_next[11];
            q[191:176] <= q_next[12];
            q[207:192] <= q_next[13];
            q[223:208] <= q_next[14];
            q[239:224] <= q_next[15];
            q[255:240] <= q_next[16];
        end
    end
endmodule
