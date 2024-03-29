`timescale 1ns / 1ps
`default_nettype none

module fpga_ace (
    input  wire clkram,
    input  wire clk65,
    input  wire clkcpu,
    input  wire reset,
    input  wire ear,
    input  wire [10:0] ps2_key,
    output wire kbd_reset,
    output wire video,
    output wire hsync,
    output wire vsync,
    output wire blank,
    output wire mic,
    output wire spk
);
	
   // Z80 buses
   wire [7:0]  DinZ80;
   wire [7:0]  DoutZ80;
   wire [15:0] AZ80;
	
   // Memory control signals
   wire iorq_n, mreq_n, int_n, rd_n, wr_n, wait_n;
   wire rom_enable, sram_enable, cram_enable, uram_enable, xram_enable, eram_enable, data_from_jace_oe;
   wire [7:0] dout_rom, dout_sram, dout_cram, dout_uram, dout_xram, dout_eram, data_from_jace;
   wire [7:0] sram_data, cram_data;
   wire [9:0] sram_addr, cram_addr;
    
   // Address bus copy for keyboard rows
   assign rows = AZ80[15:8];

   // Address multiplexer
   assign DinZ80 = rom_enable        ? dout_rom :
                   sram_enable       ? dout_sram :
                   cram_enable       ? dout_cram :
                   uram_enable       ? dout_uram :
                   xram_enable       ? dout_xram :
                   eram_enable       ? dout_eram :
                   data_from_jace_oe ? data_from_jace :
                                       sram_data | cram_data;  // By default, this is what the data bus sees

  // Memory
  ram1k_dualport sram (
    .clk(clkram),
    .ce(sram_enable),
    .a1(AZ80[9:0]),
    .a2(sram_addr),
    .din(DoutZ80),
    .dout1(dout_sram),
    .dout2(sram_data),
    .we(~wr_n)
  );
		
  ram1k_dualport cram (
    .clk(clkram),
    .ce(cram_enable),
    .a1(AZ80[9:0]),
    .a2(cram_addr),
    .din(DoutZ80),
    .dout1(dout_cram),
    .dout2(cram_data),
    .we(~wr_n)
  );
		
  ram1k uram(
    .clk(clkram),
    .ce(uram_enable),
    .a(AZ80[9:0]),
    .din(DoutZ80),
    .dout(dout_uram),
    .we(~wr_n)
  );
		
  ram16k xram(
    .clk(clkram),
    .ce(xram_enable),
    .a(AZ80[13:0]),
    .din(DoutZ80),
    .dout(dout_xram),
    .we(~wr_n)
  );


  // assign dout_xram = 8'hAA;
  
/*  
  ram32k eram(
    .clk(clkram),
    .ce(eram_enable),
    .a(AZ80[14:0]),
    .din(DoutZ80),
    .dout(dout_eram),
    .we(~wr_n)
  );
*/ 
  
  assign dout_eram = 8'hAA;

  /* ROM */
  rom the_rom(
    .clk(clkram),
    .ce(rom_enable),
    .a(AZ80[12:0]),
    .din(DoutZ80),
    .dout(dout_rom),
    .we(~wr_n) //  & enable_write_to_rom)
  );
	
  /* CPU */
  tv80n cpu(
    // Outputs
   .m1_n(), 
   .mreq_n(mreq_n), 
   .iorq_n(iorq_n), 
   .rd_n(rd_n), 
   .wr_n(wr_n), 
   .rfsh_n(), 
   .halt_n(), 
   .busak_n(), 
   .A(AZ80), 
   .do(DoutZ80),
   // Inputs
   .di(DinZ80), 
   .reset_n(reset), 
   .clk(clkcpu), 
   .wait_n(wait_n), 
   .int_n(int_n), 
   .nmi_n(1'b1), 
   .busrq_n(1'b1)
  );

  // Ace-specific logic      
  jace_logic jlogic (
    .clk(clk65),
    // CPU interface
    .cpu_addr(AZ80),
    .mreq_n(mreq_n),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .data_from_cpu(DoutZ80),
    .data_to_cpu(data_from_jace),
    .data_to_cpu_oe(data_from_jace_oe),
    .wait_n(wait_n),
    .int_n(int_n),
    // CPU-RAM interface
    .rom_enable(rom_enable),
    .sram_enable(sram_enable),
    .cram_enable(cram_enable),
    .uram_enable(uram_enable),
    .xram_enable(xram_enable),
    .eram_enable(eram_enable),
    // Screen RAM and Char RAM interface
    .screen_addr(sram_addr),
    .screen_data(sram_data),
    .char_addr(cram_addr),
    .char_data(cram_data),
    // Devices
    .kbdcols(columns),
    .ear(ear),
    .spk(spk),
    .mic(mic),
    .video(video),
    .hsync_vga(hsync),
    .vsync_vga(vsync),
    .blank_vga(blank)
  );

  wire [7:0] rows;
  wire [4:0] columns;

  // Keyboard matrix
  keyboard_for_ace the_keyboard (
    .clk(clkcpu),
    .ps2_key(ps2_key),
    .rows(rows),
    .columns(columns),
    .kbd_reset(kbd_reset),
    .kbd_nmi(),
    .kbd_mreset()
  );
  
endmodule

