#include "common.h"

uint8_t MEM[CONFIG_MSIZE];
#define CLOCK_ADDR        0x02000000
#define RTC_ADDR          0x02000000
#define UPTIME_ADDR       (CLOCK_ADDR + 8)
#define SERIAL_PORT       0x10000000



uint32_t vaddr_read(uint32_t addr){
	// 总是读取地址为`addr & ~0x3u`的4字节返回

    //串口
    if(addr==SERIAL_PORT) { return 0; }
    //时钟
    if(addr>=RTC_ADDR && addr<=RTC_ADDR+0xffff){
		printf("TODO\n");
    }

    return *(int*)(MEM+(addr & ~0x3u)-CONFIG_MBASE);

}


