# Makefile for IFU and Instr_Queue simulation using iverilog and GTKWave

# Compiler and tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
SIM_DIR = ../sim
WAVE_DIR_IFU = ../sim/waves/IFU
WAVE_DIR_INSTR_QUEUE = ../sim/waves/Instr_Queue

# Source files (relative to SIM_DIR)
SOURCES_IFU = $(SIM_DIR)/ifu_tb.v
SOURCES_INSTR_QUEUE = $(SIM_DIR)/Instr_Queue_tb.v

# Output files for IFU
TARGET_IFU = ifu_tb.out
VCD_IFU = ifu_tb.vcd

# Output files for Instr_Queue
TARGET_INSTR_QUEUE = Instr_Queue_tb.out
VCD_INSTR_QUEUE = Instr_Queue_tb.vcd

# Default target: run both simulations
all: ifu instr_queue

# IFU simulation targets
ifu: compile_ifu run_ifu move_ifu 

compile_ifu:
	$(IVERILOG) -o $(TARGET_IFU) $(SOURCES_IFU)

run_ifu:
	$(VVP) $(TARGET_IFU)
	@if [ -f $(VCD_IFU) ]; then mv $(VCD_IFU) $(WAVE_DIR_IFU)/; fi

move_ifu:
	mv $(TARGET_IFU) $(WAVE_DIR_IFU)/$(TARGET_IFU)

wave_ifu:
	$(GTKWAVE) $(WAVE_DIR_IFU)/$(VCD_IFU)

# Instr_Queue simulation targets
instr_queue: compile_instr_queue run_instr_queue move_instr_queue wave_instr_queue

compile_instr_queue:
	$(IVERILOG) -o $(TARGET_INSTR_QUEUE) $(SOURCES_INSTR_QUEUE)

run_instr_queue:
	$(VVP) $(TARGET_INSTR_QUEUE)
	@if [ -f $(VCD_INSTR_QUEUE) ]; then mv $(VCD_INSTR_QUEUE) $(WAVE_DIR_INSTR_QUEUE)/; fi

move_instr_queue:
	mv $(TARGET_INSTR_QUEUE) $(WAVE_DIR_INSTR_QUEUE)/$(TARGET_INSTR_QUEUE)

wave_instr_queue:
	$(GTKWAVE) $(WAVE_DIR_INSTR_QUEUE)/$(VCD_INSTR_QUEUE)

# Clean generated files
clean:
	rm -f $(WAVE_DIR_IFU)/$(TARGET_IFU) $(WAVE_DIR_IFU)/$(VCD_IFU)
	rm -f $(WAVE_DIR_INSTR_QUEUE)/$(TARGET_INSTR_QUEUE) $(WAVE_DIR_INSTR_QUEUE)/$(VCD_INSTR_QUEUE)

# Phony targets
.PHONY: all ifu instr_queue compile_ifu run_ifu move_ifu wave_ifu compile_instr_queue run_instr_queue move_instr_queue wave_instr_queue clean