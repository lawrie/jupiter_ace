DEVICE ?= 85k
PIN_DEF ?= ulx3s_v20.lpf

BUILDDIR = bin

compile: $(BUILDDIR)/toplevel.bit

prog: $(BUILDDIR)/toplevel.bit
	ujprog $^

$(BUILDDIR)/toplevel.json: $(VERILOG)
	mkdir -p $(BUILDDIR)
	yosys -p "synth_ecp5 -top jupiter_ace -json $@" $^

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/toplevel.json
	 nextpnr-ecp5 --${DEVICE} --package CABGA381 --freq 25 --textcfg  $@ --json $(filter-out $<,$^) --lpf $< 

$(BUILDDIR)/toplevel.bit: $(BUILDDIR)/toplevel.config
	ecppack --compress $^ $@

clean:
	rm -rf ${BUILDDIR}

.SECONDARY:
.PHONY: compile clean prog
