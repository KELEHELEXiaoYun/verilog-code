module uart_test#(
    parameter         CLK_FRE = 50_000_000	
)(
    input             i_clk,       
    input             i_rst_n,  

	input             i_rs485_rx,      
	
    output            o_rs485_tx,      
	output	reg		  o_rs485_de 
);

    localparam  IDLE 	    =  0;
    localparam  CV_HEAD 	=  1;
    localparam  RCV_COUNT 	=  2;
    localparam  RCV_DATA 	=  3;  
    localparam  WAIT		=  4;  
    localparam  SEND_WAIT   =  5;  
    localparam  SEND		=  6;

    reg  [2:0]  sta;
 
    reg         i_rx_data;
    reg         i_rx_data_ready;
    wire [7:0]  o_rx_data;
    wire        o_rx_data_valid;
    reg  [7:0]  rx_cnt;
 
    reg  [7:0]  i_tx_data;
    reg         i_tx_data_valid;
    wire        o_tx_data;
    wire        o_tx_data_ready;
    reg  [7:0]  tx_cnt;
 
    reg  [7:0]  data_count;
    reg  [31:0] wait_cnt;

    reg         fifo_wren;
    reg         fifo_rden;
    reg  [7:0]  fifo_wdata;
    wire [7:0]  fifo_rdata;


    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_rs485_de      <= 'd0;
            i_rx_data       <= 'd0;
            i_rx_data_ready <= 'd0;
            i_tx_data       <= 'd0;
            i_tx_data_valid <= 'd0;
            data_count      <= 'd0;
        end else begin
            case (sta)
                IDLE:begin
                    sta             <= CV_HEAD;
                    o_rs485_de      <= 'd0;
                    i_rx_data_ready <= 'd1;
                end 
                CV_HEAD: begin
                    if (o_rx_data_valid && o_rx_data == 'h55) begin
                        sta <= RCV_COUNT;
                    end
                end
                RCV_COUNT:begin
                    if (o_rx_data_valid) begin
                        if (o_rx_data > 0) begin
                            sta        <= RCV_DATA;
                        end else begin
                            sta        <= IDLE;
                        end 
                        data_count <= o_rx_data;
                    end else begin
                        sta <= IDLE;
                    end
                end
                RCV_DATA: begin
                    fifo_wren  <= o_rx_data_valid;
                    fifo_wdata <= o_rx_data;
                    if (o_rx_data_valid) begin
                        if (rx_cnt == data_count - 1) begin
                            rx_cnt   <= 'd0;
                            o_rs485_de <= 'd1;
                            sta      <= WAIT;
                        end else begin
                            rx_cnt   <= rx_cnt + 'd1;
                        end
                    end
                end
                WAIT: begin
                    fifo_wren <= 'd0;
                    if (wait_cnt == 50_000) begin
                        wait_cnt <= 'd0;
                        sta      <= SEND_WAIT;
                    end else begin
                        wait_cnt <= wait_cnt + 'd1;
                    end
                end
                SEND_WAIT: begin
                    if (o_tx_data_ready) begin
                        if (tx_cnt == data_count) begin
                            tx_cnt    <= 'd0;
                            fifo_rden <= 'd0;
                            sta       <= IDLE;
                        end
                    end else begin
                        fifo_rden   <= 'd1;
                        sta         <= SEND;
                    end
                    i_tx_data_valid <= 'd0;
                end
                SEND: begin
                    fifo_rden       <= 1'b0;
                    i_tx_data_valid <= 'd1;
                    if (i_tx_data_valid && o_tx_data_ready && tx_cnt < data_count) begin
                        tx_cnt <= tx_cnt + 'd1;
                        sta    <= SEND_WAIT;
                    end
                end
                default: sta <= IDLE; 
            endcase
        end
    end

    rx_fifo fifo_inst
    (
       .clk 						(sys_clk					),
       .srst 						(~rst_n						),  // FIFO 高电平复位
       .din 						(fifo_wdata					),  // 写数据
       .wr_en 						(fifo_wren					),  // 写使能
       .rd_en 						(fifo_rden					),  // 读使能
       .dout 						(fifo_rdata					),  // 读数据
       .full 						(							),
       .empty 						(							)
     );
endmodule