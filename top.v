module top (
    input wire clk,
    input wire reset_btn,
    input wire start_btn,
    output wire scl,
    inout wire sda,
    output wire led_done
);

wire done;

// Instantiate I2C Master
i2c_master uut (
    .clk(clk),
    .reset(reset_btn),
    .start(start_btn),
    .addr(7'h50),
    .data_in(8'hA5),
    .scl(scl),
    .sda(sda),
    .done(done)
);

// LED indicator
assign led_done = done;

endmodule
