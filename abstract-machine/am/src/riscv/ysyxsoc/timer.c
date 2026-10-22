#include <am.h>
#include <ysyxsoc.h>

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime);

void __am_timer_init() {
/*
  //初始化时需访问一下 TIMER_UPTIME 寄存器以获取AM系统启动以来的时间
  AM_TIMER_UPTIME_T uptime;
  __am_timer_uptime(&uptime);
*/
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
/*
  //仿真时间系数：6.2
  uint32_t us_high = inl(UPTIME_ADDR+4);
  uint32_t us_low = inl(UPTIME_ADDR);
  uptime->us = (uint64_t)((((uint64_t)us_high)<<32 | ((uint64_t)us_low)) * 62 / 10);
*/
}

//对于RTC(Real Time Clock)，约定设备方面提供两个寄存器
//RTC_ADDR: day<<24 | hour<<16 | minute<<8 | second
//RTC_ADDR+4: year<<16 | month
void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  /*
  uint32_t d = inl(RTC_ADDR);
  uint32_t y = inl(RTC_ADDR+4);
  rtc->second = (int)(d & 0xff);
  rtc->minute = (int)((d >> 8) & 0xff);
  rtc->hour   = (int)((d >> 16) & 0xff);
  rtc->day    = (int)((d >> 24) & 0xff);
  rtc->month  = (int)(y & 0xffff);
  rtc->year   = (int)((y >>16 ) & 0xffff);
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
  */
}
