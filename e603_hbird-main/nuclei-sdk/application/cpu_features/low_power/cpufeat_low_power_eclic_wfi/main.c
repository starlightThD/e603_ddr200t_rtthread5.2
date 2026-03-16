#include "nuclei_sdk_hal.h"
#include <stdio.h>
#include <stdint.h>
#include "check_cpufeature.h"

#define SOC_COUNTER0_IRQ_BASE (EVALSOC_PERIPS_BASE + 0x12000 + 0x0)

volatile unsigned int *soc_counter0_irq;

#define SOC_COUNTER0_IRQ_NUM (19+5)

__INTERRUPT void eclic_irq24_handler(void) {
    SAVE_IRQ_CSR_CONTEXT();

    *soc_counter0_irq = 0xffffffff; 
    printf("wfi waken by external irq, and irq was processed\n");
    RESTORE_IRQ_CSR_CONTEXT();
}

int eclic_register_interrupt(IRQn_Type IRQn, uint8_t shv, uint32_t trig_mode, uint32_t lvl, uint32_t priority, void * handler)
{
    ECLIC_SetShvIRQ(IRQn, shv);
    ECLIC_SetTrigIRQ(IRQn, trig_mode);
    ECLIC_SetLevelIRQ(IRQn, lvl);
    ECLIC_SetPriorityIRQ(IRQn, priority);
    ECLIC_SetVector(IRQn, (rv_csr_t)(handler));
    ECLIC_EnableIRQ(IRQn);
    return 0;
}

void main(void)
{
    soc_counter0_irq = (volatile unsigned int*)SOC_COUNTER0_IRQ_BASE;

    ECLIC_SetMth(0);     
    ECLIC_SetCfgNlbits(1);

    eclic_register_interrupt(SOC_COUNTER0_IRQ_NUM, 1, 0, 1, 0, eclic_irq24_handler);

    // test the wfi waken by interrupt, and cpu process the interrupt
    __enable_irq();
    __RMB();

    // set the soc counter0 interrupt happen delay
    *soc_counter0_irq = 100; 
    __WFI(); 
    // wfi will be waken by external interrupt

    // test the wfi waken by interrupt, and cpu ignore the interrupt
    __disable_irq();
    *soc_counter0_irq = 100; 
    __WFI();
    printf("wfi waken by external irq, and irq was ignored\n");
    printf("NUCLEI_TEST_PASS\n");
}
