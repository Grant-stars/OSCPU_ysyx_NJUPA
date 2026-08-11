#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define CONSUME_PERCENT(p) ((p)++)

char hexstrbuf[]="0123456789abcdef";

//handle options in format
static inline void scan_options(const char** fmt){
  while((**fmt!='s') && (**fmt!='d') && (**fmt!='c') && (**fmt!='x') && (**fmt!='X')){ 
    (*fmt)++; 
  }
}

#define OUTPUT(func, src, type, ...) func##_OUTPUT_##type(src, ##__VA_ARGS__) 
#define SP_OUTPUT_STR(src, out) do{ \
  strcpy(out,src);  \
  PTR_MOVE(SP, strlen(src));  \
} while(0)

#define SP_OUTPUT_CHAR(src, out) do{ \
  *out = src; \
  PTR_MOVE(SP, 1);  \
} while(0)

#define P_OUTPUT_STR(src) do{  \
  char* p = src;  \
  while(*p!='\0'){ \
    putch(*p);  \
    p++;  \
  } \
  PTR_MOVE(P, p-src);  \
} while(0)

#define P_OUTPUT_CHAR(src) do{ \
  putch(src); \
  PTR_MOVE(P, 1); \
} while(0)


#define PTR_MOVE(func, len) func##_PTR_MOVE(len)
#define SP_PTR_MOVE(len) do{ out+=len; fmt++; count+=len; } while(0)
#define P_PTR_MOVE(len) do{ fmt++; count+=len; } while(0)

#define parse_fmt(func, ...) do{ \
  while(*fmt!='\0'){  \
    if(*fmt=='%'){  \
      CONSUME_PERCENT(fmt);  \
      if(*fmt=='%') {OUTPUT(func, '%', CHAR, ##__VA_ARGS__);} \
      else{ \
        scan_options(&fmt); \
        switch(*fmt){ \
          case 's': \
            s = va_arg(ap, char*);  \
            OUTPUT(func, s, STR, ##__VA_ARGS__);  \
            break;  \
          case 'd': \
            d = va_arg(ap, int);  \
            char str_d[25];  \
            int_to_str(str_d, d); \
            OUTPUT(func, str_d, STR, ##__VA_ARGS__);  \
            break;  \
          case 'c': \
            c = (char)va_arg(ap, int); \
            OUTPUT(func, c, CHAR, ##__VA_ARGS__); \
            break;  \
          case 'x': case 'X': \
            d = va_arg(ap, int);  \
            char str_x[17]; \
            int_to_hex_str(str_x, d); \
            OUTPUT(func, str_x, STR, ##__VA_ARGS__); \
            break;  \
        } \
      } \
    } \
    else {OUTPUT(func, *fmt, CHAR, ##__VA_ARGS__);}  \
  } \
} while(0)


size_t int_to_str(char* s, int d_int){
  char stack[25];
  int top=0;
  size_t len = 0;
  unsigned int d_uint;
  //123, -456
  if(d_int<0){
    if(d_int==0x80000000){
      d_uint = (unsigned int)d_int;
    }
    else{
      d_uint = -d_int;
    }
    *s='-';
    s++;
  }
  else{
    d_uint = d_int;
  }
  //123,456
  while(d_uint!=0){
    stack[top]=(d_uint%10)+'1'-1;
    d_uint=d_uint/10;
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

size_t int_to_hex_str(char* s, int d_int){
  uint32_t d_hex = (uint32_t)d_int;
  char stack[17];
  int top = 0;
  do{
    stack[top]=hexstrbuf[d_hex%16];
    top++;
    d_hex=d_hex/16;
  }while(d_hex!=0);
  size_t len = top;
  top--;
  while(top>=0){
    s[len-top-1] = stack[top];
    top--;
  }
  s[len] = '\0';
  return len;
}


int printf(const char *fmt, ...) {
  va_list ap;
  int d;
  char* s;
  char c;
  int count =0;
  va_start(ap, fmt);
  parse_fmt(P);
  va_end(ap);
  return count;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  int d;
  char* s;
  char c;
  int count =0;
  //"I have %d %s", 4, "apples"
  va_start(ap, fmt);
  parse_fmt(SP, out);
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
