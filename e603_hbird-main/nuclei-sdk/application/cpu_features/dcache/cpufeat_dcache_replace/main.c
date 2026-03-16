// See LICENSE for license details.
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "nuclei_sdk_soc.h"
#include "check_cpufeature.h"

extern void dcache_full_replace(uint32_t loop_num, uint32_t* access_addr, uint32_t part0, uint32_t part1);
uint32_t dcache_test;

int main(void)
{


    uint32_t result1, mdcfg_value, refill_loop_num;
    uint8_t   dc_sizebits, dc_setbits, dc_ways,reg_mask;


    // enable dcache
    EnableDCache();
    // close prefetch amd speculative
    __RV_CSR_CLEAR(mmisc_ctl, 1 << 12);
    //******************************************************************************
    //******************* get parameter*********************************************
    //******************************************************************************

    mdcfg_value = __RV_CSR_READ(CSR_MDCFG_INFO);
   // printf("--------------000000 mcfg_value  is %x--------------.\n",mdcfg_value);
    // get dcache index width
    reg_mask = 0xf;
    dc_setbits = (mdcfg_value & reg_mask) + 3;
    //printf("--------------000000  set bits  is %d--------------.\n",dc_setbits);
    reg_mask = 0x7;
    dc_ways =  ((mdcfg_value >> 4) & reg_mask) + 1;

    //get dcache cacheline width
    dc_sizebits = ((mdcfg_value >> 7) & reg_mask) + 2;
   // printf("--------------000000 size bits  is %d--------------.\n",dc_sizebits);

    refill_loop_num = ((uint32_t)pow(2,(dc_setbits + dc_sizebits)) * dc_ways )/4;  // sw 
   // printf("--------------000000 loop num  is %d--------------.\n",refill_loop_num);

   // printf("--------------000000 a0 addr is  is %x--------------.\n",&dcache_test);

    MFlushInvalDCache();


    dcache_full_replace(refill_loop_num*3,&dcache_test, result1, result1 );


    printf("**********************************\n");
    printf("***************PASS***************\n");
    printf("**********************************\n");
    return 0;
}
