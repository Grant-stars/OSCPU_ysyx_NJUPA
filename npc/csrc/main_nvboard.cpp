#include "Vtop.h"
#include <nvboard.h>
#include "verilated_fst_c.h"  

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

static VerilatedFstC* tfp;

static void single_cycle() {
    dut.clk = 0; dut.eval();
    tfp->dump(Verilated::time());   // 采样
    Verilated::timeInc(1);          // 时间+1

    dut.clk = 1; dut.eval();
    tfp->dump(Verilated::time());   // 采样
    Verilated::timeInc(1);          // 时间+1

}

static void reset(int n) {
    dut.rst = 1;
    while (n -- > 0) single_cycle();
    dut.rst = 0;
}

int main(int argc, char** argv){

//生成波形初始化
Verilated::traceEverOn(true);   //启用波形跟踪
tfp = new VerilatedFstC;//创建fst波形文件
dut.trace(tfp, 99);    //采样深度99
tfp->open("build/wave.fst");  //打开波形文件

    nvboard_bind_all_pins(&dut);
    nvboard_init();

    reset(10);

    while (1) {
        nvboard_update();
        single_cycle();
    }
    tfp->close();
    return 0;
}