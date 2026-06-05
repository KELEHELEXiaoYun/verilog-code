module counter_led_5 (
    input            clk,
    input            reset_n,
    input      [7:0] Time   [0:31],
    input      [7:0] ctrl   [ 0:7],
    output reg [7:0] led
);

    //多个 LED 灯
    //按照设置的模式各自在一个变化循环内独立亮灭变化“

    reg  [7:0] counter      [0:31];
    reg  [7:0] counter_ctrl [ 0:2];
    wire [7:0] next_counter;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : loop_led

            always @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    counter[i] <= 0;
                end else if (counter[i] == Time[i] - 1) begin
                    counter[i] <= 0;
                end else begin
                    counter[i] <= counter[i] + 1'b1;
                end
            end

            assign next_counter[i] = counter[i] == Time[i] - 1;

            always @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    counter_ctrl[i] <= 0;
                end else if (next_counter[i] && counter_ctrl[i] == 7) begin
                    counter_ctrl[i] <= 0;
                end else if (next_counter) begin
                    counter_ctrl[i] <= counter_ctrl[i] + 1'b1;
                end
            end

            always @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    led[i] <= 0;
                end else begin
                    case (counter_ctrl[i])
                        3'b0:    led[i] <= ctrl[i][0];
                        3'b1:    led[i] <= ctrl[i][1];
                        3'd2:    led[i] <= ctrl[i][2];
                        3'd3:    led[i] <= ctrl[i][3];
                        3'd4:    led[i] <= ctrl[i][4];
                        3'd5:    led[i] <= ctrl[i][5];
                        3'd6:    led[i] <= ctrl[i][6];
                        3'd7:    led[i] <= ctrl[i][7];
                        default: led[i] <= 0;
                    endcase
                end
            end

        end
    endgenerate



endmodule
