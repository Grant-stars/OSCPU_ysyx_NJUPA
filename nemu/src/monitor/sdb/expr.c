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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <string.h>
#include "../../../include/common.h"
#include <ctype.h>

#define TOKENSLENTH 65535

enum {
  TK_NOTYPE = 256, TK_EQ,
  TK_DECIMAL_INTEGER,
  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"==", TK_EQ},        // equal
  {"-", '-'},           // minus
  {"\\*", '*'},         // times
  {"/", '/'},           // minus
  {"\\(", '('},         // left bracket
  {"\\)", ')'},         // right bracket
  {"[0-9]+",  TK_DECIMAL_INTEGER},         // decimal integer
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

word_t eval(int p, int q, bool* success);
bool is_str_num(char* str);
void is_str_num_test();
bool check_parentheses(int p, int q, bool* success);
word_t find_main_operator(int p, int q);


/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[TOKENSLENTH] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;
        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        Assert((nr_token<TOKENSLENTH),"Too many tokens!");
        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          case TK_DECIMAL_INTEGER: {
            Assert(substr_len<32, "Decimal integer overflow!");
            tokens[nr_token].type = rules[i].token_type;
            strncpy(tokens[nr_token].str, substr_start,substr_len);
            (tokens[nr_token].str)[substr_len]='\0';
            nr_token++;
            break;
          }
          default: {
            tokens[nr_token].type = rules[i].token_type;
            nr_token++;
            break;
          }
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}


word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  //test the is_str_num
  void is_str_num_test();

  *success = true;
  word_t value = eval(0, nr_token-1,success);
  if(*success==false){
    return 0;
  }

  return value;
}


word_t eval(int p, int q, bool* success){
  if(*success==false){
    return false;
  }

  if (p > q) {
    *success=false;
    return false;
  }
  else if (p == q) {
    if(!is_str_num(tokens[p].str)){
      *success=false;
      return false;
    }
    else{
      return strtoul(tokens[p].str, NULL, 10);
    }
  }
  else if (check_parentheses(p, q,success)) {
    return eval(p + 1, q - 1, success);
  }

  else {
    int main_op = find_main_operator(p, q);
    word_t val1 = eval(p, main_op - 1, success);
    word_t val2= eval(main_op + 1, q, success);
    if(*success==false){
      return false;
    }
    switch (tokens[main_op].type) {
        case '+': return val1 + val2;
        case '-': return val1 - val2;
        case '*': return val1 * val2;
        case '/': 
        //Division by zero
          if(val2==0){
            *success=false;
            return false;
          }
          return val1 / val2;
        default: assert(0);
    }
  }
}


bool is_str_num(char* str){
  char* p = str;
  if((*p)=='\0'){
    return false;
  }
  while(*p!='\0'){
    if(!isdigit(*p)){
      return false;
    }
    p++;
  }
  return true;
}

void is_str_num_test(){
  Assert(is_str_num("12309"),"func is_str_num error");
  Assert(!is_str_num("123p9"),"func is_str_num error");
  Assert(!is_str_num("p02309"),"func is_str_num error");
  Assert(!is_str_num("aaaa"),"func is_str_num error");
  Assert(!is_str_num(" "),"func is_str_num error");
  Assert(!is_str_num(""),"func is_str_num error");
}


bool check_parentheses(int p, int q, bool* success){
  char parenthese_stack[TOKENSLENTH][2];
  uint32_t top = 0;
  for(uint32_t i = p; i<=q; i++){
    if(tokens[i].type=='('){
      parenthese_stack[top][0]='(';
      parenthese_stack[top][1]=i;
      top++;
    }
    else if(tokens[i].type==')'){
      if(top==0){
        *success=false;
        return false;
      }
      else{
        if((i==q)&&(parenthese_stack[top-1][1]==p)){
          return true;
        }
        top--;
      }
    }
  }
  if(top!=0){
    *success=false;
    return false;
  }
  else{
    return false;
  }
}


word_t find_main_operator(int p, int q){
  char op=0;
  int index=-1;
  int parentheses = 0;
  for(int i=p; i<=q; i++){
    if(tokens[i].type=='('){
      parentheses++;
    }
    else if(tokens[i].type==')'){
      parentheses--;
    }
    else{
      //if is out of parentheses
      if(!parentheses){
        if((tokens[i].type=='+')||
        (tokens[i].type=='-')){
          op=tokens[i].type;
          index=i;
        }
        else if(
        (tokens[i].type=='*')||
        (tokens[i].type=='/')){
          if((op!='+')&&(op!='-')){
            op=tokens[i].type;
            index=i;
          }
        }
      }
    }
  }
  return index;
}