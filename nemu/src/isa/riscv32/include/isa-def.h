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

#ifndef __ISA_RISCV_H__
#define __ISA_RISCV_H__

#include <common.h>

#define IS_IN_CSR(addr) Assert((addr)==0x300 || (addr)==0x341 || (addr)==0x342 || (addr)==0x305, "Can not get this CSRs\n") 
#define READ_CSR(addr) ({ IS_IN_CSR((addr)); (addr)==0x300?CSRs[0]:((addr)==0x305?CSRs[1]:((addr)==0x341?CSRs[2]:CSRs[3])); })
#define WRITE_CSR(addr, data) do {	\
	IS_IN_CSR(addr);	\
	if((addr)==0x300) CSRs[0]=data;	\
	else if((addr)==0x305) CSRs[1]=data;	\
	else if((addr)==0x341) CSRs[2]=data;	\
	else CSRs[3]=data;	\
} while(0)

typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;
} MUXDEF(CONFIG_RV64, riscv64_CPU_state, riscv32_CPU_state);

// decode
typedef struct {
  uint32_t inst;
} MUXDEF(CONFIG_RV64, riscv64_ISADecodeInfo, riscv32_ISADecodeInfo);

extern word_t CSRs[5];

#define isa_mmu_check(vaddr, len, type) (MMU_DIRECT)

#endif
