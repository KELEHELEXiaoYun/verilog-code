module ip_fifo(
    input clk,
    input rst_n
    );
    
    wire almost_empty;
    wire almost_full;
    wire fifo_wr_en;
    wire [7:0] fifo_wr_data;
    wire fifo_rd_en;
    wire [7:0] fifo_rd_data;
    wire [7:0] dout;
    wire full;
    wire empty;
    wire [7:0] rd_data_count;
    wire [7:0] wr_data_count;
    wire wr_rst_busy;
    wire rd_rst_busy;
    
    fifo_wr u_fifo_wr (
    .clk(clk),
    .rst_n(rst_n),

    .almost_empty(almost_empty),
    .almost_full(almost_full),

    .fifo_wr_en(fifo_wr_en),
    . fifo_wr_data(fifo_wr_data)

    );
    
  fifo_rd u_fifo_rd (
    .clk(clk),
    .rst_n(rst_n),

    .almost_empty(almost_empty),
    .almost_full(almost_full),

    .fifo_rd_en(fifo_rd_en)

    );
    
    //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
fifo_generator_0 u_fifo_generator_0 (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(clk),                // input wire wr_clk
  .rd_clk(clk),                // input wire rd_clk
  .din(fifo_wr_data),                      // input wire [7 : 0] din
  .wr_en(fifo_wr_en),                  // input wire wr_en
  .rd_en(fifo_rd_en),                  // input wire rd_en
  .dout(dout),                    // output wire [7 : 0] dout
  .full(full),                    // output wire full
  .almost_full(almost_full),      // output wire almost_full
  .empty(empty),                  // output wire empty
  .almost_empty(almost_empty),    // output wire almost_empty
  .rd_data_count(rd_data_count),  // output wire [7 : 0] rd_data_count
  .wr_data_count(wr_data_count),  // output wire [7 : 0] wr_data_count
  .wr_rst_busy(wr_rst_busy),      // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy)      // output wire rd_rst_busy
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

ila_0 u_ila_0 (
	.clk(clk), // input wire clk


	.probe0(fifo_wr_en), // input wire [0:0]  probe0  
	.probe1(fifo_rd_en), // input wire [0:0]  probe1 
	.probe2(full), // input wire [0:0]  probe2 
	.probe3(almost_full), // input wire [0:0]  probe3 
	.probe4(fifo_wr_data), // input wire [7:0]  probe4 
	.probe5(wr_data_count), // input wire [7:0]  probe5 
	.probe6(rd_data_count), // input wire [7:0]  probe6 
	.probe7(dout), // input wire [7:0]  probe7 
	.probe8(empty), // input wire [0:0]  probe8 
	.probe9(almost_empty) // input wire [0:0]  probe9
);

endmodule



module fifo_wr(
    input clk,
    input rst_n,

    input almost_empty,
    input almost_full,

    output reg fifo_wr_en,
    output reg [7:0] fifo_wr_data

    );

    reg almost_empty_d0;
    reg almost_empty_syn;
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [3:0] dly_cnt;

    wire syn;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            almost_empty_d0 <= 0;
            almost_empty_syn <= 0;
        end else begin
            almost_empty_d0 <= almost_empty;
            almost_empty_syn <= almost_empty_d0;
        end
    end

    assign syn = (~almost_empty_syn) && (almost_empty_d0 );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           fifo_wr_en <= 0;
           fifo_wr_data <= 0;
           current_state <= 0;
           dly_cnt <= 0;
        end else begin
           case (current_state) 
                2'b0 : current_state <= syn ? 2'd1 : current_state;
                2'b1 : begin
                    if (dly_cnt == 4'd10) begin
                        dly_cnt <= 0;
                        current_state <= 2'd2;
                        fifo_wr_en <= 1;
                    end else begin
                        dly_cnt <= dly_cnt + 1'b1;
                    end
                end
                2'd2 : if (almost_full)begin
                    fifo_wr_en <= 0;
                    fifo_wr_data <= 0;
                    current_state <= 0;
                end else begin
                    fifo_wr_en <= 1;
                    fifo_wr_data <= fifo_wr_data + 1'd1;
                end
                default : current_state <= 2'b0;
           endcase
        end
        
    end



    
endmodule



module fifo_rd(
    input clk,
    input rst_n,

    input almost_empty,
    input almost_full,

    output reg fifo_rd_en

    );

    reg almost_full_d0;
    reg almost_full_syn;
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [3:0] dly_cnt;

    wire syn;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            almost_full_d0 <= 0;
            almost_full_syn <= 0;
        end else begin
            almost_full_d0 <= almost_full;
            almost_full_syn <= almost_full_d0;
        end
    end

    assign syn = almost_full_d0 & ~almost_full_syn;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           fifo_rd_en <= 0;
           current_state <= 0;
           dly_cnt <= 0;
        end else begin
           case (current_state) 
                2'b0 : current_state <= syn ? 2'b1 : current_state;
                2'b1 : begin
                    if (dly_cnt == 4'd10) begin
                        dly_cnt <= 0;
                        current_state <= 2'd2;
                    end else begin
                        dly_cnt <= dly_cnt + 1'b1;
                    end
                end
                2'd2 : if (almost_empty) begin
                    fifo_rd_en <= 0;
                    current_state <= 0;
                end else begin
                    fifo_rd_en <= 1;
                end
                default : current_state <= 2'b0;
           endcase
        end
    end



    
endmodule
