// See LICENSE for license details.
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "nuclei_sdk_soc.h"
#include <string.h>
#include "check_cpufeature.h"


int main(void)
{
    uint32_t*  dcache_ca_array  = (uint32_t*)aligned_alloc( 4096, 64); //4K aligned
    uint32_t*  dcache_nc_array0 = (uint32_t*)aligned_alloc( 4096, 64); //4K aligned
    uint32_t*  dcache_nc_array1 = (uint32_t*)aligned_alloc( 4096, 64); //4K aligned

    uintptr_t  mask = ~0xfff;

    // set nc region 0
    __RV_CSR_WRITE(CSR_MATTRI0_MASK, mask);
    __RV_CSR_WRITE(CSR_MATTRI0_BASE, (uintptr_t)dcache_nc_array0 + 5);

    // set nc region 1
    __RV_CSR_WRITE(CSR_MATTRI1_MASK, mask);
    __RV_CSR_WRITE(CSR_MATTRI1_BASE, (uintptr_t)dcache_nc_array1 + 5);

    // cacheable addr memory initial
    memset(dcache_ca_array,0x55, 64);

    // cacheable to non-cacheable memory_copy 
    memcpy(dcache_nc_array0, dcache_ca_array, 64);

    // non-cacheable to non-cacheable memory_copy 
    memcpy(dcache_nc_array0, dcache_nc_array1, 64);

    printf("**********************************\n");
    printf("***************PASS***************\n");
    printf("**********************************\n");
    return 0;
}
