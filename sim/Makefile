################################################################################
# Makefile to build the ORION_HOME RTL simulator
################################################################################

# Build directory
BUILD_DIR?= build

# Enable debug build
DEBUG?= 0

# Enable SV Assertions
EN_SVASSERT?= 1

# Trace format (vcd/fst)
TRACE_FORMAT?= fst

########################################
include ../common.mk

OBJ_DIR:= 		$(BUILD_DIR)/obj
VERILATED_DIR:= $(BUILD_DIR)/verilated
BIN_DIR:= 		$(BUILD_DIR)/bin

# Create directories
$(shell mkdir -p $(BUILD_DIR) $(OBJ_DIR) $(VERILATED_DIR) $(BIN_DIR))

########################################
# Verilog sources
# VSRCS:= $(wildcard $(ORION_HOME)/rtl/core/*.sv)
# VSRCS+= $(wildcard $(ORION_HOME)/rtl/lib/*.sv)
# VSRCS+= $(wildcard $(ORION_HOME)/rtl/soc/*.sv)
VSRCS:= $(ORION_HOME)/rtl/core/orion_types.sv
VSRCS+= $(ORION_HOME)/rtl/soc/orion_soc_types.sv

VSRCS+= $(ORION_HOME)/rtl/core/orion_core.sv
VSRCS+= $(ORION_HOME)/rtl/core/fetch.sv
VSRCS+= $(ORION_HOME)/rtl/core/decode.sv
VSRCS+= $(ORION_HOME)/rtl/core/regfile.sv
VSRCS+= $(ORION_HOME)/rtl/core/execute.sv
VSRCS+= $(ORION_HOME)/rtl/core/memory.sv
VSRCS+= $(ORION_HOME)/rtl/core/writeback.sv
VSRCS+= $(ORION_HOME)/rtl/soc/orion_soc.sv
VSRCS+= $(wildcard $(ORION_HOME)/rtl/lib/*.sv)

VTOP:= orion_soc

# C++ sources
CXXSRCS:= $(wildcard $(ORION_HOME)/sim/*.cc)

# Verilator options
VC:= verilator
VFLAGS:= --cc -Wall -DSIMULATION --Mdir $(VERILATED_DIR)
VFLAGS+= --top-module $(VTOP)
VFLAGS+= -I$(ORION_HOME)/rtl/common

###################################
# Orion Config
VFLAGS+= -DEN_RV32M_EXT

###################################

# CPP options
CC:= g++
CXXFLAGS:= -std=c++14 -Wall -Wextra -faligned-new -Wno-unused-parameter -Wno-unused-variable -Wno-sign-compare -Wno-array-bounds
CXXFLAGS+= -I$(VERILATED_DIR)
CXXFLAGS+= -I$(VERILATOR_PATH)/share/verilator/include
CXXFLAGS+= -I$(VERILATOR_PATH)/share/verilator/include/vltstd
LDFLAGS:= -L$(VERILATED_DIR) -l:V$(VTOP)__ALL.a -lverilated

# Debugging options
ifeq ($(DEBUG), 1)
	$(info Debug build enabled)
    CXXFLAGS += -g -O0 -DDEBUG
else
    CXXFLAGS += -O2 -DNDEBUG
endif

# SV Assertions
ifeq ($(EN_SVASSERT), 1)
    $(info - SV Assertions enabled)
    VFLAGS += --assert
endif

# Trace format
ifeq ($(TRACE_FORMAT), vcd)
    VFLAGS += --trace
else ifeq ($(TRACE_FORMAT), fst)
    VFLAGS += --trace-fst 
    CXXFLAGS+= -DTRACE_FST
    LDFLAGS += -lz
else
    $(error "Invalid trace format specified. Use 'vcd' or 'fst'.")
endif

VFLAGS += --trace-params --trace-structs --trace-underscore

# Obtain list of object files
OBJS:= $(patsubst %, $(OBJ_DIR)/%, $(notdir $(patsubst %.cc, %.o, $(CXXSRCS))))

# Simulation executable
EXE:= $(BIN_DIR)/orionsim

default: sim
########################################
.PHONY: sim
sim: $(EXE)
	@printf "$(CLR_BL)[+] Orionsim built successfully!$(CLR_NC)\n"

# # EXE <- verilated objs, C++ objs
$(EXE): $(VERILATED_DIR)/V$(VTOP)__ALL.a $(OBJS)
	@printf "$(CLR_BL)[+] Linking $@$(CLR_NC)\n"
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

# Verilation: verilated_objs <- verilog srcs
$(VERILATED_DIR)/V$(VTOP)__ALL.a: $(VSRCS)
	@printf "$(CLR_BL)[+] Generating verilated sources$(CLR_NC)\n"
	$(VC) $(VFLAGS) $^

	@printf "$(CLR_BL)[+] Generating combined header file$(CLR_NC)\n"
	printf "#pragma once\n" > $(VERILATED_DIR)/V$(VTOP)_headers.h
	find $(VERILATED_DIR) -name "*.h" -printf "#include <%P>\n" >> $(VERILATED_DIR)/V$(VTOP)_headers.h

	@printf "$(CLR_BL)[+] Compiling verilated sources$(CLR_NC)\n"
	$(MAKE) -s -C $(VERILATED_DIR) -f V$(VTOP).mk

	
# C++ obj <- C++ src (in current dir)
$(OBJ_DIR)/%.o: %.cc $(VERILATED_DIR)/V$(VTOP)__ALL.a testbench.h
	@printf "$(CLR_BL)[+] Compiling $@$(CLR_NC)\n"
	$(CC) $(CXXFLAGS) -c $< -o $@


.PHONY: iverilog
iverilog: $(VSRCS)
	@printf "$(CLR_BL)[+] Generating iverilog sources$(CLR_NC)\n"
	iverilog -g2012 -o $(BIN_DIR)/orionsim_iverilog $(VSRCS) -I$(ORION_HOME)/rtl/common
 


.PHONY: lint
lint: $(VSRCS)
	$(VC) $(VFLAGS) --lint-only $(VSRCS) && printf "$(CLR_GR)[+] Linting Success$(CLR_NC)\n" || \
	{ printf "$(CLR_RD)[!] Linting failed$(CLR_NC)\n"; exit 1; }


.PHONY: clean
clean:
	@printf "Cleaning up...\n"
	rm -f $(OBJ_DIR)/*
	rm -f $(VERILATED_DIR)/*
	rm -f $(EXE)

