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
#include <stdio.h>
#include "common.h"

extern uint8_t MEM[CONFIG_MSIZE];

static const uint32_t img [] = {
    0x00300513,          //addi a0,zero,3
    0x00300513,          //addi a0,zero,3
    //0x0FFFF537,       //lui   a0, (0x0ffff000)

    0x10054603,         //lbu a2, a0, 0x100
    0x00200513,         //addi a0,zero,2
    0x10C50023,         //sb a2 a0 0x100
    0x10002603,       //lw    a2, 0, 0x100
    0x10A00023,         //sb a0, 0, 0x100
    //0x10A02023,       //sw a0, 0, 0x100
    0x10002603,         //lw    a2, 0, 0x100
    0x00A505B3,         //add   a1,a0,a0
    0x00a50513,         //addi	a0,a0,10
    0x00100073,         //ebreak
    /*
    0x01400513,         //addi	a0,zero,20
    0x010000e7,         //jalr	ra,16(zero) # 10 <fun>
    0x00c000e7,         //jalr	ra,12(zero) # c <halt>
    0x00100073,         //ebreak
    0x00a50513,         //addi	a0,a0,10
    0x00008067,         //jalr	zero,0(ra)
    */
};

void init_mem(){
	memcpy(MEM, img, sizeof(img));
};
void init_log(const char *log_file);
void init_elf(const char* elf_file);
void init_difftest(char *ref_so_file, long img_size, int port);
void init_sdb();
void init_disasm();

#include <getopt.h>

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
static int difftest_port = 1234;

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(MEM, size, 1, fp);
  assert(ret == 1);
  Assert(ret<=CONFIG_MSIZE, "Insufficient MEM\n"); 

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {"elf"      , required_argument, NULL, 'e'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:e:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'e': elf_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-e,--elf=FILE           receive elf FILE to parse FUNC\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Open the log file. */
  init_log(log_file);

  /* Open the elf file. */
  IFDEF(CONFIG_FTRACE, init_elf(elf_file));

  /* Initialize memory. */
  init_mem();

    /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  /* Initialize disasm. */
  IFDEF(CONFIG_ITRACE, init_disasm());

  /* Initialize the simple debugger. */
  init_sdb();


}

