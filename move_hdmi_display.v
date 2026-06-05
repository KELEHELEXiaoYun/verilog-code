module video_display (

    input pixel_clk,
    input sys_rst_n,

    input [10:0] pixel_xpos,
    input [10:0] pixel_ypos,

    output reg [23:0] pixel_data

);

    parameter H_DISP = 11'd1280;
    parameter V_DISP = 11'd720;
    parameter DIV_CNT = 22'd750000;

    localparam SIDE_W = 11'd40;
    localparam BLOCK_W = 11'd40;
    localparam BLUE = 24'h0000ff;
    localparam WHITE = 24'hffffff;
    localparam BLACK = 24'h000000;


    reg  [10:0] block_x = SIDE_W;
    reg  [10:0] block_y = SIDE_W;
    reg  [21:0] div_cnt;
    reg         h_direct;
    reg         v_direct;


    wire        move_en;


    assign move_en = div_cnt == DIV_CNT - 1 ? 1'b1 : 1'b0;


    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_cnt <= 22'b0;
        end else begin
            if (div_cnt == DIV_CNT - 1) begin
                div_cnt <= 22'b0;
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_direct <= 1'b1;
        end else begin
            if (block_x == SIDE_W + 1) begin
                h_direct <= 1'b1;
            end else if (block_x == H_DISP - SIDE_W - BLOCK_W + 1) begin
                h_direct <= 1'b0;
            end else begin
                h_direct <= h_direct;
            end
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            v_direct <= 1'b1;
        end else begin
            if (block_y == SIDE_W + 1) begin
                v_direct <= 1'b1;
            end else if (block_y == V_DISP - SIDE_W - BLOCK_W + 1) begin
                v_direct <= 1'b0;
            end else begin
                v_direct <= v_direct;
            end
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            block_x <= SIDE_W + 1'b1;
        end else if (move_en) begin
            if (h_direct) begin
                block_x <= block_x + 1'b1;
            end else begin
                block_x <= block_x - 1'b1;
            end
        end else begin
            block_x <= block_x;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            block_y <= SIDE_W + 1'b1;
        end else if (move_en) begin
            if (v_direct) begin
                block_y <= block_y + 1'b1;
            end else begin
                block_y <= block_y - 1'b1;
            end
        end else begin
            block_y <= block_y;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pixel_data <= BLACK;
        end else begin
            if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W) ||
                (pixel_ypos <= SIDE_W) || (pixel_ypos > V_DISP - SIDE_W)) begin
                pixel_data <= BLUE;
            end else if ((pixel_xpos >= block_x - 1) && (pixel_xpos < block_x + BLOCK_W - 1) &&
                         (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W)) begin
                pixel_data <= WHITE;
            end else begin
                pixel_data <= BLACK;
            end
        end
    end


endmodule
