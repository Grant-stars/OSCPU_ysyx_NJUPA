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

#include "sdb.h"
#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  char* wp_name;
  word_t wp_value;
  bool is_used;

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].is_used = false;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
int new_wp(char* s){
  if(free_==NULL){
    Assert(0,"No more free watchpoint.\n");
  }

  bool success ;
  word_t value=expr(s, &success);
  if(!(success)){
    printf("Invalid expression!\n");
    return -1;
  }

  WP* tmp = free_->next;
  free_->next=head;
  head=free_;
  free_=tmp;
  head->is_used=true;
  head->wp_name=malloc(strlen(s)+1);
  strcpy(head->wp_name, s);
  head->wp_value=value;
  return head->NO;
}

bool free_wp(int number){
  if(number>=NR_WP || number<0){
    printf("Invalid watchpoint number!\n");
    return false;
  } 
  else if(wp_pool[number].is_used==0){
    printf("watchpoint %d is already free\n", number);
    return false;
  } //此处保证head一定不是NULL
  else{
    Assert(head, "Error!");
    WP* p = head; 
    //如果待删除节点是head
    if(p->NO==number){
      head=p->next;
      p->next=free_;
      p->is_used=false;
      free(p->wp_name);
      free_=p;
      return true;
    }
    while(p->next!=NULL){
      if(p->next->NO==number){
        WP* tmp = p->next;
        p->next=tmp->next;
        tmp->next=free_;
        tmp->is_used=false;
        free(tmp->wp_name);
        free_=tmp;
        return true;
      }
      else{
        p=p->next;
      }
    }
    panic("Error!");
  }
}

bool scan_wp(){
  WP* p=head;
  int flag =0;
  while(p!=NULL){
    bool success;
    word_t new_value = expr(p->wp_name, &success);
    if(new_value!=p->wp_value){
      flag=1;
      printf("Watchpoint %d: %s\n", p->NO, p->wp_name);
      printf("Old value = %u\n", p->wp_value);
      printf("New value = %u\n", new_value);
      p->wp_value=new_value;
    }
    p=p->next;
  }
  if(flag){
    return true;
  }
  else{
    return false;
  }
}

void wp_display(){
  printf("Num     Type           value          What\n");
  for(int i =0; i<NR_WP; i++){
    if(wp_pool[i].is_used==true){
      printf("%-8d%-15s%-15u%s\n", wp_pool[i].NO, "watchpoint", wp_pool[i].wp_value, wp_pool[i].wp_name);
    }
  }
}