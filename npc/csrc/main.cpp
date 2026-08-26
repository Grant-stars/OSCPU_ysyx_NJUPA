#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h>

#include "Vtop.h" 
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件
							   
VerilatedContext* contextp = new VerilatedContext;
Vtop* top = new Vtop{contextp};
VerilatedFstC* tfp = new VerilatedFstC; //创建一个 Verilator 提供的 FST 波形记录对象

bool end;
bool* end_ptr = &end;
int good = 0;

#define mem_halt 0x1218
#define sum_halt 0x224

void init_monitor(int argc, char *argv[]);
void sdb_mainloop(); 

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
            good = (top->rf10 == 0);
            if(good){
                printf("HIT GOOD TRAP\n");
            }
            else{
                printf("HIT BAD TRAP\n");
            }
            return 1; 
        }
		else{
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
