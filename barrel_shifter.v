module barrel_shifter #(
    
) (
    
    input       [7:0]  sig_xyz    ,
    input       [2:0]  sel_shft   ,
    
    output reg  [7:0]  sig_xyz_barshft

);

    wire [7:0] sig_xyz_barshft1;
    wire [7:0] sig_xyz_barshft2;
    wire [7:0] sig_xyz_barshft3;
    wire [7:0] sig_xyz_barshft4;
    wire [7:0] sig_xyz_barshft5;
    wire [7:0] sig_xyz_barshft6;
    wire [7:0] sig_xyz_barshft7;

    assign sig_xyz_barshft1 = {sig_xyz[6:0], sig_xyz[7]  };
    assign sig_xyz_barshft2 = {sig_xyz[5:0], sig_xyz[7:6]};
    assign sig_xyz_barshft3 = {sig_xyz[4:0], sig_xyz[7:5]};
    assign sig_xyz_barshft4 = {sig_xyz[3:0], sig_xyz[7:4]};
    assign sig_xyz_barshft5 = {sig_xyz[2:0], sig_xyz[7:3]};
    assign sig_xyz_barshft6 = {sig_xyz[1:0], sig_xyz[7:2]};
    assign sig_xyz_barshft7 = {sig_xyz[0]  , sig_xyz[7:1]};


    always @(*) begin
        sig_xyz_barshft = sig_xyz;
        case (sel_shft)
            3'd1: sig_xyz_barshft = sig_xyz_barshft1;
            3'd2: sig_xyz_barshft = sig_xyz_barshft2; 
            3'd3: sig_xyz_barshft = sig_xyz_barshft3; 
            3'd4: sig_xyz_barshft = sig_xyz_barshft4; 
            3'd5: sig_xyz_barshft = sig_xyz_barshft5; 
            3'd6: sig_xyz_barshft = sig_xyz_barshft6; 
            3'd7: sig_xyz_barshft = sig_xyz_barshft7; 
            default: sig_xyz_barshft = sig_xyz_barshft;
        endcase
    end

endmodule