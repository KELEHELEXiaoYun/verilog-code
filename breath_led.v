module breath_led (
    input clk,
    input rst_n,

    output led
);

    reg [15:0] cnt;
    reg [15:0] duty_cycle;
    reg        inc_dec_flag;  //0递增  1递减

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else if (cnt == 50_000) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_cycle   <= 0;
            inc_dec_flag <= 0;
        end else begin
            if (cnt == 50_000) begin
                if (inc_dec_flag == 0) begin
                    if (duty_cycle == 50_000) begin
                        inc_dec_flag <= 1;
                    end else begin
                        duty_cycle <= duty_cycle + 16'd25;
                    end
                end else begin
                    if (duty_cycle == 0) begin
                        inc_dec_flag <= 0;
                    end else begin
                        duty_cycle <= duty_cycle - 16'd25;
                    end
                end
            end
        end
    end

    assign led = (cnt > duty_cycle) ? 1 : 0;

endmodule
