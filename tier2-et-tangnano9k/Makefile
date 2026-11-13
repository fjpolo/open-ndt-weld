# ==============================================================================
# Open-Source Toolchain Makefile for Sipeed Tang Nano 9K (GW1NR-9C)
# Requires OSS CAD Suite (yosys, nextpnr-himbaechel / nextpnr-gowin, gowin_pack, openFPGALoader)
# ==============================================================================

PROJECT  := et_inspector
TOP      := top
DEVICE   := GW1NR-LV9QN88PC6/I5
FAMILY   := GW1N-9C
CST      := constraints/tangnano9k.cst
SRCS     := src/top.v src/nco_100khz.v src/spi_adc_reader.v src/iq_demodulator.v
BUILD    := build

all: $(BUILD)/$(PROJECT).fs

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/$(PROJECT).json: $(SRCS) | $(BUILD)
	yosys -p "read_verilog $(SRCS); synth_gowin -top $(TOP) -json $@"

$(BUILD)/$(PROJECT)_pnr.json: $(BUILD)/$(PROJECT).json $(CST)
	nextpnr-himbaechel --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST)

$(BUILD)/$(PROJECT).fs: $(BUILD)/$(PROJECT)_pnr.json
	gowin_pack -d $(FAMILY) -o $@ $<

flash: $(BUILD)/$(PROJECT).fs
	openFPGALoader -b tangnano9k -f $<

load: $(BUILD)/$(PROJECT).fs
	openFPGALoader -b tangnano9k $<

clean:
	rm -rf $(BUILD)

.PHONY: all flash load clean

