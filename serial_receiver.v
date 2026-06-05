module serial_receiver (
    input  clk,
    input  in,
    input  reset,  // Synchronous reset
    output done
);


    /*在许多（较旧的）串行通信协议中
每个数据字节都与起始位和停止位一起发送，
以帮助接收方从位流中分隔字节。
一种常见的方案是使用一个起始位 （0）
8 个数据位和 1 个停止位 （1）
当没有传输任何东西（空闲）时
该线路也处于逻辑 1
设计一个有限状态机，
当给定位流时，它将识别何时正确接收字节。
它需要识别起始位
等待所有 8 个数据位
然后验证停止位是否正确
如果停止位未按预期出现
则 FSM 必须等到找到停止位，
然后才能尝试接收下一个字节。*/
    reg [1:0] cs, ns;
    reg [3:0] cnt;
    parameter IDLE = 2'b00, RECV = 2'b01, DONE = 2'b10, WAIT = 2'b11;

    // State flip-flops
    always @(posedge clk)
        if (reset) cs <= IDLE;
        else cs <= ns;

    // State transition logic
    always @(*)
        case (cs)
            IDLE:    ns = in ? IDLE : RECV;
            RECV:    ns = cnt > 0 ? RECV : (in ? DONE : WAIT);
            DONE:    ns = in ? IDLE : RECV;
            WAIT:    ns = in ? IDLE : WAIT;
            default: ns = IDLE;
        endcase

    // Counter
    always @(posedge clk)
        if (reset) cnt <= 9;
        else
            case (ns)
                IDLE, DONE: cnt <= 9;
                RECV:       cnt <= cnt - 1;
                default:    cnt <= cnt;
            endcase

    // Output done
    assign done = cs == DONE;

endmodule
