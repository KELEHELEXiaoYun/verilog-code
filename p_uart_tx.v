module uart_tx #(
    parameter CLK_F = 50_00_0000,
    parameter BAUD  = 115200,
    parameter BPS   = CLK_F / BAUD - 1
) (

    input i_clk_50m,
    input i_rst_n_50m,

    input       i_tx_en,
    input [7:0] i_tx_data,

    output reg o_tx_busy,
    output reg o_tx_data

);

    reg [7:0] r_tx_data_sync;
    reg [3:0] r_data_cnt;
    reg [8:0] r_bps_cnt;

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_tx_data_sync <= 'd0;
            o_tx_busy      <= 'd0;
        end else if (i_tx_en) begin
            r_tx_data_sync <= i_tx_data;
            o_tx_busy      <= 'd1;
        end else if (r_data_cnt == 'd9 && r_bps_cnt == BPS) begin
            r_tx_data_sync <= 'd0;
            o_tx_busy      <= 'd0;
        end else begin
            r_tx_data_sync <= r_tx_data_sync;
            o_tx_busy      <= o_tx_busy;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_bps_cnt <= 'd0;
        end else if (o_tx_busy) begin
            if (r_bps_cnt == BPS) begin
                r_bps_cnt <= 'd0;
            end else begin
                r_bps_cnt <= r_bps_cnt + 'd1;
            end
        end else begin
            r_bps_cnt <= 'd0;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_data_cnt <= 'd0;
        end else if (o_tx_busy) begin
            if (r_bps_cnt == BPS) begin
                if (r_data_cnt == 'd9) begin
                    r_data_cnt <= 'd0;
                end else begin
                    r_data_cnt <= r_data_cnt + 'd1;
                end
            end
        end else begin
            r_data_cnt <= 'd0;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            o_tx_data <= 'd1;
        end else if (o_tx_busy) begin
            case (r_data_cnt)
                0:       o_tx_data <= 0;
                1:       o_tx_data <= r_tx_data_sync[0];
                2:       o_tx_data <= r_tx_data_sync[1];
                3:       o_tx_data <= r_tx_data_sync[2];
                4:       o_tx_data <= r_tx_data_sync[3];
                5:       o_tx_data <= r_tx_data_sync[4];
                6:       o_tx_data <= r_tx_data_sync[5];
                7:       o_tx_data <= r_tx_data_sync[6];
                8:       o_tx_data <= r_tx_data_sync[7];
                9:       o_tx_data <= 'd1;
                default: o_tx_data <= 1'b1;
            endcase
        end else begin
            o_tx_data <= 'd1;
        end
    end

endmodule
