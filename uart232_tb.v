`timescale 1ns / 1ps

module uart232_tb;

reg clk;
reg reset;
reg [7:0] tx_data;
reg tx_start;
wire tx_busy;
wire tx_out;
wire rx_in;
wire [7:0] rx_data;
wire rx_ready;

// Connect TX to RX for loopback test
assign rx_in = tx_out;

uart232 #(.CLK_FREQ(25000000), .BAUD_RATE(115200)) uut(
    .clk(clk),
    .reset(reset),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx_out(tx_out),
    .rx_in(rx_in),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
);

// Clock generation (25MHz)
always #20 clk = ~clk;  // 40ns period = 25MHz

initial begin
    // Initialize
    clk = 0;
    reset = 1;
    tx_data = 0;
    tx_start = 0;

    // Reset
    #100 reset = 0;

    // Test data
    #1000;
    tx_data = 8'h41;  // 'A'
    tx_start = 1;
    #40 tx_start = 0;

    // Wait for transmission and reception
    wait(rx_ready);
    $display("Received data: %h (expected: %h)", rx_data, tx_data);

    // Test another byte
    #100000;  // Wait some time
    tx_data = 8'h42;  // 'B'
    tx_start = 1;
    #40 tx_start = 0;

    wait(rx_ready);
    $display("Received data: %h (expected: %h)", rx_data, tx_data);

    // Finish
    #100000 $finish;
end

endmodule
