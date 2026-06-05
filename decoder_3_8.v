module decoder_3_8 (
    a,
    b,
    c,
    out
);

    input a;
    input b;
    input c;
    output reg [7:0] out;
    //   reg [7:0] out;

    //以always块描述的信号赋值，被赋值对象必须定义为reg类型
    //  wire[3:0] d;
    //  assign d = {a,1'b0,b,c};

    always @(*) begin  //always(a,b,c)
        case ({
            a, b, c
        })  //{a,b,c}变成了一个三位的信号，这种操作叫做位拼接
            3'b000: out = 8'b0000_0001;
            3'b001: out = 8'b0000_0010;
            3'b010: out = 8'b0000_0100;
            3'b011: out = 8'b0000_1000;
            3'b100: out = 8'b0001_0000;
            3'b101: out = 8'b0010_0000;
            3'b110: out = 8'b0100_0000;
            3'b111: out = 8'b1000_0000;
        endcase
    end

    //b 二进制 3'b101 8'b0000_1010 
    //d 十进制  3'd5  8'd10
    //h 十六进制       8ha
    //h 十六进制       8ha
endmodule
