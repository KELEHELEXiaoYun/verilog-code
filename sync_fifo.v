module sync_fifo #(
    parameter FIFO_PTR   = 4,
    parameter FIFO_WIDTH = 16,
    parameter FIFO_DEPTH = 32
) (
    input i_fifo_clk,
    input i_rst_n,

    input i_fifo_wren,
    input i_fifo_rden,

    input [FIFO_WIDTH - 1:0] i_fifo_wr_data,

    output reg                    o_fifo_full,
    output reg                    o_fifo_empty,
    output reg [      FIFO_PTR:0] o_fifo_room_avail,
    output     [      FIFO_PTR:0] o_fifo_data_avail,
    output     [FIFO_WIDTH - 1:0] o_fifo_rd_data


);

    localparam FIFO_DEPTH_MINUS1 = FIFO_DEPTH - 1;

    reg [FIFO_PTR - 1:0] r_wr_ptr, r_wr_ptr_nxt;
    reg [FIFO_PTR - 1:0] r_rd_ptr, r_rd_ptr_nxt;
    reg [FIFO_PTR:0] r_num_entries, r_num_entries_nxt;
    wire r_o_fifo_full_nxt, r_o_fifo_empty_nxt;
    wire [FIFO_PTR:0] w_fifo_room_avail_nxt;

    always @(*) begin
        r_wr_ptr_nxt = r_wr_ptr;
        if (i_fifo_wren) begin
            if (r_wr_ptr == FIFO_DEPTH_MINUS1) begin
                r_wr_ptr_nxt = 'd0;
            end else begin
                r_wr_ptr_nxt = r_wr_ptr + 1'b1;
            end
        end
    end


    always @(*) begin
        begin
            r_num_entries_nxt = r_num_entries;
            if (i_fifo_wren && i_fifo_rden) begin
                r_num_entries_nxt = r_num_entries;
            end else if (i_fifo_wren) begin
                r_num_entries_nxt = r_num_entries + 1'b1;
            end else if (i_fifo_rden) begin
                r_num_entries_nxt = r_num_entries - 1'b1;
            end
        end
    end

    assign r_o_fifo_full_nxt     = (r_num_entries_nxt == FIFO_DEPTH);
    assign r_o_fifo_empty_nxt    = (r_num_entries_nxt == 'd0);
    assign o_fifo_data_avail     = r_num_entries;
    assign w_fifo_room_avail_nxt = (FIFO_DEPTH - r_num_entries_nxt);

    always @(posedge i_fifo_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_wr_ptr          <= 'd0;
            r_rd_ptr          <= 'd0;
            r_num_entries     <= 'd0;
            o_fifo_full       <= 1'd0;
            o_fifo_empty      <= 1'b1;
            o_fifo_room_avail <= FIFO_DEPTH;
        end else begin
            r_wr_ptr          <= r_wr_ptr_nxt;
            r_rd_ptr          <= r_rd_ptr_nxt;
            r_num_entries     <= r_num_entries_nxt;
            o_fifo_full       <= r_o_fifo_full_nxt;
            o_fifo_empty      <= r_o_fifo_empty_nxt;
            o_fifo_room_avail <= w_fifo_room_avail_nxt;
        end
    end

    fifo_generator_0 your_instance_name (
        .wr_clk       (i_fifo_clk),      // input wire wr_clk
        .rd_clk       (i_fifo_clk),      // input wire rd_clk
        .din          (i_fifo_wr_data),  // input wire [15 : 0] din
        .wr_en        (i_fifo_wren),     // input wire wr_en
        .rd_en        (i_fifo_rden),     // input wire rd_en
        .dout         (o_fifo_rd_data),  // output wire [15 : 0] dout
        .full         (),                // output wire full
        .empty        (),                // output wire empty
        .rd_data_count(r_rd_ptr),        // output wire [8 : 0] rd_data_count
        .wr_data_count(r_wr_ptr)         // output wire [8 : 0] wr_data_count
    );
endmodule
