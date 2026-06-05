module video_drive (

    input pixel_clk,
    input sys_rst_n,

    input [23:0] pixel_data,

    output            video_hs,
    output            video_vs,
    output reg        video_de,
    output     [23:0] video_rgb,
    output reg        data_req,

    output reg [10:0] pixel_xpos,
    output reg [10:0] pixel_ypos

);

    // 1280 * 720
    parameter H_SYNC = 11'd40;
    parameter H_BACK = 11'd220;
    parameter H_DISP = 11'd1280;
    parameter H_FRONT = 11'd110;
    parameter H_TOTAL = 11'd1650;

    parameter V_SYNC = 11'd5;
    parameter V_BACK = 11'd20;
    parameter V_DISP = 11'd720;
    parameter V_FRONT = 11'd5;
    parameter V_TOTAL = 11'd750;

    // 1920 * 1080
    // parameter H_SYNC = 11'd4;
    // parameter H_BACK = 11'd148;
    // parameter H_DISP = 11'd1920;
    // parameter H_FRONT = 11'd88;
    // parameter H_TOTAL = 11'd2200;

    // parameter V_SYNC = 11'd5;
    // parameter V_BACK = 11'd36;
    // parameter V_DISP = 11'd1080;
    // parameter V_FRONT = 11'd4;
    // parameter V_TOTAL = 11'd1125;

    reg [11:0] cnt_h;
    reg [11:0] cnt_v;

    assign video_hs  = cnt_h < H_SYNC ? 1'b0 : 1'b1;
    assign video_vs  = cnt_v < V_SYNC ? 1'b0 : 1'b1;

    assign video_rgb = video_de ? pixel_data : 24'b0;


    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            video_de <= 1'b0;
        end else begin
            video_de <= data_req;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            data_req <= 1'b0;
        end else if ((cnt_h >= H_SYNC + H_BACK - 2) && (cnt_h < H_SYNC + H_BACK + H_DISP - 2) &&
                     (cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK + V_DISP)) begin
            data_req <= 1'b1;
        end else begin
            data_req <= 1'b0;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pixel_xpos <= 11'b0;
        end else if (data_req) begin
            pixel_xpos <= cnt_h + 2'd2 - H_SYNC - H_BACK;
        end else begin
            pixel_xpos <= 11'b0;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pixel_ypos <= 11'b0;
        end else if ((cnt_v >= (V_SYNC + V_BACK)) && (cnt_v < (V_SYNC + V_BACK + V_DISP))) begin
            pixel_ypos <= cnt_v + 1'b1 - V_SYNC - V_BACK;
        end else begin
            pixel_ypos <= 11'b0;
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_h <= 12'b0;
        end else begin
            if (cnt_h == H_TOTAL - 1) begin
                cnt_h <= 12'b0;
            end else begin
                cnt_h <= cnt_h + 1'b1;
            end
        end
    end

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_v <= 12'b0;
        end else if (cnt_h == H_TOTAL - 1) begin
            if (cnt_v == V_TOTAL - 1) begin
                cnt_v <= 12'b0;
            end else begin
                cnt_v <= cnt_v + 1'b1;
            end
        end else begin
            cnt_v <= cnt_v;
        end
    end


endmodule



module video_disply (

    input pixel_clk,
    input sys_rst_n,

    input [10:0] pixel_xpos,
    input [10:0] pixel_ypos,

    output reg [23:0] pixel_data

);

    parameter H_DISP = 11'd1280;
    parameter V_DISP = 11'D720;

    localparam WHITE = 24'b11111111_11111111_11111111;
    localparam BLACK = 24'b00000000_00000000_00000000;
    localparam RED = 24'b11111111_00001100_00000000;
    localparam GREEN = 24'b00000000_11111111_00000000;
    localparam BLUE = 24'b00000000_00000000_11111111;

    always @(posedge pixel_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) pixel_data <= BLACK;
        else begin
            if ((pixel_xpos >= 0) && (pixel_xpos < H_DISP / 5 * 1)) begin
                pixel_data <= WHITE;
            end else if ((pixel_xpos >= H_DISP / 5 * 1) && (pixel_xpos < H_DISP / 5 * 2)) begin
                pixel_data <= BLACK;
            end else if ((pixel_xpos >= H_DISP / 5 * 2) && (pixel_xpos < H_DISP / 5 * 3)) begin
                pixel_data <= RED;
            end else if ((pixel_xpos >= H_DISP / 5 * 3) && (pixel_xpos < H_DISP / 5 * 4)) begin
                pixel_data <= GREEN;
            end else begin
                pixel_data <= BLUE;
            end
        end
    end

