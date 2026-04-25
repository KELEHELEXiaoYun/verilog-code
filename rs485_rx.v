module rs485_rx #(
    parameter CLK_FRE    =50_000_000,
    parameter BAUD_RATE  = 115200,
    parameter BPS_115200 = CLK_FRE / BAUD_RATE - 1
) (
    
    input  i_clk,
    input  i_rst_n,

    input  i_rx_data,
    input  i_rx_data_ready,

    output reg [7:0] o_rx_data,
    output reg       o_rx_data_valid

);

    localparam  R_IDLE     = 0;
    localparam  R_START    = 1;
    localparam  R_REC_BYTE = 2;
    localparam  R_STOP     = 3;
    localparam  R_DATA     = 4;

    reg  [2:0]  sta, sta_nxt;
    reg  [1:0]  r_rx_data_sync;
    reg  [15:0] bps_cnt;
    reg  [2:0]  data_cnt; 
    reg  [7:0]  r_o_rx_data;
    wire        r_rx_data_neg;
    
    assign r_rx_data_neg = r_rx_data_sync[1] & ~r_rx_data_sync[0];

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_rx_data_sync <= 'd0;
        end else begin
            r_rx_data_sync <= {r_rx_data_sync[0],i_rx_data};
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sta     <= R_IDLE;
        end else begin
            sta     <= sta_nxt;
        end
    end

    always @(*) begin
        case (sta)
            R_IDLE: begin
                if (r_rx_data_neg) begin
                    sta_nxt <= R_START;
                end else begin
                    sta_nxt <= R_IDLE;
                end
            end
            R_START: begin
                if (bps_cnt == BPS_115200 / 2) begin
                    if (r_rx_data_sync[1] == 'd0) begin
                    sta_nxt <= R_REC_BYTE;
                    end else begin
                        sta_nxt <= R_IDLE;
                    end
                end else begin
                    sta_nxt <= R_START;
                end
            end
            R_REC_BYTE: begin
                if (data_cnt == 'd7 && bps_cnt == BPS_115200) begin
                    sta_nxt <= R_STOP;
                end else begin
                    sta_nxt <= R_REC_BYTE;
                end
            end
            R_STOP: begin
                if (bps_cnt == BPS_115200 / 2) begin
                    sta_nxt <= R_DATA;
                end else begin
                    sta_nxt <= R_STOP;
                end
            end
            R_DATA: begin
                if (i_rx_data_ready) begin
                    sta_nxt <= R_IDLE;
                end else begin
                    sta_nxt <= R_DATA;
                end
            end
            default: sta_nxt <= R_IDLE;
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            bps_cnt <= 'd0;
        end else if (sta != sta_nxt || bps_cnt == BPS_115200 && sta == R_REC_BYTE) begin
            bps_cnt <= 'd0;
        end else begin
            bps_cnt <= bps_cnt + 'd1;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            data_cnt <= 'd0;
        end else if (sta == R_REC_BYTE) begin
            if (bps_cnt == BPS_115200) begin
                data_cnt <= data_cnt + 'd1;
            end else begin
                data_cnt <= data_cnt;
            end
        end else begin
            data_cnt <= 'd0;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_rx_data_valid <= 'd0;
        end else if (sta == R_STOP && sta != sta_nxt) begin
            o_rx_data_valid <= 'd1;
        end else if (sta == R_DATA && i_rx_data_ready) begin
            o_rx_data_valid <= 'd0;
        end else begin
            o_rx_data_valid <= o_rx_data_valid;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_o_rx_data <= 'd0;
        end else if (sta == R_REC_BYTE && bps_cnt == BPS_115200 / 2) begin
            r_o_rx_data[data_cnt] <= r_rx_data_sync[1];
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_rx_data <= 'd0;
        end else if (sta == R_STOP && sta !=sta_nxt) begin
            o_rx_data <= r_o_rx_data;
        end else begin
            o_rx_data <= o_rx_data;
        end
    end

endmodule