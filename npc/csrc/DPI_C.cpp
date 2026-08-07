#include "svdpi.h"
#include "Vtop__Dpi.h"
#include <assert.h>
#include <stdio.h>
extern uint8_t MEM[];
extern bool* end_ptr;

#define SHIFTMASK(n) ({ (wmask >> n)&(0x1u)? (0b11111111)<<(n*8) : 0x0; })
#define MASK(wmask) ({ SHIFTMASK(0) | SHIFTMASK(1) | SHIFTMASK(2) | SHIFTMASK(3); })


int pmem_read(int raddr) {
    // 总是读取地址为`raddr & ~0x3u`的4字节返回
    return *(int*)(MEM+(raddr & ~0x3u));
}
void pmem_write(int waddr, int wdata, char wmask) {
    // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
    // `wmask`中每比特表示`wdata`中1个字节的掩码,
    // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变 
    uint32_t raw_data = pmem_read(waddr);
    uint32_t mask = MASK(wmask);
    uint32_t new_data = ((uint32_t)wdata & mask) | (raw_data & (~mask));
    *(uint32_t*)(MEM+(waddr & ~0x3u)) = new_data;
    return ;
}


void finish(){
    *end_ptr = true;
    return;
}