endmodule



module dvi_encoder (

    input clkin,
    input rstin,

    input [7:0] din,
    input       c0,
    input       c1,
    input       de,

    output reg [9:0] dout

);

    parameter CTRLTOKEN0 = 10'b1101010100;
    parameter CTRLTOKEN1 = 10'b0010101011;
    parameter CTRLTOKEN2 = 10'b0101010100;
    parameter CTRLTOKEN3 = 10'b1010101011;


    reg  [3:0] n1d;
    reg  [7:0] din_q;
    reg        de_q;
    reg        de_req;
    reg        c0_q;
    reg        c1_q;
    reg        c0_reg;
    reg        c1_reg;
    reg  [8:0] q_m_reg;
    reg  [4:0] cnt;
    reg  [3:0] n1q_m;
    reg  [3:0] n0q_m;



    wire       decision1;
    wire [8:0] q_m;
    wire       decision2;
    wire       decision3;


    assign decision1 = (n1d > 4'h4) | (n1d == 4'h4) & (din_q[0] == 1'b0);

    assign q_m[0]    = din_q[0];
    assign q_m[1]    = decision1 ? (q_m[0] ^~ din_q[1]) : (q_m[0] ^ din_q[1]);
    assign q_m[2]    = decision1 ? (q_m[1] ^~ din_q[2]) : (q_m[1] ^ din_q[2]);
    assign q_m[3]    = decision1 ? (q_m[2] ^~ din_q[3]) : (q_m[2] ^ din_q[3]);
    assign q_m[4]    = decision1 ? (q_m[3] ^~ din_q[4]) : (q_m[3] ^ din_q[4]);
    assign q_m[5]    = decision1 ? (q_m[4] ^~ din_q[5]) : (q_m[4] ^ din_q[5]);
    assign q_m[6]    = decision1 ? (q_m[5] ^~ din_q[6]) : (q_m[5] ^ din_q[6]);
    assign q_m[7]    = decision1 ? (q_m[6] ^~ din_q[7]) : (q_m[6] ^ din_q[7]);
    assign q_m[8]    = decision1 ? 1'b0 : 1'b1;

    assign decision2 = cnt == 5'b0 | n1q_m == n0q_m;
    assign decision3 = (~cnt[4] & (n1q_m > n0q_m)) | (cnt[4] & (n0q_m > n1q_m));


    always @(posedge clkin) begin
        n1d   <= #1 din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];
        din_q <= #1 din;
    end

    always @(posedge clkin) begin

        de_q    <= #1 de;
        de_req  <= #1 de_q;

        c0_q    <= #1 c0;
        c0_reg  <= #1 c0_q;
        c1_q    <= #1 c1;
        c1_reg  <= #1 c1_q;

        q_m_reg <= #1 q_m;

    end

    always @(posedge clkin) begin
        n1q_m <= #1 q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        n0q_m <= #1 4'h8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
    end

    always @(posedge clkin or posedge rstin) begin
        if (rstin) begin
            cnt  <= 5'b0;
            dout <= 10'b0;
        end else begin
            if (de_req) begin
                if (decision2) begin
                    dout[9]   <= #1 ~q_m_reg[8];
                    dout[8]   <= #1 q_m_reg[8];
                    dout[7:0] <= #1 q_m_reg[8] ? q_m_reg[7:0] : ~q_m_reg[7:0];

                    cnt       <= #1 ~q_m_reg[8] ? cnt + n0q_m - n1q_m : cnt + n1q_m - n0q_m;
                end else begin
                    if (decision3) begin
                        dout[9]   <= #1 1'b1;
                        dout[8]   <= #1 q_m_reg[8];
                        dout[7:0] <= #1 ~q_m_reg[7:0];

                        cnt       <= #1 cnt + {q_m_reg[8], 1'b0} + (n0q_m - n1q_m);
                    end else begin
                        dout[9]   <= #1 1'b0;
                        dout[8]   <= #1 q_m_reg[8];
                        dout[7:0] <= #1 q_m_reg[7:0];

                        cnt       <= #1 cnt - {~q_m_reg[8], 1'b0} + (n1q_m - n0q_m);
                    end
                end
            end else begin
                case ({
                    c1_reg, c0_reg
                })
                    2'b00:   dout <= #1 CTRLTOKEN0;
                    2'b01:   dout <= #1 CTRLTOKEN1;
                    2'b10:   dout <= #1 CTRLTOKEN2;
                    default: dout <= #1 CTRLTOKEN3;
                endcase

                cnt <= #1 5'b0;
            end
        end
    end


endmodule



module serializer_10_to_1 (

    input       reset,
    input       paralell_clk,
    input       serial_clk_5x,
    input [9:0] paralell_data,

    output serial_data_out

);

    wire cascade1;
    wire cascade2;

    OSERDESE2 #(
        .DATA_RATE_OQ  ("DDR"),     // DDR, SDR
        .DATA_RATE_TQ  ("DDR"),     // DDR, BUF, SDR
        .DATA_WIDTH    (10),        // Parallel data width (2-8,10,14)
        .INIT_OQ       (1'b0),      // Initial value of OQ output (1'b0,1'b1)
        .INIT_TQ       (1'b0),      // Initial value of TQ output (1'b0,1'b1)
        .SERDES_MODE   ("MASTER"),  // MASTER, SLAVE
        .SRVAL_OQ      (1'b0),      // OQ output value when RST is used (1'b0,1'b1)
        .SRVAL_TQ      (1'b0),      // TQ output value when RST is used (1'b0,1'b1)
        .TBYTE_CTL     ("FALSE"),   // Enable tristate byte operation (FALSE, TRUE)
        .TBYTE_SRC     ("FALSE"),   // Tristate byte source (FALSE, TRUE)
        .TRISTATE_WIDTH(1)          // 3-state converter width (1,4)
    ) OSERDESE2_Master (
        .OFB      (),                  // 1-bit output: Feedback path for data
        .OQ       (serial_data_out),   // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .TBYTEOUT (TBYTEOUT),          // 1-bit output: Byte group tristate
        .TFB      (),                  // 1-bit output: 3-state control
        .TQ       (),                  // 1-bit output: 3-state control
        .CLK      (serial_clk_5x),     // 1-bit input: High speed clock
        .CLKDIV   (paralell_clk),      // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1       (paralell_data[0]),
        .D2       (paralell_data[1]),
        .D3       (paralell_data[2]),
        .D4       (paralell_data[3]),
        .D5       (paralell_data[4]),
        .D6       (paralell_data[5]),
        .D7       (paralell_data[6]),
        .D8       (paralell_data[7]),
        .OCE      (1'b1),              // 1-bit input: Output data clock enable
        .RST      (reset),             // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1 (cascade1),
        .SHIFTIN2 (cascade2),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1       (1'b0),
        .T2       (1'b0),
        .T3       (1'b0),
        .T4       (1'b0),
        .TBYTEIN  (1'b0),              // 1-bit input: Byte group tristate
        .TCE      (1'b0)               // 1-bit input: 3-state clock enable
    );

    OSERDESE2 #(
        .DATA_RATE_OQ  ("DDR"),    // DDR, SDR
        .DATA_RATE_TQ  ("DDR"),    // DDR, BUF, SDR
        .DATA_WIDTH    (10),       // Parallel data width (2-8,10,14)
        .INIT_OQ       (1'b0),     // Initial value of OQ output (1'b0,1'b1)
        .INIT_TQ       (1'b0),     // Initial value of TQ output (1'b0,1'b1)
        .SERDES_MODE   ("SLAVE"),  // MASTER, SLAVE
        .SRVAL_OQ      (1'b0),     // OQ output value when RST is used (1'b0,1'b1)
        .SRVAL_TQ      (1'b0),     // TQ output value when RST is used (1'b0,1'b1)
        .TBYTE_CTL     ("FALSE"),  // Enable tristate byte operation (FALSE, TRUE)
        .TBYTE_SRC     ("FALSE"),  // Tristate byte source (FALSE, TRUE)
        .TRISTATE_WIDTH(1)         // 3-state converter width (1,4)
    ) OSERDESE2_Slave (
        .OFB      (),                  // 1-bit output: Feedback path for data
        .OQ       (serial_data_out),   // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(cascade1),
        .SHIFTOUT2(cascade2),
        .TBYTEOUT (TBYTEOUT),          // 1-bit output: Byte group tristate
        .TFB      (),                  // 1-bit output: 3-state control
        .TQ       (),                  // 1-bit output: 3-state control
        .CLK      (serial_clk_5x),     // 1-bit input: High speed clock
        .CLKDIV   (paralell_clk),      // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1       (1'b0),
        .D2       (1'b0),
        .D3       (paralell_data[8]),
        .D4       (paralell_data[9]),
        .D5       (1'b0),
        .D6       (1'b0),
        .D7       (1'b0),
        .D8       (1'b0),
        .OCE      (1'b1),              // 1-bit input: Output data clock enable
        .RST      (reset),             // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1 (),
        .SHIFTIN2 (),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1       (1'b0),
        .T2       (1'b0),
        .T3       (1'b0),
        .T4       (1'b0),
        .TBYTEIN  (1'b0),              // 1-bit input: Byte group tristate
        .TCE      (1'b0)               // 1-bit input: 3-state clock enable
    );


endmodule



module asyn_rst_syn (

    input clk,
    input reset_n,

    output syn_reset

);

    reg reset_1;
    reg reset_2;


    assign syn_reset = reset_2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reset_1 <= 1'b1;
            reset_2 <= 1'b1;
        end else begin
            reset_1 <= 1'b0;
            reset_2 <= reset_1;
        end
    end

endmodule



module dvi_transmitter_top (

    input pclk,
    input pclk_x5,
    input reset_n,

    input [23:0] video_din,
    input        video_hsync,
    input        video_vsync,
    input        video_de,

    output       tmds_clk_p,
    output       tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n,
    output       tmds_oen

);

    wire       reset;

    wire [9:0] red_10bit;
    wire [9:0] green_10bit;
    wire [9:0] blue_10bit;
    wire [9:0] clk_10bit;

    wire [2:0] tmds_data_serial;
    wire       tmde_clk_serial;

    assign tmds_oen  = 1'b1;
    assign clk_10bit = 10'b1111100000;


    asyn_rst_syn reset_syn (

        .reset_n(reset_n),
        .clk    (pclk),

        .syn_reset(reset)

    );

    dvi_encoder encoder_b (

        .clkin(pclk),
        .rstin(reset),

        .din (video_din[7:0]),
        .c0  (video_hsync),
        .c1  (video_vsync),
        .de  (video_de),
        .dout(blue_10bit)

    );

    dvi_encoder encoder_g (

        .clkin(pclk),
        .rstin(reset),

        .din (video_din[15:8]),
        .c0  (1'b0),
        .c1  (1'b0),
        .de  (video_de),
        .dout(green_10bit)

    );

    dvi_encoder encoder_r (

        .clkin(pclk),
        .rstin(reset),

        .din (video_din[23:16]),
        .c0  (1'b0),
        .c1  (1'b0),
        .de  (video_de),
        .dout(red_10bit)

    );


    serializer_10_to_1 serializer_b (

        .reset        (reset),
        .paralell_clk (pclk),
        .serial_clk_5x(pclk_x5),
        .paralell_data(blue_10bit),

        .serial_data_out(tmds_data_serial[0])
    );

    serializer_10_to_1 serializer_g (

        .reset        (reset),
        .paralell_clk (pclk),
        .serial_clk_5x(pclk_x5),
        .paralell_data(green_10bit),

        .serial_data_out(tmds_data_serial[1])
    );

    serializer_10_to_1 serializer_r (

        .reset        (reset),
        .paralell_clk (pclk),
        .serial_clk_5x(pclk_x5),
        .paralell_data(red_10bit),

        .serial_data_out(tmds_data_serial[2])
    );

    serializer_10_to_1 serializer_clk (

        .reset        (reset),
        .paralell_clk (pclk),
        .serial_clk_5x(pclk_x5),
        .paralell_data(clk_10bit),

        .serial_data_out(tmds_data_serial)
    );


    OBUFDS #(
        .IOSTANDARD("TMDS_33"),  // Specify the output I/O standard
        .SLEW      ("SLOW")      // Specify the output slew rate
    ) TMDS0 (
        .O (tmds_data_p[0]),      // Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[0]),      // Diff_n output (connect directly to top-level port)
        .I (tmds_data_serial[0])  // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33"),  // Specify the output I/O standard
        .SLEW      ("SLOW")      // Specify the output slew rate
    ) TMDS1 (
        .O (tmds_data_p[1]),      // Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[1]),      // Diff_n output (connect directly to top-level port)
        .I (tmds_data_serial[1])  // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33"),  // Specify the output I/O standard
        .SLEW      ("SLOW")      // Specify the output slew rate
    ) TMDS2 (
        .O (tmds_data_p[2]),      // Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[2]),      // Diff_n output (connect directly to top-level port)
        .I (tmds_data_serial[2])  // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33"),  // Specify the output I/O standard
        .SLEW      ("SLOW")      // Specify the output slew rate
    ) TMDS3 (
        .O (tmds_clk_p),      // Diff_p output (connect directly to top-level port)
        .OB(tmds_clk_n),      // Diff_n output (connect directly to top-level port)
        .I (tmde_clk_serial)  // Buffer input
    );


endmodule



module hdmi_colorbar_top (

    input sys_clk,
    input sys_rst_n,

    output       tmds_clk_p,
    output       tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n

);

    wire        pixel_clk;
    wire        pix_clk_5x;
    wire        clk_locked;

    wire [10:0] pixel_xpos_w;
    wire [10:0] pixel_ypos_w;
    wire [23:0] pixel_data_w;

    wire        video_hs;
    wire        video_vs;
    wire        video_de;
    wire [23:0] video_rgb;


    clk_wiz_0 u_clk_wiz_0 (

        // Clock out ports
        .clk_out1(pixel_clk),   // output clk_out1
        .clk_out2(pix_clk_5x),  // output clk_out2
        // Status and control signals
        .reset   (~sys_rst_n),  // input reset
        .locked  (clk_locked),  // output locked
        // Clock in ports
        .clk_in1 (sys_clk)      // input clk_in1

    );

    video_drive u_video_drive (

        .pixel_clk(pixel_clk),
        .sys_rst_n(sys_rst_n),

        .pixel_data(pixel_data_w),
        .video_hs  (video_hs),
        .video_vs  (video_vs),
        .video_de  (video_de),
        .video_rgb (video_rgb),
        .data_req  (),
        .pixel_xpos(pixel_xpos_w),
        .pixel_ypos(pixel_ypos_w)

    );

    video_disply u_video_disply (

        .pixel_clk(pixel_clk),
        .sys_rst_n(sys_rst_n),

        .pixel_xpos(pixel_xpos_w),
        .pixel_ypos(pixel_ypos_w),
        .pixel_data(pixel_data_w)

    );

    dvi_transmitter_top u_dvi_transmitter_top (

        .pclk   (pixel_clk),
        .pclk_x5(pix_clk_5x),
        .reset_n(sys_rst_n & clk_locked),

        .video_din  (video_rgb),
        .video_hsync(video_hs),
        .video_vsync(video_vs),
        .video_de   (video_de),

        .tmds_clk_p (tmds_clk_p),
        .tmds_clk_n (tmds_clk_n),
        .tmds_data_p(tmds_data_p),
        .tmds_data_n(tmds_data_n),
        .tmds_oen   ()

    );


endmodule



`timescale 1ns / 1ps
module tb_hdmi_colorbar_top ();

    reg        sys_clk;
    reg        sys_rst_n;


    wire       tmds_clk_p;
    wire       tmds_clk_n;
    wire [2:0] tmds_data_p;
    wire [2:0] tmds_data_n;


    initial begin
        sys_clk   = 1'b1;
        sys_rst_n = 1'b0;
        #201 sys_rst_n = 1'b1;
    end


    always #10 sys_clk <= ~sys_clk;


    hdmi_colorbar_top u_hdmi_colorbar_top (

        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .tmds_clk_p (tmds_clk_p),
        .tmds_clk_n (tmds_clk_n),
        .tmds_data_p(tmds_data_p),
        .tmds_data_n(tmds_data_n)

    );


endmodule

