// See LICENSE for license details.
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "nuclei_sdk_soc.h"
#include <string.h>
#include "check_cpufeature.h"

extern uint8_t dcache_lock_operation(uint32_t addr, uint32_t lock_fail, uint32_t part0);
extern void dcache_unlock_operation(uint32_t addr,  uint32_t part0);

int main(void)
{
    uint32_t   dcache_ca_addr; 
    uintptr_t  mask = ~0xfff;
    uint8_t    ccmdata_check_fail;

    // lock cacheline
    ccmdata_check_fail = dcache_lock_operation(dcache_ca_addr, 0, 0);
    if(ccmdata_check_fail == 1){

            printf("**********************************\n");
            printf("***************FAIL: ccm_data check fail, lock fail***************\n");
            printf("**********************************\n");
            return 0;

        }
    else {

    // unlock cacheline
    dcache_unlock_operation(dcache_ca_addr, 0);

    printf("**********************************\n");
    printf("***************PASS***************\n");
    printf("**********************************\n");
    return 0;
    }
}
