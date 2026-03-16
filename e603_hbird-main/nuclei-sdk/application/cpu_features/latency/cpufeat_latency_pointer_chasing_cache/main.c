// See LICENSE for license details.
#include "check_cpufeature.h"

#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "nuclei_sdk_soc.h"
#include "nmsis_bench.h"


// Pointer chasing macros to force the loop to be unwound
#define CHASE1(x) ((uintptr_t *)*x)
#define CHASE2(x) CHASE1(CHASE1(x))
#define CHASE4(x) CHASE2(CHASE2(x))
#define CHASE8(x) CHASE4(CHASE4(x))
#define CHASE16(x) CHASE8(CHASE8(x))
#define CHASE32(x) CHASE16(CHASE16(x))
#define CHASE64(x) CHASE32(CHASE32(x))
#define CHASE128(x) CHASE64(CHASE64(x))
#define CHASE256(x) CHASE128(CHASE128(x))
#define CHASE512(x) CHASE256(CHASE256(x))
#define CHASE1024(x) CHASE512(CHASE512(x))

//#define _AC(X,Y)        (X##Y)

// need to change as the SoC or CPU conf
#define SYSTEM_OFFTEST 0x40000
#define DLM_OFFTEST    0x2000
#define ILM_OFFTEST    0x2000
#define SYSTEM_CHASE_BASE_ADDR ((unsigned long)(CFG_SYS_MEM_BASE  + SYSTEM_OFFTEST))
#define DLM_CHASE_BASE_ADDR    ((unsigned long)(CFG_DLM_BASE_ADDR + DLM_OFFTEST))
#define ILM_CHASE_BASE_ADDR    ((unsigned long)(CFG_ILM_BASE_ADDR + ILM_OFFTEST))

#define REPEAT_CHASE 0
#define NUM_CHASE 1024
#define JUMP_STEP ((sizeof(long))*1)

#define CACHE_RUN  1

#define LOOPNUM 10
// end


typedef struct IRegion_Info {
    unsigned long iregion_base;         /*!< Internal region base address */
    unsigned long eclic_base;           /*!< eclic base address */
    unsigned long systimer_base;        /*!< system timer base address */
    unsigned long smp_base;             /*!< smp base address */
    unsigned long idu_base;             /*!< idu base address */
} IRegion_Info_Type;

volatile IRegion_Info_Type SystemIRegionInfo;

unsigned long long            Begin_Cycle, End_Cycle, User_Cycle;

int main(void)
{

#ifdef CACHE_RUN
    EnableICache();
    printf("L1 ICache Enable !\r\n");
#endif

    int test;
    int *SysPort_test = (int *)SYSTEM_CHASE_BASE_ADDR; // System Port range
    *SysPort_test = 0x01;

    int *DLM_test = (int *)DLM_CHASE_BASE_ADDR; // DLM range
    *DLM_test = 0x02;

    test = *((int *)SysPort_test) + *((int *)DLM_test);
    printf("Read reulst:%d\n",test);

    // read test
    uintptr_t  *base;
    volatile unsigned long result;


    // Sys Port test
    base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;

    #if REPEAT_CHASE
    *base = SYSTEM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = SYSTEM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP;
        base ++;
    }
    #endif

    __RV_CSR_WRITE(CSR_MDEVM, 0xffff8000);
    __RV_CSR_WRITE(CSR_MDEVB, SYSTEM_CHASE_BASE_ADDR|0x1);
    __RWMB();
    printf("\nSet addr:0x%lx to Device region \n",SYSTEM_CHASE_BASE_ADDR);


