`timescale 1ns / 1ps
`default_nettype none

module jupiter_ace #(
    parameter c_usb          = 1,  // Use USB connector to PS/2
  ) (
    input wire         clk_25mhz,
    input wire         usb_fpga_bd_dp,
    input wire         usb_fpga_bd_dn,

    output wire [3:0]  gpdi_dp, gpdi_dn,
    output wire        usb_fpga_pu_dp,
    output wire        usb_fpga_pu_dn,    
    output wire [3:0]  led,
    input wire [2:1]   btn,
    inout wire [27:0]  gpio
  );

  wire ear;

  assign led = ps2_key[3:0];

  // Set usb to PS/2 mode
  assign usb_fpga_pu_dp = 1;
  assign usb_fpga_pu_dn = 1;

  wire kbd_reset;
  wire [7:0] kbd_rows;
  wire [4:0] kbd_columns;
  wire video; // 1-bit video signal (black/white)


  // Trivial conversion for audio
  wire mic,spk;
  assign gpio[18] = spk;
  assign gpio[19] = mic;
  
  // Video timing
  wire vga_hsync, vga_vsync, vga_blank;

  // Power-on RESET (8 clocks)
  reg [7:0] poweron_reset = 8'h00;
  always @(posedge clkcpu) begin
    poweron_reset <= {poweron_reset[6:0],1'b1};
  end

  wire clkdvi;
  wire clkram; 
  wire clkvga; 
  wire clkcpu; 

  clk_25_system pll (
    .clk_in(clk_25mhz),
    .pll_125(clkdvi), // 125 Mhz, DDR bit rate
    .pll_75(clkram),  //  75 Mhz, treat bram as async
    .pll_25(clkvga),  //  25 Mhz, VGA pixel rate
    .pll_33(clkcpu)   //  3.25 Mhz, CPU clock
  );

  wire [10:0] ps2_key;

  // The Jupiter Ace core
  fpga_ace the_core (
    .clkram(clkram),
    .clk65(clkvga),
    .clkcpu(clkcpu),
    .reset(kbd_reset & poweron_reset[7] & ~btn[1]),
    .ear(ear),
    .kbd_reset(kbd_reset),
    .ps2_key(ps2_key),
    .video(video),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .blank(vga_blank),
    .mic(mic),
    .spk(spk)
  );

  // Get PS/2 keyboard events
  ps2 ps2_kbd (
     .clk(clkcpu),
     .ps2_clk(c_usb ? usb_fpga_bd_dp : gpio[3]),
     .ps2_data(c_usb ? usb_fpga_bd_dn : gpio[26]),
     .ps2_key(ps2_key)
  );

  // Convert VGA to HDMI
  HDMI_out vga2dvid (
    .pixclk(clkvga),
    .pixclk_x5(clkdvi),
    .red({8{video}}),
    .green({8{video}}),
    .blue({8{video}}),
    .vde(!vga_blank),
    .hSync(vga_hsync),
    .vSync(vga_vsync),
    .gpdi_dp(gpdi_dp),
    .gpdi_dn(gpdi_dn)
);

endmodule
