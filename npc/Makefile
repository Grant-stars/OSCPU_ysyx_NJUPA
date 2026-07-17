VERILATOR = verilator
BUILD_DIR = obj_dir
VTOP = $(BUILD_DIR)/Vtop
WAVE_FORMAT = fst
WAVE_FILE = wave.$(WAVE_FORMAT)
CHECKFLAGS = --lint-only -Wall

# NVBOARD makefile

TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=  ../nvboard/usr/include

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert

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
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I , $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

# 当run把$(BIN)当作依赖时，Makefile 会递归解析这个依赖：发现它
# 是「有规则的目标」→ 自动执行其编译规则，完成文件的创建 / 更新，
# 直到$(BIN)变成「符合状态要求的文件」。紧接着由于伪目标，所以命令$(BIN)
# 一定会执行，即执行Vtop

run: $(BIN)
	@$^


all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	$(VERILATOR) --cc --exe --build -j 0 -Wall --trace-$(WAVE_FORMAT) ./csrc/main.cpp ./vsrc/top.v --Mdir $(BUILD_DIR)
	./$(VTOP)
	gtkwave $(WAVE_FILE)

check: $(VSRCS)
	$(VERILATOR) $(CHECKFLAGS) $(VSRCS) 

clean:
	rm -r ./$(BUILD_DIR)
	rm wave.*

.PHONY: all sim clean  default run check

include ../Makefile
