module lcd_drive (
    
    input lcd_pclk,
    input rst_n,

    input [23:0] pixel_data,
    input [15:0] lcd_id,

    output reg [10:0] pixel_xpos,
    output reg [10:0] pixel_ypos,
    output reg [10:0] h_disp,
    output reg [10:0] v_disp,

    output lcd_clk,
    output reg lcd_de,
    output [23:0] lcd_rgb,
    output lcd_bl,
    output lcd_rst,
    output lcd_hs,
    output lcd_vs

);
   
    // 4.3' 480*272
    parameter  H_SYNC_4342 = 11'd41;
    parameter  H_BACK_4342 = 11'd2;
    parameter  H_DISP_4342 = 11'd480;
    parameter  H_FRONT_4342 = 11'd2;
    parameter  H_TOTAL_4342 = 11'd525;

    parameter  V_SYNC_4342 = 11'd10;
    parameter  V_BACK_4342 = 11'd2;
    parameter  V_DISP_4342 = 11'd272;
    parameter  V_FRONT_4342 = 11'd2;
    parameter  V_TOTAL_4342 = 11'd286;

    //7' 800*480
    parameter  H_SYNC_7084   = 11'd128;  //行同步
    parameter  H_BACK_7084   = 11'd88;   //行显示后沿
    parameter  H_DISP_7084   = 11'd800;  //行有效数据
    parameter  H_FRONT_7084  = 11'd40;   //行显示前沿
    parameter  H_TOTAL_7084  = 11'd1056; //行扫描周期

    parameter  V_SYNC_7084   = 11'd2;    //场同步
    parameter  V_BACK_7084   = 11'd33;   //场显示后沿
    parameter  V_DISP_7084   = 11'd480;  //场有效数据
    parameter  V_FRONT_7084  = 11'd10;   //场显示前沿
    parameter  V_TOTAL_7084  = 11'd525;  //场扫描周期

    //7' 1024*600
    parameter  H_SYNC_7016   = 11'd20;   //行同步
    parameter  H_BACK_7016   = 11'd140;  //行显示后沿
    parameter  H_DISP_7016   = 11'd1024; //行有效数据
    parameter  H_FRONT_7016  = 11'd160;  //行显示前沿
    parameter  H_TOTAL_7016  = 11'd1344; //行扫描周期

    parameter  V_SYNC_7016   = 11'd3;    //场同步
    parameter  V_BACK_7016   = 11'd20;   //场显示后沿
    parameter  V_DISP_7016   = 11'd600;  //场有效数据
    parameter  V_FRONT_7016  = 11'd12;   //场显示前沿
    parameter  V_TOTAL_7016  = 11'd635;  //场扫描周期

    //10.1' 1280*800
    parameter  H_SYNC_1018    = 11'd10;   //行同步
    parameter  H_BACK_1018    = 11'd80;   //行显示后沿
    parameter  H_DISP_1018    = 11'd1280; //行有效数据
    parameter  H_FRONT_1018   = 11'd70;   //行显示前沿
    parameter  H_TOTAL_1018   = 11'd1440; //行扫描周期

    parameter  V_SYNC_1018    = 11'd3;    //场同步
    parameter  V_BACK_1018    = 11'd10;   //场显示后沿
    parameter  V_DISP_1018    = 11'd800;  //场有效数据
    parameter  V_FRONT_1018   = 11'd10;   //场显示前沿
    parameter  V_TOTAL_1018   = 11'd823;  //场扫描周期

    // 4.3' 800*480
    parameter  H_SYNC_4384    = 11'd128;  // 行同步
    parameter  H_BACK_4384    = 11'd88;   // 行显示后沿
    parameter  H_DISP_4384    = 11'd800;  // 行有效数据
    parameter  H_FRONT_4384   = 11'd40;   // 行显示前沿
    parameter  H_TOTAL_4384   = 11'd1056; // 行扫描周期

    parameter  V_SYNC_4384    = 11'd2;    // 场同步
    parameter  V_BACK_4384    = 11'd33;   // 场显示后沿
    parameter  V_DISP_4384    = 11'd480;  // 场有效数据
    parameter  V_FRONT_4384   = 11'd10;   // 场显示前沿
    parameter  V_TOTAL_4384   = 11'd525;  // 场扫描周期


    reg [10:0] cnt_h;
    reg [9:0] cnt_v;
    reg data_req;
    reg [10:0] h_sync;
    reg [10:0] h_back;
    reg [10:0] h_front;
    reg [10:0] h_total;
    reg [10:0] v_sync;
    reg [10:0] v_back;
    reg [10:0] v_front;
    reg [10:0] v_total;



    assign lcd_clk = lcd_pclk;
    assign lcd_bl  = 1'b1;
    assign lcd_rst = 1'b1;
    assign lcd_hs  = 1'b1;
    assign lcd_vs  = 1'b1;

    assign lcd_rgb = lcd_de ? pixel_data : 24'b0;


    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_h <= 11'b0;
        end else begin
            if (cnt_h == h_total - 1) begin
                cnt_h <= 11'b0;
            end else begin
                cnt_h <= cnt_h + 1'b1;
            end
        end
    end

    always @(posedge lcd_pclk or negedge rst_n ) begin
        if (!rst_n) begin
            cnt_v <= 10'b0;
        end else begin
            if (cnt_h == h_total - 1) begin
                if (cnt_v == v_total - 1) begin
                    cnt_v <= 10'b0;
                end else begin
                    cnt_v <= cnt_v + 1'b1;
                end
            end else begin
                cnt_v <= cnt_v;
            end
        end
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
           lcd_de <= 1'b0;
        end else begin
           if ((cnt_h > h_sync + h_back - 1) && (cnt_h < h_sync + h_back + h_disp) && (cnt_v > v_sync + v_back - 1) && (cnt_v < v_sync + v_back + v_disp))begin
                lcd_de <= 1'b1;
           end else begin
                lcd_de <= 1'b0;
           end
        end
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
          data_req <= 1'b0;
        end else begin
           if ((cnt_h > h_sync + h_back - 2) && (cnt_h < h_sync + h_back + h_disp - 1) && (cnt_v >v_sync + v_back - 1) && (cnt_v <v_sync + v_back + v_disp))begin
                data_req <= 1'b1;
           end else begin
                data_req <= 1'b0;
           end
        end
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_xpos <= 10'b0;
        end else if (data_req) begin
            pixel_xpos <= pixel_xpos + 1'b1;
        end else begin
            pixel_xpos <= 10'b0;
        end 
    end

    always @(posedge lcd_pclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_ypos <= 10'b0;
        end else if ((cnt_v >=v_sync + v_back) && (cnt_v <v_sync + v_back + v_disp)) begin
            pixel_ypos <= cnt_v + 1'b1 - (v_sync + v_back);
        end else begin
            pixel_ypos <= 10'b0;
        end 
    end

    always @(posedge lcd_pclk) begin
        case (lcd_id)
            16'h4342 : begin
                h_disp <= H_DISP_4342;
                v_disp <= V_DISP_4342;
                h_sync <= H_SYNC_4342;
                h_back <= H_BACK_4342;
                h_front<= H_FRONT_4342;
                h_total<= H_TOTAL_4342;
                v_sync <= V_SYNC_4342;
                v_back <= V_BACK_4342;
                v_front<= V_FRONT_4342;
                v_total<= V_TOTAL_4342;
            end 
            16'h7084 : begin
                h_disp <= H_DISP_7084;
                v_disp <= V_DISP_7084;
                h_sync <= H_SYNC_7084;
                h_back <= H_BACK_7084;
                h_front<= H_FRONT_7084;
                h_total<= H_TOTAL_7084;
                v_sync <= V_SYNC_7084;
                v_back <= V_BACK_7084;
                v_front<= V_FRONT_7084;
                v_total<= V_TOTAL_7084;
            end 
            16'h7016 : begin
                h_disp <= H_DISP_7016;
                v_disp <= V_DISP_7016;
                h_sync <= H_SYNC_7016;
                h_back <= H_BACK_7016;
                h_front<= H_FRONT_7016;
                h_total<= H_TOTAL_7016;
                v_sync <= V_SYNC_7016;
                v_back <= V_BACK_7016;
                v_front<= V_FRONT_7016;
                v_total<= V_TOTAL_7016;
            end 
            16'h1018 : begin
                h_disp <= H_DISP_1018;
                v_disp <= V_DISP_1018;
                h_sync <= H_SYNC_1018;
                h_back <= H_BACK_1018;
                h_front<= H_FRONT_1018;
                h_total<= H_TOTAL_1018;
                v_sync <= V_SYNC_1018;
                v_back <= V_BACK_1018;
                v_front<= V_FRONT_1018;
                v_total<= V_TOTAL_1018;
            end 
            16'h4384 : begin
                h_disp <= H_DISP_4384;
                v_disp <= V_DISP_4384;
                h_sync <= H_SYNC_4384;
                h_back <= H_BACK_4384;
                h_front<= H_FRONT_4384;
                h_total<= H_TOTAL_4384;
                v_sync <= V_SYNC_4384;
                v_back <= V_BACK_4384;
                v_front<= V_FRONT_4384;
                v_total<= V_TOTAL_4384;
            end 
            default: ;
        endcase
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
    parameter WHITE = 24'hFFFFFF;
    parameter BLACK = 24'h000000;
    parameter RED   = 24'hFF0000;
    parameter GREEN = 24'h00FF00;
    parameter BLUE  = 24'h0000FF;

    always@(posedge lcd_pclk or negedge rst_n)begin
        if(!rst_n)
            pixel_data <= BLACK;
        else begin
            if((pixel_xpos >= 0) && (pixel_xpos < h_disp/5*1)) begin
                pixel_data <= WHITE;
            end else if((pixel_xpos >= h_disp/5*1) && (pixel_xpos < h_disp/5*2)) begin
                pixel_data <= BLACK;
            end else if((pixel_xpos >= h_disp/5*2) && (pixel_xpos < h_disp/5*3)) begin
                pixel_data <= RED;
            end else if((pixel_xpos >= h_disp/5*3) && (pixel_xpos < h_disp/5*4)) begin
                pixel_data <= GREEN;
            end else begin
                pixel_data <= BLUE;
            end
        end
    end 


endmodule



module lcd_rgb_colorbar (
    
    input sys_clk,
    input sys_rst_n,

    output lcd_clk,
    output lcd_de,
    inout  [23:0] lcd_rgb,
    output lcd_bl,
    output lcd_rst,
    output lcd_hs,
    output lcd_vs

);

    wire [23:0] pixel_data;
    wire [10:0] pixel_xpos;
    wire [10:0] pixel_ypos;
    wire [10:0] h_disp;
    wire [10:0] v_disp;
    wire [15:0] lcd_id;
    wire [23:0] lcd_rgb_i;
    wire [23:0] lcd_rgb_o;


    genvar i;
    generate for (i = 0; i < 24; i = i + 1) 
        begin : IOBUF_LOOP
             IOBUF #(
               .DRIVE(12), // Specify the output drive strength
               .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
               .IOSTANDARD("DEFAULT"), // Specify the I/O standard
               .SLEW("SLOW") // Specify the output slew rate
            ) IOBUF_inst (
               .O(lcd_rgb_i [i]),     // Buffer output
               .IO(lcd_rgb [i]),   // Buffer inout port (connect directly to top-level port)
               .I(lcd_rgb_o [i]),     // Buffer input
               .T(~lcd_de)      // 3-state enable input, high=input, low=output
            );   
        end
    endgenerate

    //assign lcd_rgb_i = lcd_rgb;
    //assign lcd_rgb = lcd_de ? lcd_rgb :{24{1'bz}};


    lcd_drive u_lcd_drive(

        .lcd_pclk (lcd_pclk),
        .rst_n (sys_rst_n),
        .lcd_id (lcd_id),
        .pixel_data (pixel_data),
        .pixel_xpos (pixel_xpos),
        .pixel_ypos (pixel_ypos),
        .h_disp (h_disp),
        .v_disp (v_disp),
        .lcd_clk (lcd_clk),
        .lcd_de (lcd_de),
        .lcd_rgb (lcd_rgb_o),
        .lcd_bl (lcd_bl),
        .lcd_rst (lcd_rst),
        .lcd_hs (lcd_hs),
        .lcd_vs (lcd_vs)

    );

    lcd_display u_lcd_display (
    
        .lcd_pclk (lcd_pclk),
        .rst_n (sys_rst_n),    

        .pixel_xpos (pixel_xpos),
        .pixel_ypos (pixel_ypos),
        .h_disp (h_disp),
        .v_disp (v_disp),

        .pixel_data (pixel_data)

    );


    clk_div u_clk_div (

        .clk (sys_clk),
        .rst_n (sys_rst_n),

        .lcd_id (lcd_id),

        .lcd_pclk (lcd_pclk)

    );

    rd_id u_rd_id (

        .clk (sys_clk),
        .rst_n (sys_rst_n),

        .lcd_rgb (lcd_rgb_i),

        .lcd_id (lcd_id)

    );

