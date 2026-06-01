module CRC8_CCITT #(
    parameter CRC_INIT_VALUE = 8'hFF
) (

    input clk,
    input rstb,

    input din,
    input init_crc,
    input calc_crc,

    output [7:0] crc_out

);


    wire [7:0] newcrc;

    reg  [7:0] crcreg;
    reg  [7:0] crcreg_nxt;


    assign newcrc[0] = crcreg[7] ^ din;
    assign newcrc[1] = (crcreg[7] ^ din) ^ crcreg[0];
    assign newcrc[2] = (crcreg[7] ^ din) ^ crcreg[1];
    assign newcrc[3] = crcreg[2];
    assign newcrc[4] = crcreg[3];
    assign newcrc[5] = crcreg[4];
    assign newcrc[6] = crcreg[5];
    assign newcrc[7] = crcreg[6];


    always @(*) begin
        if (init_crc) begin
            crcreg_nxt = CRC_INIT_VALUE;
        end else if (calc_crc) begin
            crcreg_nxt = newcrc;
        end else begin
            crcreg_nxt = crcreg;
        end
    end

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            crcreg <= CRC_INIT_VALUE;
        end else begin
            crcreg <= crcreg_nxt;
        end
    end


    assign crc_out = crcreg;


endmodule
