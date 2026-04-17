  除了 always 中的变量 为 reg 型 其他都为 wire 型

assign 连续赋值 使用 =  阻塞赋值

! 逻辑非   整体判断后取反 操作数每一位都是0则为逻辑 0 值 有 1 则为逻辑 1 值

~ 按位非  逐位拆解开取反

x 不定态 0/1 都无影响

z 高阻态 既不是0 也不是1 不驱动  主要用于 三态门

两位加减（最高位符号位）法 三位保存结果

&&  逻辑与  多位时 每位自身与 然后再与

&  按位与  单目按位与  reg [3:0] a,c;  assign c = &a; 等价于c = a[1] &a[2]&a[3]&a[0]   判断全1

|| 逻辑或  多位时 每位自身或 然后再与

|按位或 单目按位或 自己每一个相或 判断全 0 

&& 和 || 优先级低于算数运算符  ! 优先级高于双目逻辑运算符  多用括号

多用 && 和 || 少用 ! 

^ 异或 

~^ 异或非

<< 左移操作符 空缺位置用 0 补  A = B<<n  n为移动位数

>> 右移操作符 

 乘法 乘数为2时可用 << 代替   >> 右移 乘法  assign b = a*127; assign c =(a<<7) -a;综合器自动综合

 A? B:C;是否  A 是则B 不是则  A 三目运算符

 case 语句 case(条件)   a: b =c  default :  endcase 

 选择语句 vect(变量名字) [a +: b];{等同于vect[a+b-1:a]}  或 vect[a -:b];{等同于vect[a:a-b+1]}  a为起始位置 加号或减号表示升序或降序 b为位宽  b一定要为常数  多用可以精简代码

{} 拼接运算符

数字默认为32位
always @(posedge clk or negedge Reset_n) begin
            异步复位    
end

always @(posedge clk ) begin
           同步复位
end 

D触发器    always @(posedge clk or negedge Reset_n) 
                    begin
                                if(Reset_n == 0)
                                    begin
                                        q <=0;
                                    end
                                else 
                                    begin
                                        q <= d;
                                    end   
                    end                 

 阻塞赋值 : 一行一行执行 =  组合逻辑使用阻塞赋值

非阻塞赋值: 同时执行 <= 时序逻辑使用非阻塞复制

    {num{vect}}   num必须为常数 复制次数

    全加器  原理：三个输入  两个输出  a,b,cin,sum,cout; 逻辑(sum = a^b^cin   cout = a&&b | a&&cin | b&&cin ) 一位全加器
    // 1位全加器子模块（行为级实现）
module full_adder_1bit (
    input  wire A,    // 1位被加数
    input  wire B,    // 1位加数
    input  wire Cin,  // 低位进位
    output reg  S,    // 本位和
    output reg  Cout  // 高位进位
);
// 组合逻辑：根据全加器公式赋值
always @(*) begin
    S    = A ^ B ^ Cin;          // 本位和 = 异或运算
    Cout = (A & B) | ((A ^ B) & Cin);  // 高位进位 = 与或运算
end
endmodule

    a ^ 0 = a   a^1= ~a 

defparam  例化名.参数名 = n 例化测试名   

casez语句中可用?/x(无关项) 0/1  即 ?100 代表1100和0100

& a[3:0]     // AND: a[3]&a[2]&a[1]&a[0]. Equivalent to (a[3:0] == 4'hf)
| b[3:0]     // OR:  b[3]|b[2]|b[1]|b[0]. Equivalent to (b[3:0] != 4'h0)
^ c[2:0]     // XOR: c[2]^c[1]^c[0]

for (integer i =0 ;i<5; i=i+1 ) begin//always块
    
end

i<$bits(out)  //$bits(out)：系统函数，获取信号的位宽

genvar i;
generate
    for(i=0;i<$bits(in);i++) begin : any
    end
endgenerate

检测上升沿的方法  (从0到1) : 记录上一个状态  然后用下一个状态和取反的上一个状态& 、

检测两边 数值改变的边缘^

模拟双边沿检测
module top_module (
    input clk,
    input d,
    output reg q
);

    reg q1, q2;

    always @(posedge clk) begin
        q1 <= d;
    end

    always @(negedge clk) begin
        q2 <= d;
    end

    always @(*) begin
        q = clk ? q1 : q2;
    end

endmodule

 always @(posedge clk) begin//计数器0-9
        if(reset) q <= 0;
        else if (~ena) q <= q;
        else q <= q < 9 ? q + 1: 0;
    end

    LFSR  随机数生成(伪随机 有规律 但简单并且生成量很大)最大周期2^n -1 
    本质是多项式
 such as // 经典结构，最常用
reg q <= {q[30:0], q[31]^q[21]^q[1]^q[0]};//异或位是抽头的位置
// 并行反馈，适合高速应用
if(q[31])  // 检查最高位是否为1
    q <= (q << 1) ^ POLYNOMIAL;  // 如果是1，左移后与多项式异或
else
    q <= q << 1;  // 如果是0，简单左移

    {s[3:0],s} //若不断重复泽将s左移  反之右移

函数定义 function [7:0] FUN;  fun为函数名同时也是函数返回值 需要定义在模块内
    ;                           只能在模块内调用 必须在beginend书写功能 可以直接用for等函数
                                注意避免时序
endfunction