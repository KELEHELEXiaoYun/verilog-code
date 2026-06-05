module led_run (
    Clk,
    Reset_n,
    Led
);

    input Clk;
    input Reset_n;
    output /*reg*/ /*wire*/ [7:0] Led;  //底层应为wire型 

    reg [24:0] counter;

    parameter MCNT = 25'd24999999;  //定义参数

    always @(posedge Clk or negedge Reset_n)
        if (!Reset_n) counter <= 0;
        //    else if(counter == MCNT)
        else if (counter == MCNT) counter <= 0;
        else counter <= counter + 1'b1;

    /*   always@(posedge Clk or negedge Reset_n)
    if(!Reset_n)
        Led <= 8'b0000_0001;
//    else if(counter == MCNT)begin
      else if(counter == MCNT)begin
*/
    /*if(Led == 8'b1000_0000)
            Led <= 8'b0000_0001;
        else
            Led <= Led << 1;   */
    /*          Led <= {Led[6:0],Led[7]};  
   end
    else
        Led <= Led;
 */
    reg [2:0] counter2;

    always @(posedge Clk or negedge Reset_n)
        if (!Reset_n) counter2 <= 0;
        //    else if(counter2 == 7)
        //       counter2 <= 0;
        //     else if(counter == MCNT)
        else if (counter == MCNT) counter2 <= counter2 + 1'b1;

    decoder_3_8 decoder_3_8 (
        .a  (counter2[2]),
        .b  (counter2[1]),
        .c  (counter2[0]),
        .out(Led)
    );

endmodule
