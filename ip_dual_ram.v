module ram_wr (

    input clk,
    input rst_n,

    output reg       rd_flag,
    output reg       wr_en,
    output reg [5:0] wr_addr,
    output           wr_we,
    output     [7:0] wr_data

);

    assign wr_we   = wr_en;
    assign wr_data = wr_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en <= 1'b0;
        end else begin
            wr_en <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_addr <= 6'b0;
        end else if (wr_en) begin
            if (wr_addr == 6'd63) begin
                wr_addr <= 6'b0;
            end else begin
                wr_addr <= wr_addr + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_flag <= 1'b0;
        end else if (wr_addr == 6'd31) begin
            rd_flag <= 1'b1;
        end else begin
            rd_flag <= rd_flag;
        end
    end

endmodule


module ip_dual_ram (

    input sys_clk,
    input sys_rst_n

);

    wire       rd_flag;
    wire       wr_we;
    wire       wr_en;
    wire [5:0] wr_addr;
    wire [7:0] wr_data;
    wire [7:0] rd_data;
    wire       rd_en;
    wire [5:0] rd_addr;
    wire       rsta_busy;
    wire       rstb_busy;

    ram_wr u_ram_wr (
        .clk    (sys_clk),
        .rst_n  (sys_rst_n),
        .rd_flag(rd_flag),
        .wr_en  (wr_en),
        .wr_addr(wr_addr),
        .wr_we  (wr_we),
        .wr_data(wr_data)
    );

    blk_mem_gen_0 your_instance_name (
        .clka     (sys_clk),    // input wire clka
        .ena      (wr_en),      // input wire ena
        .wea      (wr_we),      // input wire [0 : 0] wea
        .addra    (wr_addr),    // input wire [5 : 0] addra
        .dina     (wr_data),    // input wire [7 : 0] dina
        .clkb     (sys_clk),    // input wire clkb
        .rstb     (sys_rst_n),  // input wire rstb
        .enb      (rd_en),      // input wire enb
        .addrb    (rd_addr),    // input wire [5 : 0] addrb
        .doutb    (rd_data),    // output wire [7 : 0] doutb
        .rsta_busy(rsta_busy),  // output wire rsta_busy
        .rstb_busy(rstb_busy)   // output wire rstb_busy
    );

    ram_rd u_ram_rd (
        .clk    (sys_clk),
        .rst_n  (sys_rst_n),
        .rd_flag(rd_flag),
        .rd_en  (rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule



module ram_rd (

    input clk,
    input rst_n,

    input       rd_flag,
    input [7:0] rd_data,

    output           rd_en,
    output reg [5:0] rd_addr

);

    assign rd_en = rd_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr <= 6'b0;
        end else if (rd_flag) begin
            if (rd_addr == 6'd63) begin
                rd_addr <= 6'b0;
            end else begin
                rd_addr <= rd_addr + 1'b1;
            end
        end
    end


endmodule


////////////////////////////////////////////////////////
`timescale 1ns / 1ns

module tb_ip_ram ();

    reg sys_clk;
    reg sys_rst_n;
    ip_dual_ram u_ip_dual_ram (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n)
    );
    always #10 sys_clk = ~sys_clk;
    initial begin
        sys_clk   = 0;
        sys_rst_n = 0;
        #200;
        sys_rst_n = 1;
        #1000000;
    end
endmodule
