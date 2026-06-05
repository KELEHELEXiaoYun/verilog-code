module rd_id (
    input        clk,
    input        rst_n,
    input [23:0] lcd_rgb,

    output reg lcd_id

);

    reg rd_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_flag <= 1'b0;
            lcd_id  <= 16'b0;
        end else begin
            if (rd_flag == 1'b0) begin
                rd_flag <= 1'b1;
                case ({
                    lcd_rgb[7], lcd_rgb[15], lcd_rgb[23]
                })
                    3'b000:  lcd_id <= 16'h4342;  // 4.3' 480*272
                    3'b001:  lcd_id <= 16'h7084;  // 7' 800*480
                    3'b010:  lcd_id <= 16'h7016;  // 7' 1024*600
                    3'b100:  lcd_id <= 16'h4384;  // 4.3' 800*480
                    3'b101:  lcd_id <= 16'h1018;  // 10' 1280*800 
                    default: lcd_id <= 16'h0;  // no connect
                endcase
            end
        end
    end

endmodule


module clk_div (
    input clk,
    input rst_n,

    input [15:0] lcd_id,

    output reg lcd_pclk

);

    reg clk_25m;
    reg clk_12_5m;
    reg div_4_cnt;

    // 2分频
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_25m <= 1'b0;
        end else begin
            clk_25m <= ~clk_25m;
        end
    end

    // 4分频
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_12_5m <= 1'b0;
            div_4_cnt <= 1'b0;
        end else begin
            div_4_cnt <= div_4_cnt + 1'b1;
            if (div_4_cnt == 1'b1) begin
                clk_12_5m <= ~clk_12_5m;
            end
        end
    end

    always @(*) begin
        case (lcd_id)
            16'h4342: lcd_pclk = clk_12_5m;  // 4.3' 480*272
            16'h7084: lcd_pclk = clk_25m;  // 7' 800*480
            16'h7016: lcd_pclk = clk;  // 7' 1024*600
            16'h4384: lcd_pclk = clk_25m;  // 4.3' 800*480
            16'h1018: lcd_pclk = clk;  // 10' 1280*80
            default:  lcd_pclk = 1'b0;
        endcase
    end



endmodule



module lcd_driver (
    input lcd_pclk,
    input rst_n,

    input [15:0] lcd_id,
    input [23:0] pixel_data,

    output [10:0] pixel_xpos,
    output [10:0] pixel_ypos,

    output reg [10:0] h_disp,
    output reg [10:0] v_disp,

    // RGB LCD
    output        lcd_de,
    output        lcd_hs,
    output        lcd_vs,
    output        lcd_bl,
    output        lcd_clk,
    output [23:0] lcd_rgb

);

    // 4.3' 480*272
    parameter H_SYNC_4342 = 11'd41;
    parameter H_BACK_4342 = 11'd2;
    parameter H_DISP_4342 = 11'd480;
    parameter H_FRONT_4342 = 11'd2;
    parameter H_TOTAL_4342 = 11'd525;

    parameter V_SYNC_4342 = 11'd10;
    parameter V_BACK_4342 = 11'd2;
    parameter V_DISP_4342 = 11'd272;
    parameter V_FRONT_4342 = 11'd2;
    parameter V_TOTAL_4342 = 11'd286;

    //7' 800*480
    parameter H_SYNC_7084 = 11'd128;  //行同步
    parameter H_BACK_7084 = 11'd88;  //行显示后沿
    parameter H_DISP_7084 = 11'd800;  //行有效数据
    parameter H_FRONT_7084 = 11'd40;  //行显示前沿
    parameter H_TOTAL_7084 = 11'd1056;  //行扫描周期

    parameter V_SYNC_7084 = 11'd2;  //场同步
    parameter V_BACK_7084 = 11'd33;  //场显示后沿
    parameter V_DISP_7084 = 11'd480;  //场有效数据
    parameter V_FRONT_7084 = 11'd10;  //场显示前沿
    parameter V_TOTAL_7084 = 11'd525;  //场扫描周期

    //7' 1024*600
    parameter H_SYNC_7016 = 11'd20;  //行同步
    parameter H_BACK_7016 = 11'd140;  //行显示后沿
    parameter H_DISP_7016 = 11'd1024;  //行有效数据
    parameter H_FRONT_7016 = 11'd160;  //行显示前沿
    parameter H_TOTAL_7016 = 11'd1344;  //行扫描周期

    parameter V_SYNC_7016 = 11'd3;  //场同步
    parameter V_BACK_7016 = 11'd20;  //场显示后沿
    parameter V_DISP_7016 = 11'd600;  //场有效数据
    parameter V_FRONT_7016 = 11'd12;  //场显示前沿
    parameter V_TOTAL_7016 = 11'd635;  //场扫描周期

    //10.1' 1280*800
    parameter H_SYNC_1018 = 11'd10;  //行同步
    parameter H_BACK_1018 = 11'd80;  //行显示后沿
    parameter H_DISP_1018 = 11'd1280;  //行有效数据
    parameter H_FRONT_1018 = 11'd70;  //行显示前沿
    parameter H_TOTAL_1018 = 11'd1440;  //行扫描周期

    parameter V_SYNC_1018 = 11'd3;  //场同步
    parameter V_BACK_1018 = 11'd10;  //场显示后沿
    parameter V_DISP_1018 = 11'd800;  //场有效数据
    parameter V_FRONT_1018 = 11'd10;  //场显示前沿
    parameter V_TOTAL_1018 = 11'd823;  //场扫描周期

    // 4.3' 800*480
    parameter H_SYNC_4384 = 11'd128;  // 行同步
    parameter H_BACK_4384 = 11'd88;  // 行显示后沿
    parameter H_DISP_4384 = 11'd800;  // 行有效数据
    parameter H_FRONT_4384 = 11'd40;  // 行显示前沿
    parameter H_TOTAL_4384 = 11'd1056;  // 行扫描周期

    parameter V_SYNC_4384 = 11'd2;  // 场同步
    parameter V_BACK_4384 = 11'd33;  // 场显示后沿
    parameter V_DISP_4384 = 11'd480;  // 场有效数据
    parameter V_FRONT_4384 = 11'd10;  // 场显示前沿
    parameter V_TOTAL_4384 = 11'd525;  // 场扫描周期

    reg  [10:0] h_sync;
    reg  [10:0] h_back;
    reg  [10:0] h_total;
    reg  [10:0] v_sync;
    reg  [10:0] v_back;
    reg  [10:0] v_total;
    reg  [10:0] h_cnt;
    reg  [10:0] v_cnt;

    wire        lcd_en;
    wire        data_req;

    assign lcd_hs = 1'b1;
    assign lcd_vs = 1'b1;
    assign lcd_bl = 1'b1;
    assign lcd_clk = lcd_pclk;
    assign lcd_de = lcd_en;

    assign lcd_en = (h_cnt >= h_sync + h_back) && (h_cnt < h_sync + h_back + h_disp) &&
        (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp) ? 1'b1 : 1'b0;

    assign lcd_rgb = lcd_en ? pixel_data : 24'd0;

    assign data_req = (h_cnt >= h_sync + h_back) && (h_cnt < h_sync + h_back + h_disp) &&
        (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp) ? 1'b1 : 1'b0;

    assign pixel_xpos = data_req ? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
    assign pixel_ypos = data_req ? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;

    always @(*) begin
        case (lcd_id)
            16'h4342: begin
                h_sync  = H_SYNC_4342;
                h_back  = H_BACK_4342;
                h_total = H_TOTAL_4342;
                v_sync  = V_SYNC_4342;
                v_back  = V_BACK_4342;
                v_total = V_TOTAL_4342;
                v_disp  = V_DISP_4342;
            end
            16'h7084: begin
                h_sync  = H_SYNC_7084;
                h_back  = H_BACK_7084;
                h_total = H_TOTAL_7084;
                v_sync  = V_SYNC_7084;
                v_back  = V_BACK_7084;
                v_total = V_TOTAL_7084;
                h_disp  = H_DISP_7084;
                v_disp  = V_DISP_7084;
            end
            16'h7016: begin
                h_sync  = H_SYNC_7016;
                h_back  = H_BACK_7016;
                h_total = H_TOTAL_7016;
                v_sync  = V_SYNC_7016;
                v_back  = V_BACK_7016;
                v_total = V_TOTAL_7016;
                h_disp  = H_DISP_7016;
                v_disp  = V_DISP_7016;
            end
            16'h1018: begin
                h_sync  = H_SYNC_1018;
                h_back  = H_BACK_1018;
                h_total = H_TOTAL_1018;
                v_sync  = V_SYNC_1018;
                v_back  = V_BACK_1018;
                v_total = V_TOTAL_1018;
                h_disp  = H_DISP_1018;
                v_disp  = V_DISP_1018;
            end
            16'h4384: begin
                h_sync  = H_SYNC_4384;
                h_back  = H_BACK_4384;
                h_total = H_TOTAL_4384;
                v_sync  = V_SYNC_4384;
                v_back  = V_BACK_4384;
                v_total = V_TOTAL_4384;
                h_disp  = H_DISP_4384;
                v_disp  = V_DISP_4384;
            end
            default: begin
                h_sync  = 11'd0;
                h_back  = 11'd0;
                h_total = 11'd0;
                v_sync  = 11'd0;
                v_back  = 11'd0;
                v_total = 11'd0;
                h_disp  = 11'd0;
                v_disp  = 11'd0;
            end
        endcase
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 11'b0;
        end else begin
            if (h_cnt == h_total - 1) begin
                h_cnt <= 1'b0;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            v_cnt <= 11'b0;
        end else begin
            if (h_cnt == h_total - 1) begin
                if (v_cnt == v_total - 1) begin
                    v_cnt <= 1'b0;
                end else begin
                    v_cnt <= v_cnt + 1'b1;
                end
            end
        end
    end


endmodule




module lcd_display (
    input lcd_pclk,
    input rst_n,

    input [10:0] pixel_xpos,
    input [10:0] pixel_ypos,

    input [10:0] h_disp,
    input [10:0] v_disp,

    output reg [23:0] pixel_data

);

    parameter WHITE = 24'hffffff;
    parameter BLACK = 24'h000000;
    parameter RED = 24'hff0000;
    parameter GREEN = 24'h00ff00;
    parameter BLUE = 24'h0000ff;

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data <= BLACK;
        end else begin
            if ((pixel_xpos >= 11'd0) && (pixel_xpos < h_disp / 5 * 1)) begin
                pixel_data <= WHITE;
            end else if ((pixel_xpos >= h_disp / 5 * 1) && (pixel_xpos < h_disp / 5 * 2)) begin
                pixel_data <= BLACK;
            end else if ((pixel_xpos >= h_disp / 5 * 2) && (pixel_xpos < h_disp / 5 * 3)) begin
                pixel_data <= RED;
            end else if ((pixel_xpos >= h_disp / 5 * 3) && (pixel_xpos < h_disp / 5 * 4)) begin
                pixel_data <= GREEN;
            end else begin
                pixel_data <= BLUE;
            end
        end
    end




endmodule




module lcd_rgb_colorbar (
    input clk,
    input rst_n,

    //RGB LCD
    output        lcd_de,
    output        lcd_hs,
    output        lcd_vs,
    output        lcd_bl,
    output        lcd_clk,
    inout  [23:0] lcd_rgb
);


    wire [23:0] lcd_rgb_i;
    wire [15:0] lcd_id;
    wire        lcd_pclk;
    wire [10:0] pixel_xpos;
    wire [10:0] pixel_ypos;
    wire [10:0] h_disp;
    wire [10:0] v_disp;
    wire [23:0] pixel_data;
    wire [23:0] lcd_rgb_o;

    assign lcd_rgb_i = lcd_rgb;
    assign lcd_rgb   = lcd_de ? lcd_rgb_o : {24{1'bz}};

    rd_id u_rd_id (
        .clk    (clk),
        .rst_n  (rst_n),
        .lcd_rgb(lcd_rgb_i),
        .lcd_id (lcd_id)
    );

    clk_div u_clk_div (
        .clk     (clk),
        .rst_n   (rst_n),
        .lcd_id  (lcd_id),
        .lcd_pclk(lcd_pclk)
    );

    lcd_display u_lcd_display (
        .lcd_pclk  (lcd_pclk),
        .rst_n     (rst_n),
        .pixel_xpos(pixel_xpos),
        .pixel_ypos(pixel_ypos),
        .h_disp    (h_disp),
        .v_disp    (v_disp),
        .pixel_data(pixel_data)
    );

    lcd_driver u_lcd_driver (
        .lcd_pclk  (lcd_pclk),
        .rst_n     (rst_n),
        .lcd_id    (lcd_id),
        .pixel_data(pixel_data),
        .pixel_xpos(pixel_xpos),
        .pixel_ypos(pixel_ypos),
        .h_disp    (h_disp),
        .v_disp    (v_disp),

        .lcd_de (lcd_de),
        .lcd_hs (lcd_hs),
        .lcd_vs (lcd_vs),
        .lcd_bl (lcd_bl),
        .lcd_clk(lcd_clk),
        .lcd_rgb(lcd_rgb_o)
    );

endmodule

