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
#include "./monitor/sdb/sdb.h"
#include <readline/readline.h>
#include <readline/history.h>

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();
void free_elf_table();

//Test expr
#ifdef CONFIG_EXPR_TEST
static void compare(){
  FILE* fp=fopen("compare","w");
  for (char *str; (str = readline("")) != NULL; ) {
    char* out1=strtok(str, " ");
    word_t value1 = strtoll(out1,NULL,10 );
    char *out2 = out1 + strlen(out1) + 1;
    bool success;
    word_t value2=expr(out2,&success);
    fprintf(fp,"%u %u %s\n",value1, value2, (value1==value2)?"CORRECT":"ERROR");
  }
  fclose(fp);
}
#endif

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

#ifdef CONFIG_EXPR_TEST
  compare();
  return 0;
#endif

  /* Start engine. */
  engine_start();
  IFDEF(CONFIG_FTRACE, free_elf_table());
  return is_exit_status_bad();
}
