module uart_recv (
    input clk,
    input rst_n,

    input uart_rxd,

    output reg [7:0] uart_data,
    output reg       uart_done

);

    parameter CLK_FREQ = 50_000_000;
    parameter UART_BPS = 9600;
    parameter BPS_CNT = CLK_FREQ / UART_BPS;

    reg         uart_rxd_d0;
    reg         uart_rxd_d1;
    reg         rx_flag;
    reg  [31:0] clk_cnt;
    reg  [ 3:0] rx_cnt;
    reg  [ 7:0] rx_data;

    wire        start_flag;

    // 打拍
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b0;
            uart_rxd_d1 <= 1'b0;
        end else begin
            uart_rxd_d0 <= uart_rxd;
            uart_rxd_d1 <= uart_rxd_d0;
        end
    end

    //检测信号上升沿
    assign start_flag = uart_rxd_d0 && ~uart_rxd_d1;


    //接受信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 1'b0;
        end else if (start_flag) begin
            rx_flag <= 1'b1;
        end else if (rx_cnt == 4'd9 && clk_cnt == BPS_CNT - 1) begin
            rx_flag <= 1'b0;
        end
    end

    // bps计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 32'b0;
        end else if (rx_flag) begin
            if (clk_cnt == BPS_CNT - 1) begin
                clk_cnt <= 32'b0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end else begin
            clk_cnt <= 32'b0;
        end
    end

    // 数据位计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 1'b0;
        end else if (clk_cnt == BPS_CNT - 1) begin
            if (rx_cnt == 4'd9) begin
                rx_cnt <= 4'b0;
            end else begin
                rx_cnt <= rx_cnt + 1'b1;
            end
        end
    end

    // 数据接收逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_data <= 8'b0;
        end else if (clk_cnt == BPS_CNT / 2 - 1) begin
            case (rx_cnt)
                4'd1:    rx_data[0] <= uart_rxd_d1;
                4'd2:    rx_data[1] <= uart_rxd_d1;
                4'd3:    rx_data[2] <= uart_rxd_d1;
                4'd4:    rx_data[3] <= uart_rxd_d1;
                4'd5:    rx_data[4] <= uart_rxd_d1;
                4'd6:    rx_data[5] <= uart_rxd_d1;
                4'd7:    rx_data[6] <= uart_rxd_d1;
                4'd8:    rx_data[7] <= uart_rxd_d1;
                default: rx_data <= uart_data;
            endcase
        end
    end

    // 接受完成信号逻辑
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
        end
    end



endmodule

module uart_send (
    input clk,
    input rst_n,

    input           send_en,
    input reg [7:0] uart_data,

    output uart_txd,
    output tx_busy

);

    parameter CLK_FREQ = 50_000_000;
    parameter UART_BPS = 9600;
    parameter BPS_CNT = CLK_FREQ / UART_BPS;

    reg         uart_en_d0;
    reg         uart_en_d1;
    reg         tx_flag;
    reg  [31:0] clk_cnt;
    reg  [ 7:0] tx_cnt;
    reg  [ 7:0] tx_data;

    wire        uart_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_en_d0 <= 1'b0;
            uart_en_d1 <= 1'b0;
        end else begin
            uart_en_d0 <= uart_en;
            uart_en_d1 <= uart_en_d0;
        end
    end

    assign uart_en = ~uart_en_d1 && uart_en_d0;

    // 发送使能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_flag <= 1'b0;
        end else if (uart_en) begin
            tx_flag <= 1'b1;
        end else if (~tx_busy && clk_cnt == BPS_CNT) begin
            tx_flag <= 1'b0;
        end
    end

    // bps计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 32'b0;
        end else if (tx_flag) begin
            if (clk_cnt == BPS_CNT - 1) begin
                clk_cnt <= 32'b0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end

    // 数据位计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt <= 8'b0;
        end else if (clk_cnt == BPS_CNT - 1) begin
            if (tx_cnt == 4'd9) begin
                tx_cnt <= 4'b0;
            end else begin
                tx_cnt <= tx_cnt + 1'b1;
            end
        end
    end


    // 数据接收逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'b0;
        end else if (uart_en) begin
            tx_data <= uart_data;
        end
    end

    // 数据发送逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_txd <= 1'b1;
        end else if (tx_flag) begin
            case (tx_cnt)
                4'd0:    uart_txd <= 1'd0;
                4'd1:    uart_txd <= tx_data[0];
                4'd2:    uart_txd <= tx_data[1];
                4'd3:    uart_txd <= tx_data[2];
                4'd4:    uart_txd <= tx_data[3];
                4'd5:    uart_txd <= tx_data[4];
                4'd6:    uart_txd <= tx_data[5];
                4'd7:    uart_txd <= tx_data[6];
                4'd8:    uart_txd <= tx_data[7];
                4'd9:    uart_txd <= 1'd1;
                default: uart_txd <= 1'd1;
            endcase
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


module uart_loop (
    input clk,
    input rst_n,

    input       tx_busy,
    input [7:0] recv_data,
    input       recv_done,

    output reg [7:0] send_data,
    output reg       send_en

);
    reg        recv_done_d0;
    reg        recv_doned1;
    reg  [7:0] loop_data;
    reg        send_req;

    wire       recv_done_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_doned0 <= 1'b0;
            recv_doned1 <= 1'b1;
        end else begin
            recv_doned0 <= send_req;
            recv_doned1 <= recv_doned0;
        end
    end

    wire recv_done_flag = ~recv_doned1 && recv_doned0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_req <= 1'b0;
        end else if (recv_done_flag) begin
            send_req <= 1'b1;
        end else if (send_req && !tx_busy) begin
            send_req <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_data <= 8'b0;
        end else if (recv_done_flag) begin
            send_data <= recv_data;
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


endmodule
