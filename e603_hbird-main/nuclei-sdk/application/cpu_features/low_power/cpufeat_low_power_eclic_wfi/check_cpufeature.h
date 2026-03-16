#include "cpufeature.h"

#ifndef CFG_HAS_CLIC
#error "This case require CPU eclic feature"
#endif

#if CFG_IRQ_NUM < 5
#error "This case require CPU external irq should be larger 5"
#endif

#ifndef EVALSOC_HAS_SUBSYS_MISC
#error "This case require evalsoc subsys_misc device to send external interrupt"
#endif

