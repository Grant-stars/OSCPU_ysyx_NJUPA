#include <cstdint>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <inttypes.h>
#include "common.h"
#include "include/cpu.h"

#include "VysyxSoCFull.h" 
#include "VysyxSoCFull_ysyxSoCFull.h" 
#include "VysyxSoCFull_ysyxSoCASIC.h" 
#include "VysyxSoCFull_CPU.h" 
#include "VysyxSoCFull_ysyx_26070215.h" 
#include "VysyxSoCFull_ysyx_26070215_RegisterFile__A5.h"
#include "VysyxSoCFull_ysyx_26070215_inst_decode.h"
#include "VysyxSoCFull_ysyx_26070215_inst_fetch.h"
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件

VerilatedContext* contextp = new VerilatedContext;
VysyxSoCFull* top = new VysyxSoCFull{contextp};
VerilatedFstC* tfp = new VerilatedFstC; //创建一个 Verilator 提供的 FST 波形记录对象

bool end;
bool* end_ptr = &end;
bool exception = false;
int good = 0;
bool g_print_step = false;
uint64_t g_nr_guest_inst = 0;
extern char log_buf[128];

void init_monitor(int argc, char *argv[]);
void sdb_mainloop(); 
bool scan_wp();
void disasm(uint32_t pc, uint32_t instruction);
void free_elf_table();
void func_check(int jump, int rs1, int rd, uint32_t pc, uint32_t npc);
void difftest_step(uint32_t pc, uint32_t npc); 

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

CPU_state cpu;

void CPU_update(){
	for(int i=0; i<32; i++){
		cpu.gpr[i] = top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[i];
	}
	cpu.pc = top->ysyxSoCFull->asic->cpu->cpu->pc;
}

void CPU_reset(){
	for(int i=0; i<32; i++){
		cpu.gpr[i] = 0;
	}
	cpu.pc = MROM_BASE;
}

uint32_t reg_read(const char *s, bool *success){
  if(!strcmp(s,"0")){
    *success = true;
    return top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[0];
  }
  else if(!strcmp(s,"pc")){
    *success = true;
    return top->ysyxSoCFull->asic->cpu->cpu->pc;    
  }
  for(int i=1; i<32; i++){
    if(!strcmp(s,regs[i])){
      *success = true;
      return top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[i];
    }
  }
  *success=false;
  return 0;
}

void reg_display(){

	for(int i =0;i<32;i++){
		printf("%-15s0x%-20" PRIX32 "%-20" PRIu32 "\n",regs[i], top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[i],top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[i]);
	}
	printf("%-15s0x%-20" PRIX32 "0x%-20" PRIX32 "\n","pc", top->ysyxSoCFull->asic->cpu->cpu->pc, top->ysyxSoCFull->asic->cpu->cpu->pc);
  
}

bool reg_check(CPU_state *ref_r, uint32_t pc){
	CPU_update();
	for(int i=0; i<32; i++){
		if(cpu.gpr[i]!=ref_r->gpr[i]){
			printf(ANSI_FMT("npc.gpr[%d]: 0x%.8x, ref.gpr[%d]: 0x%.8x\n", ANSI_FG_RED), i, cpu.gpr[i], i, ref_r->gpr[i]);
			return false;
		}
	}	
	if(cpu.pc!=ref_r->pc){
		printf(ANSI_FMT("npc.pc: 0x%.8x, ref.pc: 0x%.8x\n", ANSI_FG_RED), cpu.pc, ref_r->pc);
		return false;
	}
	return true;
}

void trace_and_difftest(uint32_t pc, uint32_t inst, uint32_t npc){
	static uint8_t inst_finish= 0;
	uint8_t inst_finish_reg = inst_finish;
	inst_finish = top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_IFU->inst_finish;
	if(!inst_finish_reg) return ;
#ifdef CONFIG_ITRACE
	disasm(pc, inst);
	log_write("%s\n", log_buf); 
	if(g_print_step) {puts(log_buf);} 
#endif
#ifdef CONFIG_FTRACE
	func_check(top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_IDU->jump, top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_IDU->rs1, top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_IDU->rd, pc, top->ysyxSoCFull->asic->cpu->cpu->pc);
#endif
  IFDEF(CONFIG_DIFFTEST, difftest_step(pc, npc));
}


static void single_cycle() {
    top->clock = 0; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1

    top->clock = 1; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1
}


static void reset(int n) {
    top->reset = 1;
    while (n -- > 0) single_cycle();
    top->reset = 0;
}


int exec_once(){
	uint32_t trace_pc=top->ysyxSoCFull->asic->cpu->cpu->pc;
	uint32_t trace_inst=top->ysyxSoCFull->asic->cpu->cpu->inst;
	single_cycle();
	g_nr_guest_inst++;
	trace_and_difftest(trace_pc, trace_inst, top->ysyxSoCFull->asic->cpu->cpu->pc);
	if(exception){
		end=true;
		return 1;
	}
	else if(end){
		good = (top->ysyxSoCFull->asic->cpu->cpu->ysyx_26070215_GPR->rf[10] == 0);
		
		if(good){
			printf("%s\n", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN));
		}
		else{
			printf("%s\n", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED));
		}
        return 1; 
	}
	else{
		#ifdef CONFIG_WATCHPOINT
			bool trigger = scan_wp();
			if(trigger){
				printf("Program stopped at: 0x%.8x\n", top->ysyxSoCFull->asic->cpu->cpu->pc);
				return 1;
			}
		#endif
		return 0;
	}
}


void cpu_exec(uint64_t n){
	if(end){
		printf("Program execution has ended\n");
		return ;
	}
	g_print_step = (n < 10);
	while(n-->0){
		if(exec_once()){
			break;
		}
	}
};


int main(int argc, char** argv) {

    //初始化仿真模型
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    top = new VysyxSoCFull{contextp};

	Verilated::commandArgs(argc, argv);
    //初始化波形跟踪
    contextp->traceEverOn(true);  //开启波形跟踪
    tfp = new VerilatedFstC; //创建一个 Verilator 提供的 FST 波形记录对象
    top->trace(tfp, 99);    //采样深度99
    tfp->open("build/wave.fst");  //打开波形文件

    //初始化sdb
    init_monitor(argc, argv);

    //运行仿真
    reset(10);
    end = false;
	sdb_mainloop();

	IFDEF(CONFIG_FTRACE, free_elf_table());
    delete top;
    delete contextp; 
    tfp->close();   //关闭波形文件
    delete tfp;  //  清理波形对象
    return (!good);
}
