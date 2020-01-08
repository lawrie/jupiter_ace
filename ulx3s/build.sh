#!/bin/sh

# Build Jupiter Ace system for ULX3S board

# synthesise design
# generates warnings, but these are okay
yosys -q -p "synth_ecp5 -json ace.json" ../src/jupiter_ace_ulx3s.v ../src/fpga_ace.v ../src/jace_logic.v	\
    ../src/memorias.v ../src/keyboard_for_ace.v ../src/ps2_port.v ../src/hdmi.v	../src/tv80n.v ../src/tv80_core.v \
    ../src/tv80_alu.v ../src/tv80_reg.v ../src/tv80_mcode.v ../src/clk_25_system.v

# place & route
# assumes 25F device
nextpnr-ecp5 --25k --package CABGA381 --json ace.json --lpf ulx3s_ace.lpf --textcfg ace.cfg

# pack bitstream
# idcode only needed when sending bitstream to 12F devices
ecppack  ace.cfg ace.bit --idcode 0x21111043

# send to ULX3S board (store in configuration RAM)
ujprog ace.bit