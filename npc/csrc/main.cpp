#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"    //vcd波形
#include "verilated_fst_c.h"    //fst波形
int main(int argc, char** argv){
    //1. 上下文
    VerilatedContext* contextp = new VerilatedContext;  //用于记录仿真时间
    contextp->commandArgs(argc, argv);

    //2. DUT
    Vtop* top = new Vtop{contextp}; //实例化电路

    //3. 波形
    Verilated::traceEverOn(true);   //启用跟踪

    /*
    VerilatedVcdC* tfp = new VerilatedVcdC; //创建vcd波形文件
    */
    VerilatedFstC* tfp = new VerilatedFstC;;//创建fst波形文件
    top->trace(tfp, 99);    //采样深度99
    tfp->open("wave.fst");  //打开波形文件

    uint64_t sim_time=20;
    while (contextp->time() < sim_time && !contextp->gotFinish()) {
        int a = rand() & 1;
        int b = rand() & 1;

        top->a = a;
        top->b = b;

        top->eval();    //更新电路状态

        printf("a = %d, b = %d, f = %d\n", a, b, top->f);
        assert(top->f == (a ^ b));

        tfp->dump(contextp->time());    //采样
        contextp->timeInc(1);   //推动仿真时间
    }
    delete top; //清理top仿真模型
    delete contextp;
    delete tfp;

    tfp->close();   //关闭波形文件

    return 0;
}
