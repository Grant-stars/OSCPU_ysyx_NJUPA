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

// mstatus: 0x300; mtvec: 0x305; mepc: 0x341; mcause: 0x342
// mcycle: 0xB00; mcycleh: 0xB80

extern bool mcycle_override;

#define IS_IN_CSR(addr) Assert((addr)==0x300 || (addr)==0x341 || (addr)==0x342 || (addr)==0x305 || (addr)==0xB00 || (addr)==0xB80, "Can not get this CSRs\n") 
#define READ_CSR(addr) ({ IS_IN_CSR((addr)); (addr)==0x300?CSRs[0]:((addr)==0x305?CSRs[1]:((addr)==0x341?CSRs[2]:((addr)==0x342)?CSRs[3]:((addr)==0xB00?CSRs[4]:CSRs[5]))); })
#define WRITE_CSR(addr, data) do {	\
	IS_IN_CSR(addr);	\
	if((addr)==0x300) CSRs[0]=data;	\
	else if((addr)==0x305) CSRs[1]=data;	\
	else if((addr)==0x341) CSRs[2]=data;	\
	else if((addr)==0x342) CSRs[3]=data;	\
	else if((addr)==0xB00) {*((uint64_t*)(CSRs+4)) = ((*((uint64_t*)(CSRs+4)) + 1) & 0xffffffff00000000) | (uint64_t)(data); mcycle_override = true;}	\
	else if((addr)==0xB80) {*((uint64_t*)(CSRs+4)) = ((*((uint64_t*)(CSRs+4)) + 1) & 0xffffffff) | (((uint64_t)(data))<<32); mcycle_override = true;}	\
} while(0)

//provided for csrr
#define PURE_WRITE_CSR(addr, data) do {	\
	if((addr)==0x300) CSRs[0]=data;	\
	else if((addr)==0x305) CSRs[1]=data;	\
	else if((addr)==0x341) CSRs[2]=data;	\
	else if((addr)==0x342) CSRs[3]=data;	\
	else if((addr)==0xB00) CSRs[4]=data;	\
	else if((addr)==0xB80) CSRs[5]=data;	\
} while(0)


#define CYCLE_ADD()	*((uint64_t*)(CSRs+4)) += 1 

typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;
} MUXDEF(CONFIG_RV64, riscv64_CPU_state, riscv32_CPU_state);

// decode
typedef struct {
  uint32_t inst;
} MUXDEF(CONFIG_RV64, riscv64_ISADecodeInfo, riscv32_ISADecodeInfo);

extern word_t CSRs[10];

#define isa_mmu_check(vaddr, len, type) (MMU_DIRECT)

#endif
