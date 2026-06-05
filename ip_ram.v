`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/05 09:42:27
// Design Name: 
// Module Name: ip_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ip_ram (
    input clk,
    input rst_n

);

    wire [7:0] douta;
    wire       ram_en;
    wire       rw;
    wire [4:0] ram_addr;
    wire [7:0] ram_rw_data;

    ram_rw u_ram_rw (
        .clk        (clk),
        .rst_n      (rst_n),
        .ram_en     (ram_en),
        .rw         (rw),
        .ram_addr   (ram_addr),
        .ram_rw_data(ram_rw_data)
    );

    //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
    blk_mem_gen_0 u_blk_mem_gen_0 (
        .clka (clk),          // input wire clka
        .ena  (ram_en),       // input wire ena
        .wea  (rw),           // input wire [0 : 0] wea
        .addra(ram_addr),     // input wire [4 : 0] addra
        .dina (ram_rw_data),  // input wire [7 : 0] dina
        .douta(douta)         // output wire [7 : 0] douta
    );
    // INST_TAG_END ------ End INSTANTIATION Template ---------

    ila_0 u_ila_0 (
        .clk(clk),  // input wire clk


        .probe0(ram_en),       // input wire [0:0]  probe0  
        .probe1(rw),           // input wire [0:0]  probe1 
        .probe2(ram_addr),     // input wire [4:0]  probe2 
        .probe3(ram_rw_data),  // input wire [7:0]  probe3 
        .probe4(douta)         // input wire [7:0]  probe4
    );


endmodule


module ram_rw (
    input clk,
    input rst_n,

    output reg       ram_en,
    output reg       rw,          // 1写 0读
    output reg [4:0] ram_addr,
    output reg [7:0] ram_rw_data
);

    reg [5:0] rw_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_en <= 0;
        end else begin
            ram_en <= 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw_cnt <= 0;
        end else if (rw_cnt == 6'd63) begin
            rw_cnt <= 0;
        end else begin
            rw_cnt <= rw_cnt + 1'b1;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_rw_data <= 0;
        end else if (rw_cnt < 6'd32 && ram_en) begin
            ram_rw_data <= ram_rw_data + 8'd1;
        end else begin
            ram_rw_data <= ram_rw_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw <= 1;
        end else if (rw_cnt < 6'd32) begin
            rw <= 1;
        end else begin
            rw <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_addr <= 0;
        end else begin
            ram_addr <= rw_cnt[4:0];
        end
    end

endmodule
