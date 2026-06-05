module fifo_wr (
    input clk,
    input rst_n,

    input almost_empty,
    input almost_full,

    output reg       fifo_wr_en,
    output reg [7:0] fifo_wr_data

);

    parameter IDLE = 2'b00;
    parameter WRIT = 2'b01;
    parameter FULL = 2'b10;

    reg        almost_full_d0;
    reg        almost_full_syn;
    reg  [1:0] current_state;
    reg  [1:0] next_state;
    reg  [3:0] dly_cnt;

    wire       syn;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            almost_full_d0  <= 0;
            almost_full_syn <= 0;
        end else begin
            almost_full_d0  <= almost_full;
            almost_full_syn <= almost_full_d0;
        end
    end

    assign syn = ~almost_full_syn && almost_full_d0;

    always @(*) begin
        case (current_state)
            IDLE:    next_state = syn ? WRIT : IDLE;
            WRIT:    next_state = dly_cnt == 4'd9 ? FULL : WRIT;
            FULL:    next_state = almost_full ? IDLE : FULL;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dly_cnt <= 0;
        end else if (current_state == WRIT) begin
            if (dly_cnt == 4'd9) begin
                dly_cnt <= 0;
            end else begin
                dly_cnt <= dly_cnt + 1'b1;
            end
        end else begin
            dly_cnt <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_en <= 0;
        end else if (current_state != IDLE && ~almost_full) begin
            fifo_wr_en <= 1'b1;
        end else begin
            fifo_wr_en <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_data <= 8'd0;
        end else if (current_state == FULL && ~almost_full) begin
            fifo_wr_data <= fifo_wr_data + 1'b1;
        end else begin
            fifo_wr_data <= 8'd0;
        end
    end

endmodule


module fifo_rd (
    input clk,
    input rst_n,

    input almost_empty,
    input almost_full,

    output reg fifo_rd_en

);

    parameter IDLE = 2'b00;
    parameter READ = 2'b01;
    parameter EMPTY = 2'b10;

    reg        almost_full_d0;
    reg        almost_full_syn;
    reg  [1:0] current_state;
    reg  [1:0] next_state;
    reg  [3:0] dly_cnt;

    wire       syn;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            almost_full_d0  <= 0;
            almost_full_syn <= 0;
        end else begin
            almost_full_d0  <= almost_full;
            almost_full_syn <= almost_full_d0;
        end
    end

    assign syn = ~almost_full_syn && almost_full_d0;

    always @(*) begin
        case (current_state)
            IDLE:    next_state = syn ? READ : IDLE;
            READ:    next_state = dly_cnt == 4'd9 ? EMPTY : READ;
            EMPTY:   next_state = almost_full ? IDLE : EMPTY;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dly_cnt <= 0;
        end else if (current_state == READ) begin
            if (dly_cnt == 4'd9) begin
                dly_cnt <= 0;
            end else begin
                dly_cnt <= dly_cnt + 1'b1;
            end
        end else begin
            dly_cnt <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_rd_en <= 0;
        end else if (current_state == EMPTY && ~almost_empty) begin
            fifo_rd_en <= 1'b1;
        end else begin
            fifo_rd_en <= 0;
        end
    end

endmodule
