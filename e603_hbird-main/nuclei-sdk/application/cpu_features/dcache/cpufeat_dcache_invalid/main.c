#include "check_cpufeature.h"
#include <stdint.h>
#include <stdio.h>
#include "nuclei_sdk_soc.h"

#define WRITE_VALUE   0x5a5a5a5a
#define WRITE_VALUE1  0x3c3c3c3c

int main(void) {
    printf("=======Benchmark start===========\n");
    EnableDCache();
    printf("=======EnableDCache===========\n");
    //data store dcache,no data write sysmem
    REG32(EVALSOC_SYSMEM_BASE + 0x30000) = WRITE_VALUE;
    REG32(EVALSOC_SYSMEM_BASE + 0x30004) = WRITE_VALUE;
    REG32(EVALSOC_SYSMEM_BASE + 0x30008) = WRITE_VALUE;
    REG32(EVALSOC_SYSMEM_BASE + 0x3000c) = WRITE_VALUE;
    MInvalDCacheLine(EVALSOC_SYSMEM_BASE + 0x30000);
    printf("=======MInvalDCacheLine!========\n");
    REG32(EVALSOC_SYSMEM_BASE + 0x30060) = WRITE_VALUE1;
    REG32(EVALSOC_SYSMEM_BASE + 0x30064) = WRITE_VALUE1;
    REG32(EVALSOC_SYSMEM_BASE + 0x30068) = WRITE_VALUE1;
    REG32(EVALSOC_SYSMEM_BASE + 0x3006c) = WRITE_VALUE1;
    MFlushInvalDCacheLines((EVALSOC_SYSMEM_BASE + 0x30060),1); //this data write to sysmem

    printf("=======MFlushInvalDCacheLines!========\n");

    printf("=======Benchmark over!========\n");
    return 0;
    
}