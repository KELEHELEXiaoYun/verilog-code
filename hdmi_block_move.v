module video_display (
    
    input pixel_clk,
    input sys_rst_n,

    input [10:0] pixel_xpos,
    input [10:0] pixel_ypos,

    output reg [23:0] pixel_data

);
    
    parameter H_DISP  = 11'd1280;
    parameter V_DISP  = 11'd720;
    parameter DIV_CNT = 22'd750000;

    localparam SIDE_W  = 11'd40;
    localparam BLOCK_W = 11'd40;
    localparam BLUE    = 24'h0000ff;
    localparam WHITE   = 24'hffffff;
    localparam BLACK   = 24'h000000;


    reg [10:0] block_x = SIDE_W;
    reg [10:0] block_y = SIDE_W;
    reg [21:0] div_cnt;
    reg h_direct;
    reg v_direct;


    wire move_en;


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
            if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W) || (pixel_ypos <= SIDE_W) || (pixel_ypos > V_DISP - SIDE_W)) begin
                pixel_data <= BLUE;
            end else if ((pixel_xpos >= block_x - 1) && (pixel_xpos < block_x + BLOCK_W - 1) && (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W)) begin
                pixel_data <= WHITE;
            end else begin
                pixel_data <= BLACK;
            end
        end
    end

    
endmodule



// video_display_block_move.v
module video_display_block_move (
    input pixel_clk,
    input sys_rst_n,
    input [10:0] pixel_xpos,
    input [10:0] pixel_ypos,
    output reg [23:0] pixel_data
);
    
    // 1280x720 分辨率参数
    parameter H_DISP  = 11'd1280;
    parameter V_DISP  = 11'd720;
    parameter DIV_CNT = 22'd750000;  // 移动速度控制，约0.25秒移动一次
    
    // 屏幕布局参数
    localparam SIDE_W  = 11'd40;     // 蓝色边框宽度
    localparam BLOCK_W = 11'd40;     // 移动方块宽度
    
    // 颜色定义 (RGB888格式)
    localparam BLUE    = 24'h0000ff;  // 蓝色
    localparam WHITE   = 24'hffffff;  // 白色
    localparam BLACK   = 24'h000000;  // 黑色
    
    // 方块位置寄存器
    reg [10:0] block_x;
    reg [10:0] block_y;
    
    // 移动方向寄存器
    reg h_direct;  // 水平方向：1=向右，0=向左
    reg v_direct;  // 垂直方向：1=向下，0=向上
    
    // 分频计数器，用于控制移动速度
    reg [21:0] div_cnt;
    
    // 移动使能信号
    wire move_en;
    
    // 计算移动范围边界
    wire [10:0] left_bound   = SIDE_W;
    wire [10:0] right_bound  = H_DISP - SIDE_W - BLOCK_W;
    wire [10:0] top_bound    = SIDE_W;
    wire [10:0] bottom_bound = V_DISP - SIDE_W - BLOCK_W;
    
    // 移动使能信号生成
    assign move_en = (div_cnt == DIV_CNT - 1);
    
    // 分频计数器
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_cnt <= 22'd0;
        end else begin
            if (move_en) begin
                div_cnt <= 22'd0;
            end else begin
                div_cnt <= div_cnt + 22'd1;
            end
        end
    end
    
    // 水平方向控制逻辑
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_direct <= 1'b1;  // 初始向右移动
        end else if (move_en) begin
            // 碰到左边界，改变方向向右
            if (block_x == left_bound) begin
                h_direct <= 1'b1;
            end 
            // 碰到右边界，改变方向向左
            else if (block_x == right_bound) begin
                h_direct <= 1'b0;
            end
        end
    end
    
    // 垂直方向控制逻辑
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            v_direct <= 1'b1;  // 初始向下移动
        end else if (move_en) begin
            // 碰到上边界，改变方向向下
            if (block_y == top_bound) begin
                v_direct <= 1'b1;
            end 
            // 碰到下边界，改变方向向上
            else if (block_y == bottom_bound) begin
                v_direct <= 1'b0;
            end
        end
    end
    
    // 方块水平位置更新
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            block_x <= left_bound;
        end else if (move_en) begin
            if (h_direct) begin
                // 向右移动，但不能超过右边界
                if (block_x < right_bound) begin
                    block_x <= block_x + 1'b1;
                end
            end else begin
                // 向左移动，但不能超过左边界
                if (block_x > left_bound) begin
                    block_x <= block_x - 1'b1;
                end
            end
        end
    end
    
    // 方块垂直位置更新
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            block_y <= top_bound;
        end else if (move_en) begin
            if (v_direct) begin
                // 向下移动，但不能超过下边界
                if (block_y < bottom_bound) begin
                    block_y <= block_y + 1'b1;
                end
            end else begin
                // 向上移动，但不能超过上边界
                if (block_y > top_bound) begin
                    block_y <= block_y - 1'b1;
                end
            end
        end
    end
    
    // 像素数据生成逻辑
    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pixel_data <= BLACK;
        end else begin
            // 条件1：蓝色边框
            if ((pixel_xpos < SIDE_W) ||                    // 左边框
                (pixel_xpos >= H_DISP - SIDE_W) ||          // 右边框
                (pixel_ypos < SIDE_W) ||                    // 上边框
                (pixel_ypos >= V_DISP - SIDE_W)) begin      // 下边框
                pixel_data <= BLUE;
            end 
            // 条件2：白色移动方块
            else if ((pixel_xpos >= block_x) && 
                     (pixel_xpos < block_x + BLOCK_W) &&
                     (pixel_ypos >= block_y) &&
                     (pixel_ypos < block_y + BLOCK_W)) begin
                pixel_data <= WHITE;
            end 
            // 条件3：黑色背景
            else begin
                pixel_data <= BLACK;
            end
        end
    end
    
    // 调试信号（可选）
    // wire [10:0] debug_block_x = block_x;
    // wire [10:0] debug_block_y = block_y;
    // wire debug_h_dir = h_direct;
    // wire debug_v_dir = v_direct;
    // wire debug_move_en = move_en;
    
