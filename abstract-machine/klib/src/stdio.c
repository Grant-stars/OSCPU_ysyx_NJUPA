#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define PTR_MOVE(len) do{ out+=len; fmt++; count+=len; } while(0)

size_t int_to_str(char* s, int d){
  char stack[25];
  int top=0;
  size_t len = 0;
  //123, -456
  if(d<0){
    d=-d;
    *s='-';
    s++;
  }
  //123,456
  while(d!=0){
    stack[top]=(d%10)+'1'-1;
    d=d/10;
    top++;
  }
  if(top==0){
    s[0]='0';
    s[1]='\0';
    return 1;
  }
  else{
    len = top;
    top--;
    while(top>=0){
      s[len-top-1]=stack[top];
      top--;
    }
    s[len]='\0';
    return len;
  }
}


int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  int d;
  char* s;
  int count =0;
  //"I have %d %s", 4, "apples"
  va_start(ap, fmt);
  while(*fmt!='\0'){
    if(*fmt=='%'){
      fmt++;
      if(*fmt=='%'){
        *out='%';
        PTR_MOVE(1);
      }
      else{
        while((*fmt!='s') && (*fmt!='d')){ fmt++; } //Todo
        switch(*fmt){
          case 's':
            s = va_arg(ap, char*);
            strcpy(out, s);
            PTR_MOVE(strlen(s));
            break;

          case 'd':
            d = va_arg(ap, int);
            char char_d[25];
            size_t d_len = int_to_str(char_d, d);
            strcpy(out, char_d);
            PTR_MOVE(d_len);
            break;
        }
      }
    }
    else{
      *out = *fmt;
      PTR_MOVE(1);
    }
  }
  *out='\0';
  va_end(ap);
  return count;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
