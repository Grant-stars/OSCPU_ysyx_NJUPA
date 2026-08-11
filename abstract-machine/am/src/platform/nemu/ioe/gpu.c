#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)
// AM访问VGACTL_ADDR和SYNC_ADDR对应init_vga()里第一次add_mmio_map注册的8字节空间

int width, height = 0;

static inline void pixel_draw(uintptr_t addr, uint32_t data){
  outl(addr, data);
}

static void line_draw(uintptr_t start_addr, uint32_t* line_pixels, int len){
  for(int i=0; i<len; i++){
    pixel_draw(start_addr+i*4, line_pixels[i]);
  }
}

void __am_gpu_init() {
  /*
  int i;
  int w = io_read(AM_GPU_CONFIG).width;  // TODO: get the correct width
  int h = io_read(AM_GPU_CONFIG).height;  // TODO: get the correct height
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  for (i = 0; i < w * h; i ++) fb[i] = i;
  outl(SYNC_ADDR, 1);
  */
  width = io_read(AM_GPU_CONFIG).width;
  height = io_read(AM_GPU_CONFIG).height;
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t wh = inl(VGACTL_ADDR);
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = wh >> 16, .height = wh & 0xffff,
    .vmemsz = 0
  };
}
//int x, y; void *pixels; int w, h; bool sync;
void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uintptr_t start_addr = FB_ADDR + (( width * ctl->y) + ctl->x)*4;
  for(int i=0; i<ctl->h; i++){
    line_draw(start_addr + (width*i)*4, ((uint32_t*)ctl->pixels) + i*ctl->w, ctl->w);
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
