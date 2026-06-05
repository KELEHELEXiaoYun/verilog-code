module rs485_tx #(
    parameter CLK_FRE    = 50_000_000,
    parameter BAUD_RATE  = 115200,
    parameter BPS_115200 = CLK_FRE / BAUD_RATE - 1
) (

    input i_clk,
    input i_rst_n,

    input [7:0] i_tx_data,
    input       i_tx_data_valid,

    output     o_tx_data,
    output reg o_tx_data_ready

);

    localparam T_IDLE = 1;
    localparam T_START = 2;
    localparam T_SEND_BYTE = 3;
    localparam T_STOP = 4;

    reg [2:0] sta, sta_nxt;
    reg [ 7:0] r_tx_data_latch;
    reg        r_o_tx_data;
    reg [15:0] bps_cnt;
    reg [ 3:0] data_cnt;

    assign o_tx_data = r_o_tx_data;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sta <= T_IDLE;
        end else begin
            sta <= sta_nxt;
        end
    end

    always @(*) begin
        case (sta)
            T_IDLE: begin
                if (i_tx_data_valid) begin
                    sta_nxt <= T_START;
                end else begin
                    sta_nxt <= T_IDLE;
                end
            end
            T_START: begin
                if (bps_cnt == BPS_115200) begin
                    sta_nxt <= T_SEND_BYTE;
                end else begin
                    sta_nxt <= T_START;
                end
            end
            T_SEND_BYTE: begin
                if (data_cnt == 'd7 && bps_cnt == BPS_115200) begin
                    sta_nxt <= T_STOP;
                end else begin
                    sta_nxt <= T_SEND_BYTE;
                end
            end
            T_STOP: begin
                if (bps_cnt == BPS_115200) begin
                    sta_nxt <= T_IDLE;
                end else begin
                    sta_nxt <= T_STOP;
                end
            end
            default: sta_nxt <= T_IDLE;
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_data_latch <= 'd0;
        end else if (sta == T_IDLE && i_tx_data_valid) begin
            r_tx_data_latch <= i_tx_data;
        end else begin
            r_tx_data_latch <= r_tx_data_latch;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            bps_cnt <= 'd0;
        end else if (sta == T_SEND_BYTE && bps_cnt == BPS_115200 || sta != sta_nxt) begin
            bps_cnt <= 'd0;
        end else begin
            bps_cnt <= bps_cnt + 'd1;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (i_rst_n == 1'b0) begin
            r_o_tx_data <= 1'b1;
        end else begin
            case (sta)
                T_IDLE, T_STOP: r_o_tx_data <= 1'b1;
                T_START:        r_o_tx_data <= 1'b0;
                T_SEND_BYTE:    r_o_tx_data <= r_tx_data_latch[data_cnt];
                default:        r_o_tx_data <= 1'b1;
            endcase
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            data_cnt <= 'd0;
        end else if (sta == T_SEND_BYTE) begin
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
            o_tx_data_ready <= 'd0;
        end else if (sta != sta_nxt && sta == T_STOP) begin
            o_tx_data_ready <= 'd1;
        end else if (sta == T_IDLE) begin
            if (i_tx_data_valid == 1'b1) begin
                o_tx_data_ready <= 1'b0;
            end else begin
                o_tx_data_ready <= 1'b1;
            end
        end else begin
            o_tx_data_ready <= o_tx_data_ready;
        end
    end

endmodule
