#include "include/cpu.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include "common.h"
extern uint8_t MEM[];
extern bool* end_ptr;
extern bool exception;
extern CPU_state cpu;
#define CONFIG_MBASE      0x80000000

#define CLOCK_ADDR        0x02000000
#define RTC_ADDR          0x02000000
#define UPTIME_ADDR       (CLOCK_ADDR + 8)
#define SERIAL_PORT       0x10000000

#define SHIFTMASK(n) ({ (wmask >> n)&(0x1u)? (0b11111111)<<(n*8) : 0x0; })
#define MASK(wmask) ({ SHIFTMASK(0) | SHIFTMASK(1) | SHIFTMASK(2) | SHIFTMASK(3); })

extern uint64_t memory_access;
extern uint64_t function_trace;
extern bool is_skip_ref;

uint32_t vaddr_read(uint32_t addr);
void vaddr_write(int waddr, int wdata, char wmask);
void is_out_of_bound(uint32_t addr); 

static struct tm local_time;
uint64_t boot_time = 0;

void get_local_time(){
    time_t t = time(NULL);
    struct tm* tm = localtime(&t);
    local_time.tm_sec = tm->tm_sec;
    local_time.tm_min = tm->tm_min;
    local_time.tm_hour = tm->tm_hour;
    local_time.tm_mday = tm->tm_mday;
    local_time.tm_mon = tm->tm_mon + 1;
    local_time.tm_year = tm->tm_year + 1900;
}



uint64_t get_time_internal(){
    
    struct timeval now;
    gettimeofday(&now, NULL);
    uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
    return us;
    /*
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
    uint64_t us = now.tv_sec * 1000000 + now.tv_nsec / 1000;
    */
    return us;
}

uint64_t get_time(){
    if(boot_time == 0)  boot_time = get_time_internal();
    uint64_t now = get_time_internal();
    return now - boot_time;
}


int pmem_read(volatile int raddr) {
	#ifdef CONFIG_MTRACE
		log_write("memory read from addr: 0x%.8x\n", raddr); 
		memory_access++;
	#endif 
    // 总是读取地址为`raddr & ~0x3u`的4字节返回

	//读取设备时，difftest执行结果以dut的状态为准
    //串口
    if(raddr==SERIAL_PORT) { is_skip_ref = true; return 0; }
    //时钟
    if(raddr>=RTC_ADDR && raddr<=RTC_ADDR+0xffff){
		is_skip_ref = true;

        //对于RTC(Real Time Clock)，约定设备方面提供两个寄存器
            //RTC_ADDR: day<<24 | hour<<16 | minute<<8 | second
            //RTC_ADDR+4: year<<16 | month
        if(raddr==RTC_ADDR) { get_local_time(); return (local_time.tm_mday<<24 | local_time.tm_hour<<16 | local_time.tm_min<<8 | local_time.tm_sec); }
        if(raddr==RTC_ADDR+4) { get_local_time(); return (local_time.tm_year<<16 | local_time.tm_mon);}

        // AM_TIMER_UPTIME
        if(raddr==UPTIME_ADDR) { uint64_t us = get_time(); return (uint32_t)us; }
        if(raddr==UPTIME_ADDR+4){ uint64_t us = get_time(); return us>>32; }
    }
	is_out_of_bound(raddr & ~0x3u);
    return *(int*)(MEM+(raddr & ~0x3u)-CONFIG_MBASE);
}

void pmem_write(int waddr, int wdata, char wmask) {

	#ifdef CONFIG_MTRACE
		log_write("memory write to addr: 0x%.8x with wdata=0x%.8x, wmask=0x%x\n", waddr & ~0x3u, (uint32_t)wdata, wmask); 
		memory_access++;
	#endif
	// 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
    // `wmask`中每比特表示`wdata`中1个字节的掩码,
    // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变 

	//写设备时，difftest执行结果以dut的状态为准
    //串口
    if(waddr==SERIAL_PORT) { is_skip_ref = true; putchar((char)(uint32_t)wdata); return; }
    //时钟
    if(waddr>=RTC_ADDR && waddr<=RTC_ADDR+0xffff) { is_skip_ref = true; return;}
	is_out_of_bound(waddr & ~0x3u);

    uint32_t raw_data = *(uint32_t*)(MEM+(waddr & ~0x3u)-CONFIG_MBASE);
;
    uint32_t mask = MASK(wmask);
    uint32_t new_data = ((uint32_t)wdata & mask) | (raw_data & (~mask));
    *(uint32_t*)(MEM+(waddr & ~0x3u)-CONFIG_MBASE) = new_data;
    return ;
}


void finish(){
    *end_ptr = true;
    return;
}

void unimplement(){
	CPU_update();
	printf(ANSI_FMT("The instruction 0x%.8x: 0x%.8x is not implemented.\n", ANSI_FG_RED), cpu.pc, pmem_read(cpu.pc));
	exception =  true;
	return ;
}
