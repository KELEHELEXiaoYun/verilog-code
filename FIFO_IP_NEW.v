
module FIFO_WR(

    input wr_clk,
    input rst_n,

    input empty,
    input almost_full,
    input wr_rst_busy,

    output reg fifo_wr_en,
    output reg [7:0] fifo_wr_data

    );

    reg empty_d0;
    reg empty_d1;

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty_d0 <= 1'b0;
            empty_d1 <= 1'b0;
        end else begin
            empty_d0 <= empty;
            empty_d1 <= empty_d0;
        end
    end

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
           fifo_wr_en <= 1'b0;
        end else if (!wr_rst_busy) begin
           if (empty_d1) begin
                fifo_wr_en <= 1'b1;
           end else if (almost_full) begin
                fifo_wr_en <= 1'b0;
           end
        end
    end

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_data <= 8'b0;
        end else if (fifo_wr_en && fifo_wr_data <254) begin
           fifo_wr_data <= fifo_wr_data + 1'b1;
        end else begin
            fifo_wr_data <= 8'b0;
        end
    end

endmodule


module FIFO_RD (

    input rd_clk,
    input rst_n,

    input [7:0] fifo_rd_data,
    input full,
    input almost_empty,
    input rd_rst_busy,

    output reg fifo_rd_en

);  

    reg full_d0;
    reg full_d1;

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            full_d0 <= 1'b0;
            full_d1 <= 1'b0;
        end else begin
            full_d0 <= full;
            full_d1 <= full_d0;
        end
    end

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_rd_en <= 1'b0;
        end else if (!rd_rst_busy) begin
            if (full_d1) begin
                fifo_rd_en <= 1'b1;
            end else if (almost_empty) begin
                fifo_rd_en <= 1'b0;
            end
        end
    end

endmodule


module FIFO_IP (

    input sys_clk,
    input sys_rst_n

);

    wire clk_50m;
    wire clk_100m;
    wire locked;
    wire rst_n;
    wire        empty         ;
    wire        almost_full   ;
    wire        wr_rst_busy   ;
    wire        fifo_wr_en    ;
    wire  [7:0] fifo_wr_data  ;

    wire  [7:0] fifo_rd_data  ;
    wire        full          ;
    wire        almost_empty  ;
    wire        rd_rst_busy   ;
    wire        fifo_rd_en    ;
    wire  [7:0] rd_data_count;
    wire  [7:0] wr_data_count;
    assign rst_n = sys_rst_n & locked;

 clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(clk_50m),     // output clk_out1
    .clk_out2(clk_100m),     // output clk_out2
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(sys_clk)      // input clk_in1
);

FIFO_WR  u_fifo_wr(
    .wr_clk        (clk_50m     ),
    .rst_n         (rst_n       ),

    .empty         (empty       ),
    .almost_full   (almost_full ),
    .wr_rst_busy   (wr_rst_busy ),
    .fifo_wr_en    (fifo_wr_en  ),
    .fifo_wr_data  (fifo_wr_data)
);

FIFO_RD  u_fifo_rd(
    .rd_clk        (clk_100m    ),
    .rst_n         (rst_n       ),

    .fifo_rd_data  (fifo_rd_data),
    .full          (full        ),
    .almost_empty  (almost_empty),
    .rd_rst_busy   (rd_rst_busy ),
    .fifo_rd_en    (fifo_rd_en  )
);

fifo_generator_0 your_instance_name (
    .rst            (~rst_n),         //fifo复位高有效
    .wr_clk         (clk_50m),
    .rd_clk         (clk_100m),
    .din            (fifo_wr_data),
    .wr_en          (fifo_wr_en),
    .rd_en          (fifo_rd_en),
    .dout           (fifo_rd_data),
    .full           (full),
    .almost_full    (almost_full),
    .empty          (empty),
    .almost_empty   (almost_empty),
    .rd_data_count  (rd_data_count),
    .wr_data_count  (wr_data_count),
    .wr_rst_busy    (wr_rst_busy),
    .rd_rst_busy    (rd_rst_busy)
);
endmodule


module tb_FIFO_IP();

reg sys_clk;
reg sys_rst_n;

always #10 sys_clk = ~sys_clk;
FIFO_IP U_FIFO_IP (.sys_clk(sys_clk),.sys_rst_n(sys_rst_n));
initial begin
sys_clk = 0;
sys_rst_n = 0;
#200
sys_rst_n = 1;
#1000000;
$stop;
end

endmodule