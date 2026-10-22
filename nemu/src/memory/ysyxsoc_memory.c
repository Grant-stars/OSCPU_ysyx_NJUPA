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

#include <isa.h>
#include <memory/host.h>
#include <memory/ysyxsoc.h>

static uint8_t mrom[MROM_SIZE] PG_ALIGN = {};
static uint8_t sram[SRAM_SIZE] PG_ALIGN = {};


uint8_t* mrom_to_host(paddr_t paddr) { return mrom + paddr - MROM_VECTOR; }
uint8_t* sram_to_host(paddr_t paddr) { return sram + paddr - SRAM_VECTOR; }

word_t mrom_read(paddr_t addr, int len) {
  word_t ret = host_read(mrom_to_host(addr), len);
  return ret;
}

word_t sram_read(paddr_t addr, int len) {
  word_t ret = host_read(sram_to_host(addr), len);
  return ret;
}


void mrom_write(paddr_t addr, int len, word_t data) {
  host_write(mrom_to_host(addr), len, data);
}

void sram_write(paddr_t addr, int len, word_t data) {
  host_write(sram_to_host(addr), len, data);
}
