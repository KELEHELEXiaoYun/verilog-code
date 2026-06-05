module ram_rw (
    input clk,
    input rst_n,

    output reg       ram_en,
    output reg       rw,
    output reg [4:0] ram_addr,
    output reg [7:0] ram_rw_data

);


    reg [5:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else if (cnt == 6'd63) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_en <= 0;
        end else begin
            ram_en <= 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw <= 1;
        end else if (cnt < 6'd32) begin
            rw <= 1;
        end else begin
            rw <= 0;
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_rw_data <= 0;
        end else if (cnt < 6'd32 && ram_en) begin
            ram_rw_data <= ram_rw_data + 1'b1;
        end else begin
            ram_rw_data <= ram_rw_data;
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_addr <= 0;
        end else begin
            ram_addr <= cnt[4:0];
        end
    end


endmodule

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

endmodule
