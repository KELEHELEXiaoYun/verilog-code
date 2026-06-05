// UART232 Module
// Supports 8-bit data, 1 start bit, 1 stop bit, no parity
// Baud rate configurable

module uart232 (
    input        clk,
    input        reset,
    // TX interface
    input  [7:0] tx_data,
    input        tx_start,
    output       tx_busy,
    output       tx_out,
    // RX interface
    input        rx_in,
    output [7:0] rx_data,
    output       rx_ready
);

    // Parameters
    parameter CLK_FREQ = 25000000;  // 25MHz clock
    parameter BAUD_RATE = 115200;

    // Baud tick generator
    wire baud_tick;
    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen_inst (
        .clk  (clk),
        .reset(reset),
        .tick (baud_tick)
    );

    // UART Transmitter
    uart_tx uart_tx_inst (
        .clk      (clk),
        .reset    (reset),
        .baud_tick(baud_tick),
        .data     (tx_data),
        .start    (tx_start),
        .busy     (tx_busy),
        .tx       (tx_out)
    );

    // UART Receiver
    uart_rx uart_rx_inst (
        .clk      (clk),
        .reset    (reset),
        .baud_tick(baud_tick),
        .rx       (rx_in),
        .data     (rx_data),
        .ready    (rx_ready)
    );

endmodule

// Baud rate generator
module baud_gen (
    input  clk,
    input  reset,
    output tick
);

    parameter CLK_FREQ = 25000000;
    parameter BAUD_RATE = 115200;

    localparam DIVIDER = CLK_FREQ / BAUD_RATE;
    reg [15:0] counter = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick    <= 0;
        end else begin
            if (counter == DIVIDER - 1) begin
                counter <= 0;
                tick    <= 1;
            end else begin
                counter <= counter + 1;
                tick    <= 0;
            end
        end
    end

endmodule

// UART Transmitter
module uart_tx (
    input            clk,
    input            reset,
    input            baud_tick,
    input      [7:0] data,
    input            start,
    output reg       busy,
    output reg       tx
);

    reg [3:0] state = 0;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= 0;
            busy      <= 0;
            tx        <= 1;  // Idle high
            shift_reg <= 0;
            bit_cnt   <= 0;
        end else begin
            case (state)
                0: begin  // Idle
                    tx <= 1;
                    if (start && !busy) begin
                        shift_reg <= data;
                        busy      <= 1;
                        state     <= 1;
                        bit_cnt   <= 0;
                    end
                end
                1: begin  // Start bit
                    if (baud_tick) begin
                        tx    <= 0;
                        state <= 2;
                    end
                end
                2: begin  // Data bits
                    if (baud_tick) begin
                        tx        <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_cnt   <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            state <= 3;
                        end
                    end
                end
                3: begin  // Stop bit
                    if (baud_tick) begin
                        tx    <= 1;
                        busy  <= 0;
                        state <= 0;
                    end
                end
            endcase
        end
    end

endmodule

// UART Receiver
module uart_rx (
    input            clk,
    input            reset,
    input            baud_tick,
    input            rx,
    output reg [7:0] data,
    output reg       ready
);

    reg [3:0] state = 0;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg rx_sync1, rx_sync2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= 0;
            ready     <= 0;
            data      <= 0;
            shift_reg <= 0;
            bit_cnt   <= 0;
            rx_sync1  <= 1;
            rx_sync2  <= 1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;

            case (state)
                0: begin  // Idle
                    ready <= 0;
                    if (rx_sync2 == 0) begin  // Start bit detected
                        state   <= 1;
                        bit_cnt <= 0;
                    end
                end
                1: begin  // Wait for middle of start bit
                    if (baud_tick) begin
                        state <= 2;
                    end
                end
                2: begin  // Receive data bits
                    if (baud_tick) begin
                        shift_reg <= {rx_sync2, shift_reg[7:1]};
                        bit_cnt   <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            state <= 3;
                        end
                    end
                end
                3: begin  // Stop bit
                    if (baud_tick) begin
                        if (rx_sync2 == 1) begin  // Valid stop bit
                            data  <= shift_reg;
                            ready <= 1;
                        end
                        state <= 0;
                    end
                end
            endcase
        end
    end

endmodule
