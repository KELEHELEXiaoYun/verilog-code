module key_debounce (
    input clk,
    input rst_n,

    input key,

    output reg key_value,
    output reg key_flag
);

    reg [19:0] cnt;
    reg key_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            key_reg <= 1'b1;
        end else begin
            key_reg <= key;
            if (key_reg != key) begin
                cnt <= 20'd100_0000;
            end else begin
                if (cnt > 0) begin
                cnt <= cnt - 1'b1;
                end else begin
                    cnt <= 0;
                end
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_value <= 1'b1;
            key_flag <= 1'b0;
        end else begin
            if (cnt == 1) begin
                key_flag <= 1'b1;
                key_value <= key;
            end else begin
                key_value <= key_value;
                key_flag  <= 1'b0;
            end
        end
    end
endmodule

module beep_control (
    input clk,
    input rst_n,

    input key_value,
    input key_flag,

    output reg beep
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beep <= 1'b1;
        end else if (key_flag && (key_value == 0)) begin
            beep <= ~beep;            
        end
    end

endmodule

module top_beep (
    input clk,
    input rst_n,

    input key,
    
    output beep
);

    wire key_value;
    wire key_flag;
    
    key_debounce u_key_debounce (
        .clk(clk),
        .rst_n(rst_n),

        .key(key),
        .key_value(key_value),
        .key_flag(key_flag)
    );

    beep_control u_beep_control (
        .clk(clk),
        .rst_n(rst_n),

        .key_value(key_value),
        .key_flag(key_flag),
        .beep(beep)
    );
endmodule