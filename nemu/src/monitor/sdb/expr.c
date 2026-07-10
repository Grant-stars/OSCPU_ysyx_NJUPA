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
#include <memory/vaddr.h>

#define TOKENSLENTH 65535

enum {
  TK_NOTYPE = 256, TK_EQ, TK_NEQ, TK_AND,
  TK_DECIMAL_INTEGER,
  TK_HEX_INTEGER,
  TK_REG,
  TK_DEREF,
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
  {"!=", TK_NEQ},        // neq
  {"&&", TK_AND},        // and
  {"-", '-'},           // minus
  {"\\*", '*'},         // times or deref
  {"/", '/'},           // division
  {"\\(", '('},         // left bracket
  {"\\)", ')'},         // right bracket
  {"\\$[a-zA-Z0][0-9a-zA-Z_]*", TK_REG},      //reg
  {"0[xX][0-9a-fA-F]+", TK_HEX_INTEGER},      // hex integer
  {"[0-9]+",  TK_DECIMAL_INTEGER},            // decimal integer
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

word_t eval(int p, int q, bool* success);

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
          case TK_DECIMAL_INTEGER: 
          case TK_HEX_INTEGER: 
          case TK_REG:{
              switch (rules[i].token_type){
                case TK_DECIMAL_INTEGER: {
                  Assert(substr_len<32, "Decimal integer overflow!");
                  break;
                }
                case TK_HEX_INTEGER: {
                  Assert(substr_len<32, "Hex integer overflow!");
                  break;
                }
                case TK_REG:  {
                  Assert(substr_len<32, "REG overflow!");
                  break;
                }
              }

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
  *success = true;
  //*若前面为表达式类型，则为乘，否则是解引用
  for (int i = 0; i < nr_token; i ++) {
    if (tokens[i].type == '*' && (i == 0 || 
      (tokens[i - 1].type != TK_DECIMAL_INTEGER && 
        tokens[i - 1].type !=TK_HEX_INTEGER && 
        tokens[i - 1].type != TK_REG &&
        tokens[i - 1].type != ')')) ) {
      tokens[i].type = TK_DEREF;
    }
  }

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
    if(tokens[p].type == TK_DECIMAL_INTEGER){
      return strtoul(tokens[p].str, NULL, 10);
    }
    else if(tokens[p].type == TK_HEX_INTEGER){
      return strtoul(tokens[p].str, NULL, 16);
    }
    else if(tokens[p].type == TK_REG){
      word_t ret = isa_reg_str2val((tokens[p].str)+1, success);
      if(*success==false){
        return false;
      }
      else{
        return ret;
      }
    }
    else{
      *success=false;
      return false;
    }
  }
  else if (check_parentheses(p, q,success)) {
    return eval(p + 1, q - 1, success);
  }

  else {
    int main_op = find_main_operator(p, q);
    word_t val1=0;
    word_t val2=0;
    if(tokens[main_op].type!=TK_DEREF){
      val1= eval(p, main_op - 1, success);
    }
    val2= eval(main_op + 1, q, success);
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
        case TK_EQ: return (val1==val2);
        case TK_NEQ: return (val1!=val2);
        case TK_AND: return (val1&&val2);
        case TK_DEREF: return (vaddr_read(val2,4));
        default: assert(0);
    }
  }
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


//运算符优先级:
enum{
  OP_DEREF, //解引用
  OP_TIMES_DIVISION, //乘除
  OP_PLUS_MINUS,  //加减
  OP_EQUAL, //相等运算符
  OP_AND, //逻辑与
};

word_t find_main_operator(int p, int q){
  int priority =-1;
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
        if((tokens[i].type==TK_AND) &&
            priority<=OP_AND){
          priority=OP_AND;
          index=i;
        }

        else if((tokens[i].type==TK_EQ || tokens[i].type==TK_NEQ) &&
            priority<=OP_EQUAL){
          priority=OP_EQUAL;
          index=i;
        }
        else if(
            ((tokens[i].type=='+')||(tokens[i].type=='-')) &&
            priority<=OP_PLUS_MINUS){
          priority=OP_PLUS_MINUS;
          index=i;
        }
        else if(
            ((tokens[i].type=='*')||(tokens[i].type=='/')) &&
            priority<=OP_TIMES_DIVISION){
          priority=OP_TIMES_DIVISION;
          index=i; 
        }
        else if((tokens[i].type==TK_DEREF) &&
            priority<=OP_DEREF){
          priority=OP_DEREF;
          index=i;
        }
      }
    }
  }
  return index;
}