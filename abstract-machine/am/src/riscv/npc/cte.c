#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

#define XLEN 4
#define word_t uint32_t
#define MSTATUS 0x1800

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
	  //Environment call from M-mode
	  case 11:
          switch(c->GPR1){
			  case -1: ev.event = EVENT_YIELD; c->mepc += 4; break;
		      default: ev.event = EVENT_ERROR; break;
		  }
		  break;

      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  //mepc
  *(((word_t*)kstack.end) - 1) = (uintptr_t)entry;
  //mstatus
  *(((word_t*)kstack.end) - 2) = MSTATUS;
  //arg
  *((word_t*)((uintptr_t)kstack.end - sizeof(Context) + 10*XLEN)) = (uintptr_t)arg;
  //cp
  Context *cp = (Context*)((uintptr_t)kstack.end - sizeof(Context)); 
  return cp;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
