module pulse_synchronizer #(
    
) (
    
    input  clksrc,
    input  resetb_clksrc,
    
    input  clkdest,
    input  resetb_clkdest,

    input  pulse_src,

    output pulse_dest

);


    reg  sig_stretched;
    wire sig_stretched_nxt;
    reg  sig_stretched_sync1, sig_stretched_dest;
    reg  sig_stretched_dest_d1;
    reg  sig_stretched_ack_pre, sig_stretched_ack;
    reg  sig_stretched_ack_d1;
    wire sig_stretched_ack_edge;
    
    
    assign sig_stretched_nxt = sig_stretched_ack_edge? 1'b0: (pulse_src? 1'b1: sig_stretched);

    always @(posedge clksrc or negedge resetb_clksrc) begin
        if (!resetb_clksrc) begin
            sig_stretched <= 1'b0;
        end else begin
            sig_stretched <= sig_stretched_nxt;
        end
    end

    always @(posedge clkdest or negedge resetb_clkdest) begin
        if (!resetb_clkdest) begin
            sig_stretched_sync1   <= 1'b0;
            sig_stretched_dest    <= 1'b0;
            sig_stretched_dest_d1 <= 1'b0;
        end else begin
            sig_stretched_sync1   <= sig_stretched;
            sig_stretched_dest    <= sig_stretched_sync1;
            sig_stretched_dest_d1 <= sig_stretched_dest;
        end
    end

    always @(posedge clksrc or negedge resetb_clksrc) begin
        if (!resetb_clksrc) begin
            sig_stretched_ack_pre <= 1'b0;
            sig_stretched_ack     <= 1'b0;
            sig_stretched_ack_d1  <= 1'b0;
        end else begin
            sig_stretched_ack_pre <= sig_stretched_dest;
            sig_stretched_ack     <= sig_stretched_ack_pre;
            sig_stretched_ack_d1  <= sig_stretched_ack;
        end 
    end

    assign sig_stretched_ack_edge = sig_stretched_ack & !sig_stretched_ack_d1;
    assign pulse_dest             = sig_stretched_dest & !sig_stretched_dest_d1;
    
     
endmodule