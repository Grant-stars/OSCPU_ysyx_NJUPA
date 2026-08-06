#include "svdpi.h"
#include "Vtop__Dpi.h"
extern bool* end_ptr;
void finish(){
    *end_ptr = true;
    return;
}
