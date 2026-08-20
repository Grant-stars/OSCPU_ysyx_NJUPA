/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>

#define DTRACE_NUM 10000
#define MTRACE_NUM 10000 
#define FTRACE_NUM 10000
extern uint64_t g_nr_guest_inst;
uint64_t device_access = 0;
uint64_t memory_access = 0;
uint64_t function_trace = 0;

#ifndef CONFIG_TARGET_AM
FILE *log_fp = NULL;

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout");
}

bool log_enable() {
  return MUXDEF(CONFIG_TRACE, ((g_nr_guest_inst >= CONFIG_TRACE_START) &&
        (g_nr_guest_inst <= CONFIG_TRACE_END)) || device_access <=DTRACE_NUM ||
			memory_access <=MTRACE_NUM || function_trace <=FTRACE_NUM, false);
}
#endif
