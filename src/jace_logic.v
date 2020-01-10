`timescale 1ns / 1ps
`default_nettype none

module jace_logic (
    input wire clk,
    // CPU interface
    input wire [15:0] cpu_addr,
    input wire mreq_n,
    input wire iorq_n,
    input wire rd_n,
    input wire wr_n,
    input wire [7:0] data_from_cpu,
    output reg [7:0] data_to_cpu,
    output reg data_to_cpu_oe,
    output reg wait_n,
    output wire int_n,
    // CPU-RAM interface
    output reg rom_enable,
    output reg sram_enable,
    output reg cram_enable,
    output reg uram_enable,
    output reg xram_enable,
    output reg eram_enable,
    // Screen RAM and Char RAM interface
    output wire [9:0] screen_addr,
    input wire [7:0] screen_data,
    output wire [9:0] char_addr,
    input wire [7:0] char_data,
    // Devices
    input wire [4:0] kbdcols,
    input wire ear,
    output reg spk,
    output reg mic,
    output wire video,
    output wire hsync_vga,
    output wire vsync_vga,
    output wire blank_vga
    );
    
    initial begin
        wait_n = 1'b1;
        spk = 1'b0;
        mic = 1'b0;
    end
    
    reg  [9:0]  cntpix = 9'd0;
    reg  [9:0]  cntscn = 9'd0;
    wire [19:0] cnt = {cntscn, cntpix};
	 
    always @(posedge clk) begin
        if (cntpix != 10'd799)
            cntpix <= cntpix + 10'd1;
        else begin
            cntpix <= 10'd0;
            if (cntscn != 10'd524)
                cntscn <= cntscn + 10'd1;
            else
                cntscn <= 10'd0;
        end
    end
    
    reg vsync; // FIELD signal in schematic
    always @* begin
        vsync = !(cntscn > 10'd489 && cntscn < 10'd492);
    end
    assign int_n = vsync;
    
    reg hsync; // LINE signal in schematic
    always @* begin
        hsync = !(cntpix > 10'd655 && cntpix < 10'd752);
    end
    
    assign hsync_vga = hsync;
    assign vsync_vga = vsync;
    
    reg viden; // VIDEN signal in schematic
    always @* begin
        viden = (cntpix >= 10'd0 && cntpix <= 10'd511 && 
                 cntscn >= 10'd0 && cntscn <= 10'd383);
    end
    wire blank_vga  = !((cntpix<640) && (cntscn<480));
    
    // SHIFT/LOAD signal to 74LS166
    reg shiftload;
    always @* begin
        shiftload = (cnt[3:0] == 3'b0000 && viden == 1'b1);
    end
    
    assign screen_addr = {cnt[18:14], cnt[8:4]};
    assign char_addr = {screen_data[6:0], cnt[13:11]};
        
    // 74LS166
    reg [7:0] shiftreg = 8'h00;
    always @(posedge clk) begin
        if (shiftload)
            shiftreg <= char_data;
        else if (!cnt[0])
            shiftreg <= {shiftreg[6:0], 1'b0};
    end
    
    // Pixel inverter reg and video output stage
    reg pixinverter = 1'b0;
    always @(posedge clk) begin
        if (cnt[2:0] == 4'b0000)
            pixinverter <= viden & screen_data[7];
    end
    
    assign video = shiftreg[7] ^ pixinverter;

    // Address decoder
    reg fast_access;
    always @* begin
        rom_enable = 1'b0;
        sram_enable = 1'b0;
        cram_enable = 1'b0;
        uram_enable = 1'b0;
        xram_enable = 1'b0;
        eram_enable = 1'b0;
        fast_access = 1'b1;
        if (mreq_n == 1'b0) begin
            if (cpu_addr >= 16'h0000 && cpu_addr <= 16'h1FFF)
                rom_enable = 1'b1;
            else if (cpu_addr >= 16'h2000 && cpu_addr <= 16'h27FF) begin
                sram_enable = 1'b1;
                if (cpu_addr >= 16'h2400 && cpu_addr <= 16'h27FF)
                    fast_access = 1'b0;
            end
            else if (cpu_addr >= 16'h2800 && cpu_addr <= 16'h2FFF) begin
                cram_enable = 1'b1;
                if (cpu_addr >= 16'h2C00 && cpu_addr <= 16'h2FFF)
                    fast_access = 1'b0;
            end
            else if (cpu_addr >= 16'h3000 && cpu_addr <= 16'h3FFF)
                uram_enable = 1'b1;
            else if (cpu_addr >= 16'h4000 && cpu_addr <= 16'h7FFF)
                xram_enable = 1'b1;
            else
                eram_enable = 1'b1;
        end
    end
    
    // CPU arbitration to share memory with video generator
    always @(posedge clk) begin
        if ((sram_enable == 1'b1 || cram_enable == 1'b1) && viden == 1'b1 && fast_access == 1'b0)
            wait_n <= 1'b0;
        else if (viden == 1'b0)
            wait_n <= 1'b1;
    end
    
    // IO devices
    always @* begin
        data_to_cpu_oe = 1'b0;
        data_to_cpu = {2'b11, ear, kbdcols};
        if (iorq_n == 1'b0 && cpu_addr[0] == 1'b0 && rd_n == 1'b0) begin
            data_to_cpu_oe = 1'b1;
        end
    end    
    
    always @(posedge clk) begin
        if (iorq_n == 1'b0 && cpu_addr[0] == 1'b0) begin
            if (rd_n == 1'b0 && wr_n == 1'b1)
                spk <= 1'b0;
            else if (rd_n == 1'b1 && wr_n == 1'b0)
                spk <= 1'b1;
            if (wr_n == 1'b0)
                mic <= data_from_cpu[3];
        end
    end
endmodule
