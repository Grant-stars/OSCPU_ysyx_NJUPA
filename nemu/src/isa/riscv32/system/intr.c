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

#include "isa-def.h"
#include <isa.h>
extern uint64_t exception_access;
static uint32_t mtvec = 0;
word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */

  WRITE_CSR(0x341, epc);
  WRITE_CSR(0x342, NO);
  mtvec = READ_CSR(0x305); 
#ifdef CONFIG_ETRACE
    //syscall: 
	//riscv32e: a5; riscv32: a7 
	int syscall = cpu.gpr[17];
	if(ETRACE_COND){
	  log_write("Trigger an interrupt/exception with mepc = 0x%.8x, mcause = 0x%.8x, syscall = %d, mtvec = 0x%.8x\n", epc, NO, syscall, mtvec);
      exception_access++;
    }
  return mtvec;
#endif
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
