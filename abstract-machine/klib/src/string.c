#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t i =0;
  while(s[i]!='\0'){
    i++;
  }
  return i;
}

char *strcpy(char *dst, const char *src) {
  size_t i =0;
  while(src[i]!='\0'){
    dst[i]=src[i];
    i++;
  }
  dst[i]='\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for(i =0; i<n && src[i]!='\0'; i++){
    dst[i]=src[i];
  }
  while(i<n){
    dst[i]='\0';
    i++;
  }
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t dst_len = strlen(dst);
  size_t src_len = strlen(src);
  size_t i;
  for(i =0; i<src_len; i++){
    dst[dst_len+i]=src[i];
  }
  dst[dst_len+i]='\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  size_t i = 0;
  while(s1[i]!='\0' && s2[i]!='\0'){
    if((unsigned char)(s1[i]) < (unsigned char)(s2[i])){
      return -1;
    }
    else if ((unsigned char)(s1[i]) > (unsigned char)(s2[i])){
      return 1;
    }
    else{
      i++;
    }
  }
  if(s1[i]=='\0' && s2[i]=='\0'){
    return 0;
  }
  else if(s1[i]=='\0'){
    return -1;
  }
  else{
    return 1;
  }
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i = 0;
  while(s1[i]!='\0' && s2[i]!='\0' && i<n){
    if((unsigned char)(s1[i]) < (unsigned char)(s2[i])){
      return -1;
    }
    else if ((unsigned char)(s1[i]) > (unsigned char)(s2[i])){
      return 1;
    }
    else{
      i++;
    }
  }
  if(i==n || (s1[i]=='\0' && s2[i]=='\0')){
    return 0;
  }
  else if(s1[i]=='\0'){
    return -1;
  }
  else{
    return 1;
  }
}

void *memset(void *s, int c, size_t n) {
  unsigned char* s_ch =s; 
  for(size_t i =0; i<n; i++){
    s_ch[i]= (unsigned char)c; 
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  if(dst<src){
    for(size_t i =0; i<n; i++){
      ((unsigned char*)dst)[i] =  ((unsigned char*)src)[i];
    }
  }
  else{
    for(size_t i =n; i>0; ){
      i--;
      ((unsigned char*)dst)[i] =  ((unsigned char*)src)[i];
    }
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  for(size_t i =0; i<n; i++){
    ((unsigned char*)out)[i] =  ((unsigned char*)in)[i];
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  size_t i;
  for(i =0; i<n; i++){
    if(((unsigned char*)s1)[i]<((unsigned char*)s2)[i]){
      return -1;
    }
    else if(((unsigned char*)s1)[i]>((unsigned char*)s2)[i]){
      return 1;
    }
  }
  return 0;
}

#endif
