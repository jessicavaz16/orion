include ../../common.mk

# Override these variables 
BUILD_DIR?= build
SRCS?= 
EXEC?= a.elf
TRACE?= 
LOG?=

################################################################################
RVPREFIX := riscv64-unknown-elf
CFLAGS += -Wall -O0
CFLAGS += -march=rv32im -mabi=ilp32 -nostartfiles -ffreestanding -I ../include
LFLAGS := -T $(ORION_HOME)/sw/lib/link/link.ld -Wl,-Map=$(BUILD_DIR)/$(basename $(EXEC)).map

SRCS += $(ORION_HOME)/sw/lib/start.S

ORIONSIM_FLAGS?= 
ifeq ($(TRACE), 1)
    # Get the trace format from simulator
    ORIONSIM_TRACE_TYPE:= $(shell orionsim --help | grep -oP 'Trace type:\s*\K\w+' | tr '[:upper:]' '[:lower:]')
    ORIONSIM_FLAGS += -t --trace-file $(ORION_HOME)/trace.$(ORIONSIM_TRACE_TYPE)
endif

ifeq ($(LOG), 1)
    ORIONSIM_FLAGS += --log $(ORION_HOME)/sim.log
endif

SPIKE_FLAGS := --isa=rv32im -m0x10000:0x10000

default: build

################################################################################
# build: Builds the program
################################################################################
.PHONY: build
build: $(BUILD_DIR)/$(EXEC)

$(BUILD_DIR)/$(EXEC): $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(RISCV_TOOLCHAIN_PREFIX)gcc $(CFLAGS) $^ -o $@ $(LFLAGS)
	$(RISCV_TOOLCHAIN_PREFIX)objdump -dt $@ > $(basename $@).lst
	$(RISCV_TOOLCHAIN_PREFIX)objcopy -O binary $@ $(basename $@).bin
	xxd -e -c 4 $(basename $@).bin | awk '{print $$2}' > $(basename $@).hex


################################################################################
# run: Runs the program on Orionsim
################################################################################
.PHONY: run
run: $(BUILD_DIR)/$(EXEC)
	@echo "Running $(EXEC)"
	orionsim $(ORIONSIM_FLAGS) $(basename $<).hex


################################################################################
# run-verif: Runs the program on both Spike and Orionsim, and compares the logs.
################################################################################
# SPIKE_LOG := $(BUILD_DIR)/spike.log
# ORIONSIM_LOG := $(BUILD_DIR)/orionsim.log
# DIFF_FILE := $(BUILD_DIR)/run.diff


.PHONY: run-verif
run-verif: $(BUILD_DIR)/$(EXEC)
	@echo "Running $(EXEC) on Spike and Orionsim"
	bash $(ORION_HOME)/scripts/spike_verif.sh --elf $(BUILD_DIR)/$(EXEC) --build-dir $(BUILD_DIR) \
		--spike-flags "$(SPIKE_FLAGS)" \
		--orionsim-flags "$(ORIONSIM_FLAGS)"

# spike --isa=rv32i -m0x10000:0x10000 --log-commits $(BUILD_DIR)/$(EXEC) 2>&1 | tail -n +6 > $(SPIKE_LOG)
# orionsim $(ORIONSIM_FLAGS) --log $(ORIONSIM_LOG) --log-format spike $(basename $<).hex || true
	

################################################################################
# clean: Cleans the build directory
################################################################################
.PHONY: clean
clean:
	rm -f $(BUILD_DIR)/*