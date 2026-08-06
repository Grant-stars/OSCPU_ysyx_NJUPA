#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "Vtop.h" 
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件


static const uint32_t img [] = {
    0x01400513,         //addi	a0,zero,20
    0x00A505B3,         //add   a1,a0,a0
    0x00a50513,         //addi	a0,a0,10
    0x00100073,         //ebreak
    /*
    0x01400513,         //addi	a0,zero,20
    0x010000e7,         //jalr	ra,16(zero) # 10 <fun>
    0x00c000e7,         //jalr	ra,12(zero) # c <halt>
    0x00100073,         //ebreak
    0x00a50513,         //addi	a0,a0,10
    0x00008067,         //jalr	zero,0(ra)
    */
};

#define MEM_Maxsize (1U<<30)
uint8_t MEM[MEM_Maxsize];

bool end;
bool* end_ptr = &end;

static void single_cycle(Vtop* top, VerilatedFstC* tfp, VerilatedContext* contextp) {
    top->clk = 0; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1

    top->clk = 1; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1
}


static void reset(Vtop* top, VerilatedFstC* tfp, VerilatedContext* contextp, int n) {
    top->rst = 1;
    while (n -- > 0) single_cycle(top, tfp, contextp);
    top->rst = 0;
}

int main(int argc, char** argv) {

    //初始化仿真模型
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vtop* top = new Vtop{contextp};

    //初始化波形跟踪
    contextp->traceEverOn(true);  //开启波形跟踪
    VerilatedFstC* tfp = new VerilatedFstC; //创建一个 Verilator 提供的 FST 波形记录对象
    top->trace(tfp, 99);    //采样深度99
    tfp->open("build/wave.fst");  //打开波形文件

    //读取客户程序
    memcpy(MEM, img, sizeof(img));

    //运行仿真
    reset(top, tfp, contextp, 10);
    end = false;
    while (1){ 
        single_cycle(top, tfp, contextp);
        if(end) break;
    }

    delete top;
    delete contextp; 
    tfp->close();   //关闭波形文件
    delete tfp;  //  清理波形对象
    return 0;
}