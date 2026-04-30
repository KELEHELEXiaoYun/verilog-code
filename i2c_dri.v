module i2c_dri #(
    parameter CLK_FREQ     = 50_000_000,
    parameter SCL_FREQ     = 400_000,
    parameter SLAVE_ADDR   = 1010000
) (

    input                       i_clk,
    input                       i_rst_n,

    input                       i_i2c_exec,
    input                       i_bit_ctrl,
    input                       i_i2c_rh_wl,

    input        [15:0]         i_i2c_addr,
    input        [7:0]          i_i2c_data_w,

    output  reg                 o_dri_clk,
    output                      o_i2c_done,
    output                      o_i2c_ack,
    output                      o_scl,

    output       [7:0]          o_i2c_data_r,

    inout                       io_sda

);

    localparam  DRI_FREQ    = SCL_FRQ << 2;
    localparam  DRI_CNT    = CLK_FRQ / DRI_FRQ / 2;

    localparam  ST_IDLE    = 0;
    localparam  ST_SLADDR  = 1;
    localparam  ST_ADDR16  = 2;
    localparam  ST_ADDR8   = 3;
    localparam  ST_DATA_WR = 4;
    localparam  ST_ADDR_RD = 5;
    localparam  ST_DATA_RD = 6;
    localparam  ST_STOP    = 7;

    reg  [2:0]  sta, nsta;
    reg  [3:0]  dri_cnt;
    reg         st_done;
    reg         wr_flag;
    reg         sda_out;
    reg         sda_in;
    reg         sda_dir;
    reg  [5:0]  cnt;
    reg  [15:0] r_i2c_addr;
    reg  [7:0]  r_i2c_data_w;
    reg  [7:0]  r_i2c_data_r;

    assign io_sda = sda_dir? sda_out: 1'bz;
    assign sda_in = io_sda;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            dri_cnt   <= 4'd0;
            o_dri_clk <= 1'd0;
        end else if (dri_cnt == DRI_CNT - 1) begin
            dri_cnt   <= 4'd0;
            o_dri_clk <= !o_dri_clk;
        end else begin
            dri_cnt   <= dri_cnt + 4'd1;
            o_dri_clk <= o_dri_clk;
        end
    end

    always @(*) begin
        case (sta)
            ST_IDLE: begin
                if (i_i2c_exec) begin
                    nsta <= ST_SLADDR;
                end
            end 
            ST_SLADDR: begin
                if (i_bit_ctrl) begin
                    nsta <= ST_ADDR16;
                end else begin
                    nsta <= ST_ADDR8;
                end
            end
            ST_ADDR16: begin
                if (st_done) begin
                    nsta <= ST_ADDR8;
                end else begin
                    nsta <= ST_ADDR16;
                end
            end
            ST_ADDR8: begin
                if (wr_flag) begin
                    nsta <= ST_ADDR_RD;
                end else begin
                    nsta <=  ST_DATA_WR;
                end
            end
            ST_DATA_RD: begin
                if (st_done) begin
                    nsta <= ST_STOP;
                end else begin
                    nsta <= ST_DATA_RD;
                end
            end
            ST_DATA_WR: begin
                if (st_done) begin
                    nsta <= ST_STOP;
                end else begin
                    nsta <= ST_DATA_WR;
                end
            end
            ST_STOP: begin
                if (st_done) begin
                    nsta <= ST_IDLE;
                end else begin
                    nsta <= ST_STOP;
                end
            end
            default: nsta <= ST_IDLE;
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sta <= ST_IDLE;
        end else begin
            sta <= nsta;
        end
        
    end

    always @(posedge o_dri_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_scl        <= 1'b1;
            sda_out      <= 1'b1;
            sda_dir      <= 1'b1;
            wr_flag      <= 1'b1;
            st_done      <= 1'b0;
            o_i2c_done   <= 1'b0;
            o_i2c_ack    <= 1'b0;
            o_i2c_data_r <= 8'b0;
        end else begin
            st_done <= 1'b0;
            cnt     <= cnt + 1'b1;
            case (sta)
                ST_IDLE: begin
                    o_scl      <= 1'b1;
                    sda_out    <= 1'b1;
                    sda_dir    <= 1'b1;
                    o_i2c_done <= 1'b0;
                    cnt        <= 1'b0;
                    if (i_i2c_exec) begin
                        wr_flag      <= i_i2c_rh_wl;
                        r_i2c_addr   <= i_i2c_addr;
                        r_i2c_data_w <= i_i2c_data_w;
                        o_i2c_ack    <= 1'b0;
                    end else begin
                        r_i2c_addr   <= r_i2c_addr;
                        r_i2c_data_w <= r_i2c_data_w;
                        o_i2c_ack    <= o_i2c_ack;
                    end
                end
                    ST_SLADDR: begin
                        case (cnt)
                            7'd1 : sda_out <= 1'b0;
                            7'd3 : o_scl   <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];
                            7'd5 : o_scl   <= 1'b1;
                            7'd7 : o_scl   <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : o_scl   <= 1'b1;
                            7'd11: o_scl   <= 1'b0;
                            7'd12: sda_dir <= SLAVE_ADDR[4];
                            7'd13: o_scl   <= 1'b1;
                            7'd15: o_scl   <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: o_scl   <= 1'b1;
                            7'd19: o_scl   <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: o_scl   <= 1'b1;
                            7'd23: o_scl   <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: o_scl   <= 1'b1;
                            7'd27: o_scl   <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: o_scl   <= 1'b1;
                            7'd31: o_scl   <= 1'b0;
                            7'd32: sda_out <= 1'b0;
                            7'd33: o_scl   <= 1'b1;
                            7'd35: o_scl   <= 1'b0;
                            7'd36: begin
                                sda_dir <= 1'b0;
                                sda_out <= 1'b1;
                            end
                            7'd37: o_scl <= 1'b1;
                            7'd38: begin
                                if (sda_in) begin
                                    st_done   <= 1'b0;
                                    o_i2c_ack <= 1'b1;
                                end else begin
                                    st_done <= 1'b1;
                                end
                            end
                            7'd39: begin
                                o_scl <= 1'b0;
                                cnt   <= 7'b0;
                            end 
                            default: begin end
                        endcase
                    end
                ST_ADDR16: begin
                    case (cnt)
                            7'd0 : begin
                                   sda_dir <= 1'b1;
                                   sda_out <= r_i2c_addr[15];
                            end
                            7'd1 : o_scl   <= 1'b1;
                            7'd3 : o_scl   <= 1'b0;
                            7'd4 : sda_out <= r_i2c_addr[14];
                            7'd5 : o_scl   <= 1'b1;
                            7'd7 : o_scl   <= 1'b0;
                            7'd8 : sda_out <= r_i2c_addr[13];
                            7'd9 : o_scl   <= 1'b1;
                            7'd11: o_scl   <= 1'b0;
                            7'd12: sda_out <= r_i2c_addr[12];
                            7'd13: o_scl   <= 1'b1;
                            7'd15: o_scl   <= 1'b0;
                            7'd16: sda_out <= r_i2c_addr[11];
                            7'd17: o_scl   <= 1'b1;
                            7'd19: o_scl   <= 1'b0;
                            7'd20: sda_out <= r_i2c_addr[10];
                            7'd21: o_scl   <= 1'b1;
                            7'd23: o_scl   <= 1'b0;
                            7'd24: sda_out <= r_i2c_addr[9];
                            7'd25: o_scl   <= 1'b1;
                            7'd27: o_scl   <= 1'b0;
                            7'd28: sda_out <= r_i2c_addr[8];
                            7'd29: o_scl   <= 1'b1;
                            7'd31: o_scl   <= 1'b0;
                            7'd32: begin
                                sda_dir <= 1'b0;
                                sda_out <= 1'b1;
                            end
                            7'd33: o_scl   <= 1'b1;
                            7'd34: begin
                                if (sda_in) begin
                                    st_done   <= 1'b0;
                                    o_i2c_ack <= 1'b1;
                                end else begin
                                    st_done <= 1'b1;
                                end
                            end
                            7'd35: begin 
                                o_scl <= 1'b0;
                                cnt   <= 7'd0;
                            end
                            default: begin end
                        endcase
                    end
                    ST_ADDR8: begin
                    case (cnt)
                            7'd0 : begin
                                   sda_dir <= 1'b1;
                                   sda_out <= r_i2c_addr[7];
                            end
                            7'd1 : o_scl   <= 1'b1;
                            7'd3 : o_scl   <= 1'b0;
                            7'd4 : sda_out <= r_i2c_addr[6];
                            7'd5 : o_scl   <= 1'b1;
                            7'd7 : o_scl   <= 1'b0;
                            7'd8 : sda_out <= r_i2c_addr[5];
                            7'd9 : o_scl   <= 1'b1;
                            7'd11: o_scl   <= 1'b0;
                            7'd12: sda_out <= r_i2c_addr[4];
                            7'd13: o_scl   <= 1'b1;
                            7'd15: o_scl   <= 1'b0;
                            7'd16: sda_out <= r_i2c_addr[3];
                            7'd17: o_scl   <= 1'b1;
                            7'd19: o_scl   <= 1'b0;
                            7'd20: sda_out <= r_i2c_addr[2];
                            7'd21: o_scl   <= 1'b1;
                            7'd23: o_scl   <= 1'b0;
                            7'd24: sda_out <= r_i2c_addr[1];
                            7'd25: o_scl   <= 1'b1;
                            7'd27: o_scl   <= 1'b0;
                            7'd28: sda_out <= r_i2c_addr[0];
                            7'd29: o_scl   <= 1'b1;
                            7'd31: o_scl   <= 1'b0;
                            7'd32: begin
                                sda_dir <= 1'b0;
                                sda_out <= 1'b1;
                            end
                            7'd33: o_scl   <= 1'b1;
                            7'd34: begin
                                if (sda_in) begin
                                    st_done   <= 1'b0;
                                    o_i2c_ack <= 1'b1;
                                end else begin
                                    st_done <= 1'b1;
                                end
                            end
                            7'd35: begin 
                                o_scl <= 1'b0;
                                cnt   <= 7'd0;
                            end
                            default: begin end
                        endcase
                    end
                    ST_DATA_WR: begin
                    case (cnt)
                            7'd0 : begin
                                   sda_dir <= 1'b1;
                                   sda_out <= r_i2c_data_w[7];
                            end
                            7'd1 : o_scl   <= 1'b1;
                            7'd3 : o_scl   <= 1'b0;
                            7'd4 : sda_out <= r_i2c_data_w[6];
                            7'd5 : o_scl   <= 1'b1;
                            7'd7 : o_scl   <= 1'b0;
                            7'd8 : sda_out <= r_i2c_data_w[5];
                            7'd9 : o_scl   <= 1'b1;
                            7'd11: o_scl   <= 1'b0;
                            7'd12: sda_out <= r_i2c_data_w[4];
                            7'd13: o_scl   <= 1'b1;
                            7'd15: o_scl   <= 1'b0;
                            7'd16: sda_out <= r_i2c_data_w[3];
                            7'd17: o_scl   <= 1'b1;
                            7'd19: o_scl   <= 1'b0;
                            7'd20: sda_out <= r_i2c_data_w[2];
                            7'd21: o_scl   <= 1'b1;
                            7'd23: o_scl   <= 1'b0;
                            7'd24: sda_out <= r_i2c_data_w[1];
                            7'd25: o_scl   <= 1'b1;
                            7'd27: o_scl   <= 1'b0;
                            7'd28: sda_out <= r_i2c_data_w[0];
                            7'd29: o_scl   <= 1'b1;
                            7'd31: o_scl   <= 1'b0;
                            7'd32: begin
                                sda_dir <= 1'b0;
                                sda_out <= 1'b1;
                            end
                            7'd33: o_scl   <= 1'b1;
                            7'd34: begin
                                if (sda_in) begin
                                    st_done   <= 1'b0;
                                    o_i2c_ack <= 1'b1;
                                end else begin
                                    st_done <= 1'b1;
                                end
                            end
                            7'd35: begin 
                                o_scl <= 1'b0;
                                cnt   <= 7'd0;
                            end
                            default: begin end
                        endcase
                    end
                    ST_ADDR_RD: begin
                        case (cnt)
                            7'd0 : begin 
                                sda_out <= 1'b1;
                                sda_dir <= 1'b1;
                            end
                            7'd1 : o_scl   <= 1'b1;
                            7'd2 : sda_out <= 1'b0;
                            7'd3 : o_scl   <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];
                            7'd5 : o_scl   <= 1'b1;
                            7'd7 : o_scl   <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : o_scl   <= 1'b1;
                            7'd11: o_scl   <= 1'b0;
                            7'd12: sda_out <= SLAVE_ADDR[4];
                            7'd13: o_scl   <= 1'b1;
                            7'd15: o_scl   <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: o_scl   <= 1'b1;
                            7'd19: o_scl   <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: o_scl   <= 1'b1;
                            7'd23: o_scl   <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: o_scl   <= 1'b1;
                            7'd27: o_scl   <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: o_scl   <= 1'b1;
                            7'd31: o_scl   <= 1'b0;
                            7'd32: sda_out <= 1'b1;
                            7'd33: o_scl   <= 1'b1;
                            7'd35: o_scl   <= 1'b0;
                            7'd36: begin
                                sda_dir <= 1'b0;
                                sda_out <= 1'b1;
                            end
                            7'd37: o_scl   <= 1'b1;
                            7'd38   : begin
                                if (sda_in) begin
                                    st_done   <= 1'b0;
                                    o_i2c_ack <= 1'b1;
                                end else begin
                                    st_done <= 1'b1;
                                end
                            end
                            7'd39: begin
                                o_scl <= 1'b0;
                                cnt   <= 7'b0;
                            end 
                            default: begin end
                        endcase
                    end
                    ST_DATA_RD: begin
                        7'd0 : sda_dir <= 1'b0;
                        7'd1 : begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[7] <= sda_in;
                        end
                        7'd3 : o_scl <= 1'b0;
                        7'd5 : begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[6] <= sda_in;
                        end
                        7'd7 : o_scl <= 1'b0;
                        7'd9 : begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[5] <= sda_in;
                        end
                        7'd11: o_scl <= 1'b0;
                        7'd13: begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[4] <= sda_in;
                        end
                        7'd15: o_scl <= 1'b0;
                        7'd17: begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[3] <= sda_in;
                        end
                        7'd19: o_scl <= 1'b0;
                        7'd21: begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[2] <= sda_in;
                        end
                        7'd23: o_scl <= 1'b0;
                        7'd25: begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[1] <= sda_in;
                        end
                        7'd27: o_scl <= 1'b0;
                        7'd29: begin
                            o_scl           <= 1'b1;
                            r_i2c_data_r[0] <= sda_in;
                        end
                        7'd31: o_scl <= 1'b0;
                        7'd32: begin
                            sda_dir <= 1'b1;
                            sda_out <= 1'b1;
                        end
                        7'd33: o_scl   <= 1'b1;
                        7'd34: st_done <= 1'b1;
                        7'd35: begin
                            o_scl <= 1'b0;
                            cnt   <= 1'b0;
                            o_i2c_data_r <= r_i2c_data_r;
                        end
                    end
                    ST_STOP: begin
                        case (cnt)
                            7'd0 : sda_out <= 1'b0;
                            7'd1 : o_scl   <= 1'b1;
                            7'd3 : sda_out <= 1'b1;
                            7'd15: st_done <= 1'b1;
                            7'd16: begin
                                o_i2c_done <= 1'b1;
                                cnt        <= 7'b0;
                            end 
                            default: begin end
                        endcase
                    end
            endcase
        end
    end

endmodule