module led(
    input clk,
    input rst_n,
    
    output reg led
    );
    
    parameter MAX = 24_999_999;
    (* mark_debug = "true" *) reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)  begin
            led <= 0;
            cnt <= 0;
        end else begin
            if (cnt == MAX) begin
                cnt <= 0;
                led <= ~led;
            end else begin
                led <= ~led;
                cnt <= cnt + 1'b1;
            end
        end
    end
    
endmodule


module led_tb ();

    reg clk , rst_n;

    always #10 clk = ~clk;
  
    led #(
        .MAX (9)
    )u_led (,clk, .rst_n, .led );

    initial begin
        clk <= 0;
        rst_n <= 0;
        #200
        rst_n <= 1;
        #10000000000
    end


endmodule