#ifdef CACHE_RUN
    printf("Device Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    Begin_Cycle =  __get_rv_cycle();

    for(int i = 0; i<LOOPNUM;i++)
    {
    	result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    }

    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Device Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("Device Region Test: Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Device Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
#endif

    // dev region off
    __RV_CSR_WRITE(CSR_MDEVB, SYSTEM_CHASE_BASE_ADDR);

    // non-cacheable region on
    __RV_CSR_WRITE(CSR_MNOCM, 0xffff8000);
    __RV_CSR_WRITE(CSR_MNOCB, SYSTEM_CHASE_BASE_ADDR|0x1);
    __RWMB();
    printf("\nSet addr:0x%lx to non-cacheable region \n",SYSTEM_CHASE_BASE_ADDR);


#ifdef CACHE_RUN
    printf("Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    Begin_Cycle =  __get_rv_cycle();

    for(int i = 0; i<LOOPNUM;i++)
    {
    	result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    }

    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
#endif


    __RV_CSR_WRITE(CSR_MNOCB, SYSTEM_CHASE_BASE_ADDR);
    __RWMB();
    printf("\nSet addr:0x%lx to cacheable region back \n",SYSTEM_CHASE_BASE_ADDR);

#ifdef CACHE_RUN
    printf("DCache Disable So Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    Begin_Cycle =  __get_rv_cycle();

    for(int i = 0; i<LOOPNUM;i++)
    {
    	result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    }

    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DCache Disable So Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("DCache Disable So Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DCache Disable So Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
#endif


    unsigned long mcfg_info;

    mcfg_info = __RV_CSR_READ(CSR_MCFG_INFO);
    if (mcfg_info & MCFG_INFO_DCACHE) { // DCache present

    	EnableDCache();
    	printf("\nL1 DCache Enable !\r\n");

    	if(mcfg_info & MCFG_INFO_SMP) { // SMP present

    		volatile uint32_t *smp_base;
    		smp_base = (uint32_t *)(SystemIRegionInfo.smp_base + 0x10);
    		 *smp_base |= (uint32_t) 0x1;
    		 printf("Cluster Cache Enable !\r\n");

    	}

	#ifdef CACHE_RUN
		printf("\nDCache Enable so Cacheable Region Test (Cold Cache): Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
		User_Cycle = 0;
		for(int i = 0; i<LOOPNUM;i++)
		{
			Begin_Cycle =  __get_rv_cycle();
			result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
			End_Cycle = __get_rv_cycle();
			User_Cycle += End_Cycle - Begin_Cycle;
			//MInvalDCache();
			MFlushInvalDCacheLines(SYSTEM_CHASE_BASE_ADDR, NUM_CHASE/8);
			__RWMB();
		}
		printf("DCache Enable so Cacheable Region Test (Cold Cache)   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));

		// to let next run cache hit
		result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
	#else
		printf("\nDCache Enable so Cacheable Region Test (Cold Cache): Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
		//MInvalDCache();
		//__RWMB();
		Begin_Cycle =  __get_rv_cycle();
		result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
		End_Cycle = __get_rv_cycle();
		User_Cycle = End_Cycle - Begin_Cycle;
		printf("DCache Enable so Cacheable Region Test (Cold Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
	#endif


	#ifdef CACHE_RUN
		printf("\nDCache Enable so Cacheable Region Test (Warm Cache): Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
		User_Cycle = 0;
		for(int i = 0; i<LOOPNUM;i++)
		{
			Begin_Cycle =  __get_rv_cycle();
			result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
			End_Cycle = __get_rv_cycle();
			User_Cycle += End_Cycle - Begin_Cycle;
		}
		printf("DCache Enable so Cacheable Region Test (Warm Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
	#else
		printf("\nDCache Enable so Cacheable Region Test (Warm Cache) Test: Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
		Begin_Cycle =  __get_rv_cycle();
		result = (unsigned long) CHASE1024((uintptr_t  *)SYSTEM_CHASE_BASE_ADDR);
		End_Cycle = __get_rv_cycle();
		User_Cycle = End_Cycle - Begin_Cycle;
		printf("DCache Enable so Cacheable Region Test (Warm Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
	#endif

    }

    // DLM Test
    base = (uintptr_t  *)DLM_CHASE_BASE_ADDR;

    #if REPEAT_CHASE
    *base = DLM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = DLM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP;
        base ++;
    }
    #endif

#ifdef CFG_HAS_DLM
#ifdef CACHE_RUN
    printf("\nDLM Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",DLM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    Begin_Cycle =  __get_rv_cycle();

    for(int i = 0; i<LOOPNUM;i++)
    {
    	result = (unsigned long) CHASE1024((uintptr_t  *)DLM_CHASE_BASE_ADDR);
    }

    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DLM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("\nDLM Region Test: Begin to chase from addr:0x%lx , num is %d\n",DLM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    result = (unsigned long) CHASE1024((uintptr_t  *)DLM_CHASE_BASE_ADDR);
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DLM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
#endif
#endif

    // ILM Test
    base = (uintptr_t  *)ILM_CHASE_BASE_ADDR;

    #if REPEAT_CHASE
    *base = ILM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = ILM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP;
        base ++;
    }
    #endif

#ifdef CFG_HAS_ILM
#ifdef CACHE_RUN
    printf("\nILM Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",ILM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    Begin_Cycle =  __get_rv_cycle();

    for(int i = 0; i<LOOPNUM;i++)
    {
    	result = (unsigned long) CHASE1024((uintptr_t  *)ILM_CHASE_BASE_ADDR);
    }

    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("ILM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("\nILM Region Test: Begin to chase from addr:0x%lx , num is %d\n",ILM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    result = (unsigned long) CHASE1024((uintptr_t  *)ILM_CHASE_BASE_ADDR);
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("ILM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)NUM_CHASE));
#endif
#endif

    return 0;
}

