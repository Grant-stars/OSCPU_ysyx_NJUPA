VERILATOR = verilator
BUILD_DIR = obj_dir
VTOP = $(BUILD_DIR)/Vtop
WAVE_FORMAT = fst
WAVE_FILE = wave.$(WAVE_FORMAT)


all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	$(VERILATOR) --cc --exe --build -j 0 -Wall --trace-$(WAVE_FORMAT) ./csrc/main.cpp ./vsrc/top.v --Mdir $(BUILD_DIR)
	./$(VTOP)
	gtkwave $(WAVE_FILE)

test:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	$(VERILATOR) --cc --exe --build -j 0 -Wall --trace-$(WAVE_FORMAT) ./csrc/main.cpp ./vsrc/top.v --Mdir $(BUILD_DIR)
	./$(VTOP)
	gtkwave $(WAVE_FILE)

clean:
	rm -r ./$(BUILD_DIR)
	rm wave.*

.PHONY: all sim clean test

include ../Makefile
