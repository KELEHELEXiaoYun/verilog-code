module uart_recv (
    input clk,
    input rst_n,

    input uart_rxd,

    output reg [7:0] uart_data,
    output reg uart_done

    );
    
    parameter CLK_FREQ = 50_000_000;
    parameter UART_BPS = 115200;
    parameter BPS_CNT = CLK_FREQ / UART_BPS;

    reg uart_rxd_d0;
    reg uart_rxd_d1;
    reg rx_flag;
    reg [3:0] rx_cnt;
    reg [15:0] clk_cnt;
    reg [7:0] rx_data;
    
    wire start_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b1;
            uart_rxd_d1 <= 1'b1;
        end else begin
            uart_rxd_d0 <= uart_rxd;
            uart_rxd_d1 <= uart_rxd_d0;
        end
    end

    assign start_flag = ~uart_rxd_d0 && uart_rxd_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 1'b0;
        end else if (start_flag) begin
            rx_flag <= 1'b1;
        end else if (rx_cnt == 4'd9 && clk_cnt == BPS_CNT - 1) begin
            rx_flag <= 1'b0;
        end else begin
            rx_flag <= rx_flag;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 16'b0;
        end else if (rx_flag) begin
           if (clk_cnt == BPS_CNT - 1) begin
            clk_cnt <= 16'b0;
           end else begin
            clk_cnt <= clk_cnt + 1'b1;
           end
        end else begin
            clk_cnt <= 16'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 4'b0;
        end else if (rx_flag) begin
            if (clk_cnt == BPS_CNT - 1) begin
                rx_cnt <= rx_cnt + 1'b1;
            end else begin
                rx_cnt <= rx_cnt;
            end
        end else begin
            rx_cnt <= 4'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 8'b0;
        end else if (rx_flag && clk_cnt == BPS_CNT / 2 - 1) begin
           case (rx_cnt) 
                4'd1: rx_data[0] <= uart_rxd_d1; 
                4'd2: rx_data[1] <= uart_rxd_d1; 
                4'd3: rx_data[2] <= uart_rxd_d1;
                4'd4: rx_data[3] <= uart_rxd_d1;
                4'd5: rx_data[4] <= uart_rxd_d1;
                4'd6: rx_data[5] <= uart_rxd_d1;
                4'd7: rx_data[6] <= uart_rxd_d1;
                4'd8: rx_data[7] <= uart_rxd_d1; 
                default: rx_data <= rx_data; 
           endcase 
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_done <= 1'b0;
        end else if (rx_cnt == 4'd9 && clk_cnt == BPS_CNT / 2 - 1) begin
            uart_done <= 1'b1;
        end else begin
            uart_done <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_data <= 8'b0;
        end else if (uart_done) begin
            uart_data <= rx_data;
        end else begin
            uart_data <= 8'b0;   
        end
    end

endmodule



module uart_send (
    input clk,
    input rst_n,

    input uart_en,

    input [7:0] uart_din,

    output reg uart_txd,
    output reg tx_busy

    );

    parameter CLK_FREQ = 50_000_000;
    parameter UART_BPS = 115200;
    parameter BPS_CNT  = CLK_FREQ / UART_BPS;


    reg uart_en_d0;
    reg uart_en_d1;
    reg tx_flag;
    reg [3:0] tx_cnt;
    reg [15:0] clk_cnt_tx;
    reg [7:0] tx_data;

    wire en_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_en_d0 <= 1'b0;
            uart_en_d1 <= 1'b0;
        end else begin
            uart_en_d0 <= uart_en;
            uart_en_d1 <= uart_en_d0;
        end
    end

    assign en_flag = ~uart_en_d1 && uart_en_d0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'b0;
        end else if (en_flag) begin
           tx_data <= uart_din;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_flag <= 1'b0;
        end else if (en_flag) begin
            tx_flag <= 1'b1;
        end else if (tx_cnt == 4'd9 & clk_cnt_tx == BPS_CNT - 1)begin
            tx_flag <= 1'b0;
        end else begin
            tx_flag <= tx_flag;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt_tx <= 16'b0;
        end else if (tx_flag) begin
            if (clk_cnt_tx == BPS_CNT - 1) begin
                clk_cnt_tx <= 0;
            end else begin
                clk_cnt_tx <= clk_cnt_tx + 1'b1;
            end
        end else begin
            clk_cnt_tx <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt <= 4'b0;
        end else if (tx_flag) begin
           if (clk_cnt_tx == BPS_CNT - 1) begin
                tx_cnt <= tx_cnt + 1'b1;
           end else begin
                tx_cnt <= tx_cnt;
           end
        end else begin
            tx_cnt <= 4'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_txd <= 1'b1;
        end else if (tx_flag) begin
            case (tx_cnt)
                4'd0: uart_txd <= 1'b0;         
                4'd1: uart_txd <= tx_data[0];
                4'd2: uart_txd <= tx_data[1];
                4'd3: uart_txd <= tx_data[2];
                4'd4: uart_txd <= tx_data[3];
                4'd5: uart_txd <= tx_data[4];
                4'd6: uart_txd <= tx_data[5];
                4'd7: uart_txd <= tx_data[6];
                4'd8: uart_txd <= tx_data[7]; 
                4'd9: uart_txd <= 1'b1;      
                default : uart_txd <= 1'b1;
            endcase
        end else begin
            uart_txd <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy <= 1'b0;
        end else begin
            tx_busy <= tx_flag;
        end
    end

endmodule



// module uart_loop (
//     input clk,
//     input rst_n,

//     input recv_done,
//     input [7:0] recv_data,
//     input tx_busy,

//     output reg send_en,
//     output reg send_data

// );
    
//     reg recv_done_d0;
//     reg recv_done_d1;
//     reg send_req;

//     wire recv_done_flag;

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             recv_done_d0 <= 1'b0;
//             recv_done_d1 <= 1'b0;
//         end else begin
//             recv_done_d0 <= recv_done;
//             recv_done_d1 <= recv_done_d0;
//         end
//     end

//     assign recv_done_flag = ~recv_done_d1 && recv_done_d0;

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             send_req <= 1'b0;
//         end else if (recv_done_flag) begin
//             send_req <= 1'b1;
//         end else if (send_req && !tx_busy) begin
//             send_req <= 1'b0;
//         end
//     end

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             send_en <= 1'b0;
//         end else if (send_req && !tx_busy) begin
//             send_en <= 1'b1;
//         end else begin
//             send_en <= 1'b0;
//         end
//     end

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             send_data <= 1'b0;
//         end else if (recv_done_flag) begin
//             send_data <= recv_data;
//         end else begin
//             send_data <= send_data;
//         end
//     end

// endmodule // 当recv module 释放后到下一次接收之前 uart_data一直保持数据位时



module uart_loop (
    input clk,
    input rst_n,

    input recv_done,          
    input [7:0] recv_data,    
    input tx_busy,

    output reg send_en,
    output reg [7:0] send_data
);
    
    reg send_req; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_req  <= 1'b0;
        end else if (recv_done) begin
            send_req  <= 1'b1;
        end else if (send_req && !tx_busy) begin
            send_req <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           send_data <= 8'b0;
        end else if (recv_done) begin
           send_data <= recv_data;
        end else begin
            send_data <=send_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_en <= 1'b0;
        end else if (send_req && !tx_busy) begin
            send_en <= 1'b1; 
        end else begin
            send_en <= 1'b0; 
        end
    end

endmodule // recv module 只在uart_done拉高瞬间发送数据



module top_uart (
    input clk,
    input rst_n,

    input uart_rxd,

    output uart_txd

    );
    
    wire [7:0] uart_data;
    wire uart_done;
    wire send_en;
    wire tx_busy;
    wire [7:0] send_data;

    uart_recv u_uart_recv(
        .clk (clk),
        .rst_n (rst_n),
        .uart_rxd (uart_rxd),        
        .uart_data (uart_data),     
        .uart_done (uart_done)       
    );

    uart_loop u_uart_loop (
        .clk (clk),
        .rst_n (rst_n),
        .recv_done (uart_done),      
        .recv_data (uart_data),      
        .tx_busy (tx_busy),          
        .send_en (send_en),          
        .send_data (send_data)       
    );

    uart_send u_uart_send (
        .clk (clk),
        .rst_n (rst_n),
        .uart_en (send_en),          
        .uart_din (send_data),       
        .uart_txd (uart_txd),        
        .tx_busy (tx_busy)           
    );
    


endmodule