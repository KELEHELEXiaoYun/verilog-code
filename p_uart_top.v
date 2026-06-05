module top_uart (

    input clk,
    input rst_n,

    input rx_data,

    output tx_data

);

    wire [7:0] w_rx_data;
    wire       w_rx_done;

    uart_rx u_uart_rx (

        .i_clk_50m  (clk),
        .i_rst_n_50m(rst_n),
        .i_tx_data  (rx_data),
        .o_rx_done  (w_rx_done),
        .o_rx_data  (w_rx_data)

    );

    uart_tx u_uart_tx (

        .i_clk_50m  (clk),
        .i_rst_n_50m(rst_n),
        .i_tx_en    (w_rx_done),
        .i_tx_data  (w_rx_data),
        .o_tx_busy  (),
        .o_tx_data  (tx_data)

    );
endmodule
