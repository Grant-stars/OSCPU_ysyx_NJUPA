#include "common.h"
#include "include/cpu.h"

uint8_t MEM[CONFIG_MSIZE];
#define CLOCK_ADDR        0x02000000
#define RTC_ADDR          0x02000000
#define UPTIME_ADDR       (CLOCK_ADDR + 8)
#define SERIAL_PORT       0x10000000
uint8_t MROM[MROM_SIZE];

extern CPU_state cpu;

uint8_t* guest_to_host(uint32_t paddr) { return MEM + paddr - CONFIG_MBASE; }
uint8_t* mrom_to_host(uint32_t paddr) { return MROM + paddr - MROM_BASE; }

void is_out_of_bound(uint32_t addr) {
	CPU_update();
	if(likely(addr >= PMEM_LEFT && addr <= PMEM_RIGHT)){
		return ;
	}
	panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc); 
}


uint32_t vaddr_read(uint32_t addr){
	// 总是读取地址为`addr & ~0x3u`的4字节返回

    //串口
    if(addr==SERIAL_PORT) { return 0; }
    //时钟
    if(addr>=RTC_ADDR && addr<=RTC_ADDR+0xffff){
		printf("TODO\n");
    }

    return *(int*)guest_to_host(addr & ~0x3u);

}


