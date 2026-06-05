module uart_rx #(
    parameter CLK_F = 50_00_0000,
    parameter BAUD  = 115200,
    parameter BPS   = CLK_F / BAUD - 1
) (

    input i_clk_50m,
    input i_rst_n_50m,
    input i_tx_data,

    output reg       o_rx_done,
    output reg [7:0] o_rx_data

);


    reg  [2:0] r_tx_data_sync;
    reg  [3:0] r_tx_data_cnt;
    reg  [8:0] bps_cnt;
    reg  [7:0] r_data;
    reg        rx_flag;

    wire       start_en;


    assign start_en = r_tx_data_sync[2] & ~r_tx_data_sync[1] & ~r_tx_data_sync[0];

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_tx_data_sync <= 'd0;
        end else begin
            r_tx_data_sync <= {r_tx_data_sync[1:0], i_tx_data};
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            rx_flag <= 'd0;
        end else if (start_en) begin
            rx_flag <= 'd1;
        end else if (r_tx_data_cnt == 'd9 && bps_cnt == BPS / 2) begin
            rx_flag <= 'd0;
        end else begin
            rx_flag <= rx_flag;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            bps_cnt <= 'd0;
        end else if (rx_flag) begin
            if (bps_cnt == BPS) begin
                bps_cnt <= 'd0;
            end else begin
                bps_cnt <= bps_cnt + 'd1;
            end
        end else begin
            bps_cnt <= 'd0;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_tx_data_cnt <= 'd0;
        end else if (rx_flag) begin
            if (bps_cnt == BPS) begin
                if (r_tx_data_cnt == 'd9) begin
                    r_tx_data_cnt <= 'd0;
                end else begin
                    r_tx_data_cnt <= r_tx_data_cnt + 'd1;
                end
            end
        end else begin
            r_tx_data_cnt <= 'd0;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            r_data <= 'd0;
        end else if (bps_cnt == BPS / 2) begin
            case (r_tx_data_cnt)
                'd1:     r_data[0] <= r_tx_data_sync[2];
                'd2:     r_data[1] <= r_tx_data_sync[2];
                'd3:     r_data[2] <= r_tx_data_sync[2];
                'd4:     r_data[3] <= r_tx_data_sync[2];
                'd5:     r_data[4] <= r_tx_data_sync[2];
                'd6:     r_data[5] <= r_tx_data_sync[2];
                'd7:     r_data[6] <= r_tx_data_sync[2];
                'd8:     r_data[7] <= r_tx_data_sync[2];
                default: r_data <= r_data;
            endcase
        end else begin
            r_data <= r_data;
        end
    end

    always @(posedge i_clk_50m or negedge i_rst_n_50m) begin
        if (!i_rst_n_50m) begin
            o_rx_done <= 'd0;
            o_rx_data <= 'd0;
        end else if (r_tx_data_cnt == 'd9 && bps_cnt == BPS / 2) begin
            o_rx_done <= 'd1;
            o_rx_data <= r_data;
        end else begin
            o_rx_done <= 'd0;
            o_rx_data <= 'd0;
        end
    end
endmodule
