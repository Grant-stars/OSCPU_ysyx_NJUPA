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

#include <readline/readline.h>
#include <readline/history.h>
#include <stdint.h>
#include "../common.h"
#include "VysyxSoCFull.h" 
#include "verilated.h" 
#include "verilated_fst_c.h"   //引入波形相关头文件

static int is_batch_mode = false;
void cpu_exec(uint64_t n);

void init_regex();
void reg_display();
uint32_t vaddr_read(uint32_t addr);
word_t expr(char *e, bool *success);
void init_wp_pool();
void wp_display();
int new_wp(char* s);
bool free_wp(int number);

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
	return -1;
}

static int cmd_si(char *args) {
  if(args==NULL){
    cpu_exec(1);
  } 
  else{
    long long inst_num = strtoll(args,NULL,10 );
    if(inst_num<0){
      printf("Execute all remaining instructions\n");
    }
    cpu_exec(inst_num);
  }
  return 0;
}

static int cmd_info(char *args) {
  if(args==NULL){
    printf("Argument required for info\n");
  }
  else if(*args=='r' && *(args+1)=='\0'){
    reg_display();
  }
  else if(*args=='w' && *(args+1)=='\0'){
    wp_display();
  }
  else {
    printf("Invalid info args!\n");
  }
  return 0;
}

static int cmd_x(char *args) {
  if(args==NULL){
    printf("Argument required (num of outpupt and starting display address)\n");
  }
  else{
    char *args_end = args + strlen(args);
    char* N_str=strtok(args, " ");
    int N_len=strlen(N_str);
    int N = strtoll(N_str,NULL,10 );
    if(N<=0){
      printf("Illegal input\n");
    }
    char* start_ptr = N_str+N_len+1;
    if(start_ptr>args_end){
      printf("Argument required (starting display address)\n");
    }
    else {
      bool success ;
      word_t start_addr=expr(start_ptr,&success);
      if(!success){
        printf("Invalid expression!\n");
      }
      else{
        for(int i=0;i<N;i++){
            char buf[32];
            sprintf(buf,"0x%X:",(start_addr+4*i));
            printf("%-12s0x%.8X\n",buf, vaddr_read((start_addr+4*i)));
        }
      }
    }
  }
  return 0;
}

static int cmd_p(char *args) {
  if(args==NULL){
    printf("Argument required for p\n");
    return 0;
  }
  bool success ;
  word_t value=expr(args,&success);
  if(!success){
    printf("Invalid expression!\n");
  }
  else{
    printf("%s = %u (0x%x)\n",args, value, value);
  }
  return 0;
}

static int cmd_w(char *args) {
  if(args==NULL){
    printf("Argument required for w\n");
    return 0;
  }
#ifndef CONFIG_WATCHPOINT
  printf("Please open watchpoint!\n");
#else
  int number = new_wp(args);
  if(number!=-1){
    printf("Watchpoint %d: %s\n", number, args);
  }
#endif
  return 0;
}

static int cmd_d(char *args) {
  if(args==NULL){
    printf("Argument required for d\n");
    return 0;
  }
  bool success;
  int number = (int)expr(args,&success);
  if(!success){
    printf("Invalid expression!\n");
  }
  else{
    if(!free_wp(number)){
      printf("Failed to delete watchpoint %d\n", number);
    }
    else{
      printf("Deleted watchpoint %d\n", number);
    }
  }
  return 0;
}



static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },
  { "si", "Step the program for N instructions", cmd_si },
  { "info", "Print the state of program", cmd_info },
  { "x", "Scan memory and output N bytes", cmd_x },
  { "p", "Print the arithmetic expression", cmd_p },
  { "w", "Set the watchpoint", cmd_w },
  { "d", "Delete watchpoint", cmd_d },

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
 }
