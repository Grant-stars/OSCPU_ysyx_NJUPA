#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "Vtop.h" 
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件


static const uint32_t img [] = {
    0x01400513,         //addi	a0,zero,20
    0x010000e7,         //jalr	ra,16(zero) # 10 <fun>
    0x00c000e7,         //jalr	ra,12(zero) # c <halt>
    0x00100073,         //ebreak
    0x00a50513,         //addi	a0,a0,10
    0x00008067,         //jalr	zero,0(ra)
};


#define MEM_Maxsize (1U<<30)
uint8_t MEM[MEM_Maxsize];
uint32_t pmem_read(uint32_t addr, int len){
    switch (len){
    case 1:
        return (uint32_t)(*(uint8_t*)(MEM+addr));
    case 2:
        return (uint32_t)(*(uint16_t*)(MEM+addr));
    case 4:
        return (uint32_t)(*(uint32_t*)(MEM+addr));
    default:
        assert(0);
        return 0;
    }
}

void pmem_write(uint32_t addr, uint32_t data, int len){
    switch (len)
    {
    case 1:
        *(uint8_t*)(MEM+addr) = (uint8_t)data;
        break;
    case 2:
        *(uint16_t*)(MEM+addr) = (uint16_t)data;
        break;
    case 4:
        *(uint32_t*)(MEM+addr) = (uint32_t)data;
        break;
    default:
        assert(0);
    }
    return ;
}

    bool end;
    bool* end_ptr = &end;

static void single_cycle(Vtop* top, VerilatedFstC* tfp, VerilatedContext* contextp) {
    if(top->l_en) top->l_data=pmem_read(top->addr, top->len);
    
    top->clk = 0; top->eval(); 
    tfp->dump(contextp->time());    //采样
    contextp->timeInc(1);         // 时间+1

    top->clk = 1; top->eval(); 
    top->inst = pmem_read(top->pc, 4); top->eval(); 
    if(top->s_en) pmem_write(top->addr, top->s_data, top->len);
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