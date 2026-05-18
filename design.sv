`timescale 1ns/1ps

// ============================================================
// I2C MASTER
// ============================================================
module i2c_master (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [6:0] addr,
    input  wire [7:0] data_in,
    output wire       scl,
    inout  wire       sda,
    output reg        done
);

reg [3:0] state;
reg [3:0] bit_cnt;
reg [7:0] shift_reg;

reg sda_out;
reg sda_en;

assign sda = (sda_en) ? sda_out : 1'bz;

// States
localparam IDLE  = 0,
           START = 1,
           ADDR  = 2,
           ACK1  = 3,
           DATA  = 4,
           ACK2  = 5,
           STOP  = 6;

// Clock Divider
reg [7:0] clk_div;
reg scl_int;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_div <= 0;
        scl_int <= 1;
    end else begin
        clk_div <= clk_div + 1;

        if (clk_div == 100) begin
            clk_div <= 0;
            scl_int <= ~scl_int;
        end
    end
end

assign scl = scl_int;

// Edge detection
reg scl_prev;

always @(posedge clk or posedge reset) begin
    if (reset)
        scl_prev <= 1;
    else
        scl_prev <= scl_int;
end

wire scl_rising  = (scl_prev == 0 && scl_int == 1);
wire scl_falling = (scl_prev == 1 && scl_int == 0);

// FSM
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state     <= IDLE;
        sda_out   <= 1;
        sda_en    <= 1;
        done      <= 0;
        bit_cnt   <= 0;
        shift_reg <= 0;
    end else begin

        case(state)

        IDLE: begin
            done    <= 0;
            sda_out <= 1;
            sda_en  <= 1;

            if (start)
                state <= START;
        end

        // START condition
        START: begin
            if (scl_rising) begin
                sda_out   <= 0;
                shift_reg <= {addr, 1'b0};
                bit_cnt   <= 7;
                state     <= ADDR;
            end
        end

        // Send address
        ADDR: begin

            if (scl_falling)
                sda_out <= shift_reg[bit_cnt];

            if (scl_rising) begin
                if (bit_cnt == 0)
                    state <= ACK1;
                else
                    bit_cnt <= bit_cnt - 1;
            end
        end

        // ACK after address
        ACK1: begin

            if (scl_falling)
                sda_en <= 0;

            if (scl_rising) begin

                if (sda == 1) begin
                    state <= STOP;
                end else begin
                    shift_reg <= data_in;
                    bit_cnt   <= 7;
                    sda_en    <= 1;
                    state     <= DATA;
                end
            end
        end

        // Send data
        DATA: begin

            if (scl_falling)
                sda_out <= shift_reg[bit_cnt];

            if (scl_rising) begin
                if (bit_cnt == 0)
                    state <= ACK2;
                else
                    bit_cnt <= bit_cnt - 1;
            end
        end

        // ACK after data
        ACK2: begin

            if (scl_falling)
                sda_en <= 0;

            if (scl_rising)
                state <= STOP;
        end

        // STOP condition
        STOP: begin

            if (scl_rising) begin
                sda_en  <= 1;
                sda_out <= 1;
                done    <= 1;
                state   <= IDLE;
            end
        end

        endcase
    end
end

endmodule


// ============================================================
// SIMPLE I2C SLAVE
// ============================================================
module i2c_slave (
    inout wire sda,
    input wire scl
);

reg sda_out;
reg sda_en;

assign sda = (sda_en) ? sda_out : 1'bz;

initial begin
    sda_en  = 0;
    sda_out = 0;
end

// ACK generation
always @(negedge scl) begin
    sda_en  <= 1;
    sda_out <= 0;
end

always @(posedge scl) begin
    sda_en <= 0;
end

endmodule