endmodule



module tb_lcd_rgb_colorbar ();
    
    reg sys_clk;
    reg sys_rst_n;

    wire lcd_clk;
    wire lcd_de;
    wire [23:0] lcd_rgb;
    wire lcd_bl;
    wire lcd_rst;
    wire lcd_hs;
    wire lcd_vs;

    initial begin
        sys_clk = 1'b0;
        sys_rst_n = 1'b0;
        #200;
        sys_rst_n = 1'b1;
    end

    assign lcd_rgb = lcd_de ? {24{1'bz}} : 24'h80;

    always #10 sys_clk = ~sys_clk;


    lcd_rgb_colorbar u_lcd_rgb_colorbar (
    // 输入端口
    .sys_clk    (sys_clk),    // 系统时钟输入
    .sys_rst_n  (sys_rst_n),  // 系统复位输入（低有效）
    
    // 输出端口
    .lcd_clk    (lcd_clk),    // LCD 像素时钟输出
    .lcd_de     (lcd_de),     // LCD 数据使能输出
    .lcd_rgb    (lcd_rgb),    // LCD 24位RGB数据输出
    .lcd_bl     (lcd_bl),     // LCD 背光控制输出
    .lcd_rst    (lcd_rst),    // LCD 复位输出
    .lcd_hs     (lcd_hs),     // LCD 行同步输出
    .lcd_vs     (lcd_vs)      // LCD 场同步输出
    );

endmodule




module rd_id (
    input clk,
    input rst_n,

    input [23:0] lcd_rgb,

    output reg [15:0] lcd_id

);

    reg rd_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_flag <= 1'b0;
        end else begin
            if (!rd_flag) begin
                rd_flag <= 1'b1;
            end
        end
    end

     always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lcd_id <= 16'b0;
        end else begin
            if (!rd_flag) begin
                case ({lcd_rgb [7], lcd_rgb [15], lcd_rgb [23]})
                    3'b000 : lcd_id <= 16'h4342;
                    3'b001 : lcd_id <= 16'h7084;
                    3'b010 : lcd_id <= 16'h7016;
                    3'b100 : lcd_id <= 16'h4384;
                    3'b101 : lcd_id <= 16'h1018;
                    default: lcd_id <= 16'b0;
                endcase
            end
        end
    end


endmodule



module clk_div (
    input clk,
    input rst_n,

    input [15:0] lcd_id,

    output reg  lcd_pclk

);

    reg clk_25m;
    reg clk_12_5m;

    reg div_4_cnt;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_25m <= 0;
        end else begin
            clk_25m <= ~clk_25m;
        end
    end

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_12_5m <= 0;
        end else begin
            if (div_4_cnt) begin
                clk_12_5m <= ~clk_12_5m;
            end else begin
                clk_12_5m <= clk_12_5m;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_4_cnt <= 0;
        end else begin
            div_4_cnt <= div_4_cnt + 1'b1;
        end
    end
    
    always @(*) begin
        case (lcd_id)
            16'h4342 : lcd_pclk = clk_12_5m; 
            16'h7084 : lcd_pclk = clk_25m;
            16'h7016 : lcd_pclk = clk;
            16'h4384 : lcd_pclk = clk_25m;
            16'h1018 : lcd_pclk = clk;
            default  : lcd_pclk = 1'b0;
        endcase 
    end

endmodule