#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <inttypes.h>
#include "common.h"

#include "Vtop.h" 
#include "Vtop_top.h" 
#include "Vtop_RegisterFile__A5.h"
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件
							   
VerilatedContext* contextp = new VerilatedContext;
Vtop* top = new Vtop{contextp};
VerilatedFstC* tfp = new VerilatedFstC; //创建一个 Verilator 提供的 FST 波形记录对象

bool end;
bool* end_ptr = &end;
int good = 0;

void init_monitor(int argc, char *argv[]);
void sdb_mainloop(); 
bool scan_wp();


const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

uint32_t reg_read(const char *s, bool *success){
  if(!strcmp(s,"0")){
    *success = true;
    return top->top->GPR->rf[0];
  }
  else if(!strcmp(s,"pc")){
    *success = true;
    return top->pc;    
  }
  for(int i=1; i<32; i++){
    if(!strcmp(s,regs[i])){
      *success = true;
      return top->top->GPR->rf[i];
    }
  }
  *success=false;
  return 0;
}

void reg_display(){

	for(int i =0;i<32;i++){
		printf("%-15s0x%-20" PRIX32 "%-20" PRIu32 "\n",regs[i], top->top->GPR->rf[i],top->top->GPR->rf[i]);
	}
	printf("%-15s0x%-20" PRIX32 "0x%-20" PRIX32 "\n","pc", top->pc, top->pc);
  
}

static void single_cycle() {
    top->clk = 0; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1

    top->clk = 1; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1
}


static void reset(int n) {
    top->rst = 1;
    while (n -- > 0) single_cycle();
    top->rst = 0;
}


int exec_once(){
	single_cycle();
    if(end){
		good = (top->top->GPR->rf[10] == 0);
		if(good){
			printf("HIT GOOD TRAP\n");
		}
		else{
			printf("HIT BAD TRAP\n");
		}
        return 1; 
	}
	else{
		#ifdef CONFIG_WATCHPOINT
			bool trigger = scan_wp();
			if(trigger){
				printf("Program stopped at: 0x%.8x\n", top->pc);
				return 1;
			}
		#endif
		return 0;
	}
}



void cpu_exec(uint64_t n){
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
    top = new Vtop{contextp};

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

    delete top;
    delete contextp; 
    tfp->close();   //关闭波形文件
    delete tfp;  //  清理波形对象
    return (!good);
}
