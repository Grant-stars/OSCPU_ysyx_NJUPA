WAVE_FORMAT = fst
WAVE_FILE = wave.$(WAVE_FORMAT)

NPC_CHECKFLAGS = --lint-only -Wall 
SOC_CHECKFLAGS = --lint-only $(INCFLAGS) --top-module $(TOPNAME) --timescale "1ns/1ns" --no-timing

TOPNAME = ysyxSoCFull
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --autoflush \
				--CFLAGS "-ggdb -O0" --timescale "1ns/1ns" --no-timing	

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# 依据nxdc文件生存生成绑定引脚C++文件
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
NPC_VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS = $(NPC_VSRCS)
VSRCS += $(shell find $(abspath ../ysyxSoC/perip) -name "*.v")
VSRCS += $(shell find $(abspath ../ysyxSoC/build/ysyxSoCFull.v) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")


# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lreadline


#rules for capstone
CAPSTONE_INC=$(abspath csrc/tools/capstone/repo/include)
CXXFLAGS += -I$(CAPSTONE_INC)
CAPSTONE_SO=$(abspath csrc/tools/capstone/repo/libcapstone.so.5)
CXXFLAGS += -DCAPSTONE_SO_PATH=\"$(CAPSTONE_SO)\"


# rules for difftest
DIFF_REF_PATH = $(NPC_HOME)/csrc/tools/nemu-diff
DIFF_REF_SO = $(DIFF_REF_PATH)/riscv32-nemu-interpreter-so
ARGS_DIFF = --diff=$(DIFF_REF_SO)
override ARGS += $(ARGS_DIFF)

# 如果启用NVBoard， 需传入NVBOARD=1
NVBOARD?=
ifneq ($(NVBOARD),)
  $(info # Enable NVBoard)
  NXDC_FILES = constr/top.nxdc
  INC_PATH ?=  ../nvboard/usr/include
  # rules for NVBoard
  include $(NVBOARD_HOME)/scripts/nvboard.mk
  CSRCS += $(SRC_AUTO_BIND)
  CSRCS:=$(filter-out %main.cpp, $(CSRCS))

else
  $(info # Disable NVBoard)
  CSRCS:=$(filter-out %main_nvboard.cpp, $(CSRCS))
endif

INC_PATH += ../ysyxSoC/perip/uart16550/rtl
INC_PATH += ../ysyxSoC/perip/spi/rtl
VERILATOR_CFLAGS += $(INCFLAGS)

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) --trace-$(WAVE_FORMAT)\
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

# 当run把$(BIN)当作依赖时，Makefile 会递归解析这个依赖：发现它
# 是「有规则的目标」→ 自动执行其编译规则，完成文件的创建 / 更新，
# 直到$(BIN)变成「符合状态要求的文件」。紧接着由于伪目标，所以命令$(BIN)
# 一定会执行，即执行VysyxSoCFull

run: $(BIN)
	@$^


all: 
	@echo "Write this Makefile by your self."

NPC_EXEC := $(BIN) $(ARGS) $(IMG) 

sim: $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(VERILATOR_CFLAGS) --trace-$(WAVE_FORMAT) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	$(NPC_EXEC)



check: $(VSRCS)
	@echo "checking npc: "
	$(VERILATOR) $(NPC_CHECKFLAGS) $(NPC_VSRCS) 
	@echo "checking soc: "
	$(VERILATOR) $(SOC_CHECKFLAGS) $(VSRCS) 

clean:
	rm -rf ./$(BUILD_DIR)
	rm -f wave.*

.PHONY: all sim clean  default run check

include ../Makefile