endmodule



module tb_top_hdmi_block_move ();
    
    reg sys_clk;
    reg sys_rst_n;

    wire tmds_clk_n;
    wire tmds_clk_p;
    wire [2:0] tmds_data_n;
    wire [2:0] tmds_data_p;

    initial begin
        sys_clk <= 1'b1;
        sys_rst_n = 1'b0;
        #201
        sys_rst_n = 1'b1;
    end

    
    always #10 sys_clk <= ~sys_clk;


    defparam tb_top_hdmi_block_move_inst.u_video_display.DIV_CNT = 75;

    tb_top_hdmi_block_move tb_top_hdmi_block_move_inst (

        .sys_clk (sys_clk),
        .sys_rst_n (sys_rst_n),

        .tmds_clk_n (tmds_clk_n),
        .tmds_clk_p (tmds_clk_p),
        .tmds_data_p (tmds_data_p),
        .tmds_data_n (tmds_data_n)

    );


endmodule



// hdmi_block_move_top.v
module hdmi_block_move_top (
    input sys_clk,
    input sys_rst_n,
    
    output tmds_clk_p,
    output tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n
);
    
    // 时钟信号
    wire pixel_clk;
    wire pix_clk_5x;
    wire clk_locked;
    
    // 视频时序信号
    wire [10:0] pixel_xpos_w;
    wire [10:0] pixel_ypos_w;
    wire [23:0] pixel_data_w;
    
    // 视频输出信号
    wire video_hs;
    wire video_vs;
    wire video_de;
    wire [23:0] video_rgb;
    
    // ==================== 时钟生成模块 ====================
    clk_wiz_0 u_clk_wiz_0 (
        // Clock out ports
        .clk_out1(pixel_clk),      // 74.25MHz (1280x720@60Hz 像素时钟)
        .clk_out2(pix_clk_5x),     // 371.25MHz (5倍像素时钟，用于串行化)
        
        // Status and control signals
        .reset(~sys_rst_n),        // 异步复位，高有效
        .locked(clk_locked),       // 时钟锁定信号
        
        // Clock in ports
        .clk_in1(sys_clk)          // 输入系统时钟
    );
    
    // ==================== 视频时序驱动模块 ====================
    video_drive u_video_drive (
        .pixel_clk    (pixel_clk),
        .sys_rst_n    (sys_rst_n),
        
        .pixel_data   (pixel_data_w),
        
        .video_hs     (video_hs),
        .video_vs     (video_vs),
        .video_de     (video_de),
        .video_rgb    (video_rgb),
        
        .data_req     (),          // 可选连接
        .pixel_xpos   (pixel_xpos_w),
        .pixel_ypos   (pixel_ypos_w)
    );
    
    // ==================== 方块移动显示模块 ====================
    video_display_block_move u_video_display (
        .pixel_clk    (pixel_clk),
        .sys_rst_n    (sys_rst_n),
        
        .pixel_xpos   (pixel_xpos_w),
        .pixel_ypos   (pixel_ypos_w),
        
        .pixel_data   (pixel_data_w)
    );
    
    // ==================== DVI发射器模块 ====================
    dvi_transmitter_top u_dvi_transmitter_top (
        .pclk         (pixel_clk),
        .pclk_x5      (pix_clk_5x),
        .reset_n      (sys_rst_n & clk_locked),  // 系统复位 + 时钟锁定
        
        .video_din    (video_rgb),
        .video_hsync  (video_hs),
        .video_vsync  (video_vs),
        .video_de     (video_de),
        
        .tmds_clk_p   (tmds_clk_p),
        .tmds_clk_n   (tmds_clk_n),
        .tmds_data_p  (tmds_data_p),
        .tmds_data_n  (tmds_data_n),
        .tmds_oen     ()                         // 可选连接
    );
    
endmodule