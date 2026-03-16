#include "nuclei_sdk_hal.h"
#include <stdio.h>
#include <stdint.h>
#include "check_cpufeature.h"


#define SOC_EVENT_BASE (EVALSOC_PERIPS_BASE + 0x12000 + 0x104)

volatile unsigned int *soc_event;


void main(void)
{
    soc_event = (volatile unsigned int*)SOC_EVENT_BASE;

    // test the wfe waken by external event
    // set the soc event happen delay
    *soc_event = 100; 
    __WFE(); 
    // wfi will be waken by external event

    printf("wfe waken by external event\n");
    printf("NUCLEI_TEST_PASS\n");
}
