`default_nettype none

module ChipInterface (
  input  logic CLOCK_50,
  input  logic [17:0] SW,
  output logic [6:0] HEX0, HEX2, HEX3,
  output logic [17:0] LEDR,
  output logic [7:0] LEDG);

  logic clock, reset;
  logic [12:0] count;
  logic [7:0] io_out;

  // Use the second-level module for simpler connections
  Zymason_Tiny1 dut (.clock, .reset, .RW(SW[2]), .sel(SW[3]), .pin_in(SW[7:4]),
                    .io_out);

  // Input connections
  assign reset = SW[1];
  assign clock = count[12];

  // Output connections
  assign LEDR[0] = io_out[7];
  assign HEX0 = io_out[6:0];

  // Divide clock from 50MHz to ~6.10kHz to simulate the real thing
  always_ff @(posedge CLOCK_50) begin
    if (reset)
      count <= 13'd0;
    else
      count <= count + 13'd1;
  end

endmodule : ChipInterface