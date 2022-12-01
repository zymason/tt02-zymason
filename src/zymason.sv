`default_nettype none

// Top-level design module, acting only as a wrapper
module zymason_tinytop (
  input  logic [7:0] io_in,
  output logic [7:0] io_out);

  Zymason_Tiny1 p0 (.clock(io_in[0]), .reset(io_in[1]), .RW(io_in[2]),
                    .sel(io_in[3]), .pin_in(io_in[7:4]), .io_out);

endmodule : zymason_tinytop



// Primary design module
module Zymason_Tiny1 (
  input  logic       clock, reset,
  input  logic       RW, sel,
  input  logic [3:0] pin_in,
  output tri   [7:0] io_out);
  localparam NUM_DIGITS = 2;    // The number of total digits that can be stored

  logic pos_en, pulse;
  logic [6:0] dig_out[NUM_DIGITS-1:0];    // Unpacked digit output array
  logic [NUM_DIGITS-1:0] dig_en;          // Enable line for each digit


  // Shift register for selecting current display digit in both modes
  // Control FSM
  // Clocking module to generate slow pulses for display cycling in R-mode
  Zymason_ShiftReg #(NUM_DIGITS) s0 (.clock, .reset, .en(pos_en), .out(dig_en));
  Zymason_FSM f0 (.clock, .reset, .RW, .sel, .pulse, .pos_en);
  Zymason_PulseGen p0 (.clock, .reset, .spd({pin_in, sel}), .pulse);

  genvar i;
  generate
    for (i=0; i<NUM_DIGITS; i=i+1) begin: STR
      Zymason_DigStore ds (.clock, .reset, .en(dig_en[i]), .sel, .RW, .pin_in,
                          .dig_out(dig_out[i]));
      assign io_out[6:0] = (dig_en[i]) ? dig_out[i] : 'bz;  // Display driver
    end
  endgenerate

  // Output to segment
  assign io_out[6:0] = dig_out[dig_en];

  // Mode indicator
  assign io_out[7] = RW;

endmodule : Zymason_Tiny1



// Control state machine for Zymason_Tiny1
module Zymason_FSM (
  input  logic clock, reset,
  input  logic RW, sel, pulse,
  output logic pos_en);

  enum logic [1:0] {INIT, SCAN, WRT0, WRT1} state, nextState;

  // Explicit-style FSM
  always_ff @(posedge clock) begin
    state <= (reset) ? INIT : nextState;
  end

  // Next-state logic
  always_comb begin
    case (state)
      INIT: nextState = RW ? WRT0 : SCAN;
      SCAN: nextState = RW ? WRT0 : SCAN;
      WRT0: nextState = sel ? WRT1 : WRT0;
      WRT1: nextState = RW ? (sel ? WRT1 : WRT0) : SCAN;
      default: nextState = INIT;
    endcase
  end

  // Output logic
  always_comb begin
    case (state)
      INIT: pos_en = 1'b0;
      SCAN: pos_en = ~RW & pulse;
      WRT0: pos_en = 1'b0;
      WRT1: pos_en = RW & ~sel;
      default: pos_en = 1'b0;
    endcase
  end

endmodule : Zymason_FSM



// Single digit storage instance
module Zymason_DigStore (
  input  logic       clock, reset,
  input  logic       en, sel, RW,
  input  logic [3:0] pin_in,
  output logic [6:0] dig_out);

  // 2 implicit registers with a synchronous reset
  always_ff @(posedge clock) begin
    if (reset)
      dig_out <= 8'd0;
    else if (en & ~sel & RW)
      dig_out[3:0] <= pin_in;
    else if (en & sel & RW)
      dig_out[6:4] <= pin_in[2:0];
  end

endmodule : Zymason_DigStore



// Read-only left-shift register that resets to ...0001
module Zymason_ShiftReg
  #(parameter DW = 2)
  (input logic clock, reset,
  input  logic en,
  output logic [DW-1:0] out);

  always_ff @(posedge clock) begin
    if (reset) begin
      out <= {DW, {1'b0}};
      out[0] <= 1'b1;
    end
    else if (en)
      out <= {out[DW-2:0], out[DW-1]};
  end

endmodule : Zymason_ShiftReg



// Internal clocking pulse, expecting 6.25kHz clock as input
module Zymason_PulseGen (
  input  logic       clock, reset,
  input  logic [4:0] spd,
  output logic       pulse);

  logic [8:0] count;
  logic [4:0] lowCount;

  logic en_low;
  logic temp_pulse;

  // Invariant counter to produce pulses at 12.1Hz
  always_ff @(posedge clock) begin
    if (reset)
      count <= 9'd0;
    else
      count <= count + 9'd1;
  end

  // Variable counter to find spd
  always_ff @(posedge clock) begin
    if (reset | pulse)
      lowCount <= 5'd0;
    else if (en_low)
      lowCount <= lowCount + 5'd1;
  end

  // pulse is asserted for a single cycle since its counter immediately resets
  assign pulse = (lowCount == spd) ? 1'b1 : 1'b0;
  assign en_low = (count == 9'd0) ? 1'b1 : 1'b0;

endmodule : Zymason_PulseGen