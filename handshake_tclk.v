module handshake_tclk #(
    parameter DILE_T        = 2'd0,
    parameter ASSERT_TRDY   = 2'd1,
    parameter DEASSERT_TRDY = 2'd2
) (

    input tclk,
    input resetb_tclk,

    input        r_ack,
    input        data_avail,
    input [31:0] transmit_data,

    output            t_rdy,
    output reg [31:0] t_data

);


    reg [1:0] t_hndshk_state, t_hndshk_state_nxt;
    reg t_rdy, t_rdy_nxt;
    reg [31:0] t_data_nxt;
    reg r_ack_d1, r_ack_tclk;


    always @(*) begin
        t_hndshk_state_nxt = t_hndshk_state;
        t_rdy_nxt          = 1'b0;
        t_data_nxt         = t_data;

        case (t_hndshk_state)
            DILE_T: begin
                if (data_avail) begin
                    t_hndshk_state_nxt = ASSERT_TRDY;
                    t_rdy_nxt          = 1'b1;
                    t_data_nxt         = transmit_data;
                end
            end
            ASSERT_TRDY: begin
                if (r_ack_tclk) begin
                    t_rdy_nxt          = 1'b0;
                    t_hndshk_state_nxt = DEASSERT_TRDY;
                    t_data_nxt         = 'd0;
                end else begin
                    t_rdy_nxt  = 1'b1;
                    t_data_nxt = t_data;
                end
            end
            DEASSERT_TRDY: begin
                if (!r_ack_tclk) begin
                    if (data_avail) begin
                        t_hndshk_state_nxt = ASSERT_TRDY;
                        t_rdy_nxt          = 1'b1;
                        t_data_nxt         = transmit_data;
                    end else begin
                        t_hndshk_state_nxt = DILE_T;
                    end
                end
            end
            default: begin
            end
        endcase
    end

    always @(posedge tclk or negedge resetb_tclk) begin
        if (!resetb_tclk) begin
            t_hndshk_state <= DILE_T;
            t_rdy          <= 1'b0;
            t_data         <= 'd0;
            r_ack_d1       <= 1'b0;
            r_ack_tclk     <= 1'b0;
        end else begin
            t_hndshk_state <= t_hndshk_state_nxt;
            t_rdy          <= t_rdy_nxt;
            t_data         <= t_data_nxt;
            r_ack_d1       <= r_ack;
            r_ack_tclk     <= r_ack_d1;
        end
    end


endmodule
