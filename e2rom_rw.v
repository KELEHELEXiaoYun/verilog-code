module e2rom_rw #(
    parameter      WR_WAIT_TIME = 14'd5000,
    parameter      MAX_BYTE     = 16'd256
) (
    
    input                     i_dri_clk,
    input                     i_rst_n,

    input        [ 7:0]       i_i2c_data_r,
    input                     i_i2c_done,
    input                     i_i2c_ack,

    output                    o_i2c_exec,
    output                    o_bit_ctrl,
    output                    o_i2c_rh_wl

    output  reg  [15:0]       o_i2c_addr,
    output  reg  [ 7:0]       o_i2c_data_w,

    output  reg               o_rw_done,
    output  reg               o_rw_result

);
    
    reg   [1:0]    flow_cnt;
    reg   [13:0]   wait_cnt;

    always @(posedge i_dri_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            flow_cnt     <=  2'b0;
            wait_cnt     <= 14'd0;
            o_i2c_exec   <=  1'b0;
            o_bit_ctrl   <=  1'b1;
            o_i2c_rh_wl  <=  1'b0;
            o_i2c_addr   <= 14'd0;
            o_i2c_data_w <=  8'd0;
            o_rw_done    <=  1'b0;
            rw_result    <=  1'b0;
 
        end else begin
            o_rw_done  <=  1'b0;
            o_i2c_exec <=  1'b0;
            case (flow_cnt)
                2'd0: begin
                    wait_cnt <= wait_cnt + 1'b1;
                    if (wait_cnt == WR_WAIT_TIME - 1) begin
                        wait_cnt <= 14'd0;
                        if (o_i2c_addr == MAX_BYTE) begin
                            o_i2c_addr  <= 16'd0;
                            flow_cnt    <= 2'd2;
                            o_i2c_rh_wl <= 1'b1;
                        end else begin
                            flow_cnt <= flow_cnt + 2'd1;
                            o_i2c_exec <= 1'b1;
                        end
                    end
                end
                2'd1: begin
                    if (i_i2c_done) begin
                        flow_cnt     <= 2'd0;
                        o_i2c_addr   <= o_i2c_addr   + 16'd1;
                        o_i2c_data_w <= o_i2c_data_w +  8'd1;
                    end
                end
                2'd2: begin
                    flow_cnt   <= flow_cnt + 2'd1;
                    o_i2c_exec <= 1'b1;
                end
                2'd3: begin
                    if(i_i2c_done == 1'b1) begin                 
                        if((o_i2c_addr[7:0] != i_i2c_data_r) || (i_i2c_ack == 1'b1)) begin
                            o_rw_done <= 1'b1;
                            o_rw_result <= 1'b0;
                        end else if(o_i2c_addr == (MAX_BYTE - 16'b1))begin 
                            o_rw_done   <= 1'b1;
                            o_rw_result <= 1'b1;
                        end else begin
                            flow_cnt <= 2'd2;
                            o_i2c_addr <= o_i2c_addr + 16'b1;
                        end
                    end                 
                end
                default: begin end
            endcase
        end
    end

endmodule