#include "svdpi.h"
#include "Vtop__Dpi.h"
#include <assert.h>
#include <stdio.h>
extern uint8_t MEM[];
extern bool* end_ptr;

int pmem_read(int raddr) {
    // 总是读取地址为`raddr & ~0x3u`的4字节返回
    return *(int*)(MEM+(raddr & ~0x3u));
}
void pmem_write(int waddr, int wdata, char wmask) {
    // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
    // `wmask`中每比特表示`wdata`中1个字节的掩码,
    // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
    switch(wmask){
        case(0x1): 
            *(uint8_t*)(MEM+(waddr & ~0x3u)) = (uint8_t)wdata;
            break;
        case(0x3): 
            *(uint16_t*)(MEM+(waddr & ~0x3u)) = (uint16_t)wdata;
            break;
        case(0xf):
            *(uint32_t*)(MEM+(waddr & ~0x3u)) = (uint32_t)wdata;
            break;
        default: assert(0);
        
    }
    return ;
}


void finish(){
    *end_ptr = true;
    return;
}
