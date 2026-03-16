// See LICENSE for license details.
#include "check_cpufeature.h"

#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "nuclei_sdk_soc.h"
#include "nmsis_bench.h"

#define LOAD_to_ADD_BIAS 0

#define	FIVE(m)		m m m m m
#define	TEN(m)		FIVE(m) FIVE(m)
#define	FIFTY(m)	TEN(m) TEN(m) TEN(m) TEN(m) TEN(m)
#define	HUNDRED(m)	FIFTY(m) FIFTY(m)
#define	THOUSAND(m)	HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m) HUNDRED(m)




#define CHASE1(x) ((uintptr_t *)(*x + LOAD_to_ADD_BIAS))
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

#define SYSTEM_OFFTEST 0x40000
#define DLM_OFFTEST    0x2000
#define ILM_OFFTEST    0x2000
#define SYSTEM_CHASE_BASE_ADDR ((unsigned long)(CFG_SYS_MEM_BASE  + SYSTEM_OFFTEST))
#define DLM_CHASE_BASE_ADDR    ((unsigned long)(CFG_DLM_BASE_ADDR + DLM_OFFTEST))
#define ILM_CHASE_BASE_ADDR    ((unsigned long)(CFG_ILM_BASE_ADDR + ILM_OFFTEST))

#define REPEAT_CHASE 0
#define NUM_CHASE 100
#define JUMP_STEP ((sizeof(long))*1)

#define CACHE_RUN

#define LOOPNUM 10




/** \brief CPU Internal Region Information */
typedef struct IRegion_Info {
    unsigned long iregion_base;         /*!< Internal region base address */
    unsigned long eclic_base;           /*!< eclic base address */
    unsigned long systimer_base;        /*!< system timer base address */
    unsigned long smp_base;             /*!< smp base address */
    unsigned long idu_base;             /*!< idu base address */
} IRegion_Info_Type;

volatile IRegion_Info_Type SystemIRegionInfo;



unsigned long long            Begin_Cycle, End_Cycle, User_Cycle;
int main(void) __attribute__((optimize("O1")));

int main(void)
{

#ifdef CACHE_RUN
    EnableICache();
    printf("L1 ICache Enable !\r\n");
#endif

    int test;
    int *SysPort_test = (int *)SYSTEM_CHASE_BASE_ADDR; // System Port range
    *SysPort_test = 0x01;

    int *DLM_test = (int *)DLM_CHASE_BASE_ADDR; // DTIM range
    *DLM_test = 0x02;

    test = *((int *)SysPort_test) + *((int *)DLM_test);
    printf("Load to Add Test Begin ...\n");

    // read test
    volatile uintptr_t  *base;
    register unsigned long result = 0;

    // Sys Port test

    base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;

    __RV_CSR_WRITE(CSR_MDEVM, 0xffff8000);
    __RV_CSR_WRITE(CSR_MDEVB, SYSTEM_CHASE_BASE_ADDR|0x1);
    __RWMB();

	#if REPEAT_CHASE
    *base = SYSTEM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = SYSTEM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP - LOAD_to_ADD_BIAS;
        base ++;
    }
    #endif

    base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;

    printf("\nSet addr:0x%lx to Device region \n",SYSTEM_CHASE_BASE_ADDR);


#ifdef CACHE_RUN
    printf("Device Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE,LOOPNUM);
    User_Cycle = 0;
	for(int i = 0; i<LOOPNUM;i++)
	{
		Begin_Cycle =  __get_rv_cycle();
		HUNDRED( result += *base; base ++;)
		End_Cycle = __get_rv_cycle();
		User_Cycle += End_Cycle - Begin_Cycle;
		printf(" Load to add result is %ld\r\n ", result);
		result = 0;
		base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	}
	printf("\nDevice Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("Device Region Test: Begin to chase from addr:0x%lx , num is %d\n",SYSTEM_CHASE_BASE_ADDR, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    HUNDRED( result += *base; base ++;)
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Device Region   total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
    printf(" Load to add result is %ld\r\n", result);
#endif


    // dev region off
    __RV_CSR_WRITE(CSR_MDEVB, SYSTEM_CHASE_BASE_ADDR);

    // non-cacheable region on
    __RV_CSR_WRITE(CSR_MNOCM, 0xffff8000);
    __RV_CSR_WRITE(CSR_MNOCB, SYSTEM_CHASE_BASE_ADDR|0x1);
    __RWMB();
    printf("\nSet addr:0x%lx to non-cacheable region \n",SYSTEM_CHASE_BASE_ADDR);

    result = 0;
    base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;

#ifdef CACHE_RUN
    printf("Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
    User_Cycle = 0;
	for(int i = 0; i<LOOPNUM;i++)
	{
		Begin_Cycle =  __get_rv_cycle();
		HUNDRED( result += *base; base ++;)
		End_Cycle = __get_rv_cycle();
		User_Cycle += End_Cycle - Begin_Cycle;
		printf(" Load to add result is %ld\r\n ", result);
		result = 0;
		base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	}
    printf("\nNon-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    HUNDRED( result += *base; base ++;)
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
    printf(" Load to add result is %ld\r\n", result);
#endif


    result = 0;
    base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
    __RV_CSR_WRITE(CSR_MNOCB, SYSTEM_CHASE_BASE_ADDR);
    __RWMB();
    printf("\nSet addr:0x%lx to cacheable region back \n",SYSTEM_CHASE_BASE_ADDR);

#ifdef CACHE_RUN
    printf("DCache Disable So Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
    User_Cycle = 0;
	for(int i = 0; i<LOOPNUM;i++)
	{
		Begin_Cycle =  __get_rv_cycle();
        HUNDRED(result += *base; base ++;)
		End_Cycle = __get_rv_cycle();
		User_Cycle += End_Cycle - Begin_Cycle;
		printf(" Load to add result is %ld\r\n ", result);
		result = 0;
		base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	}
    printf("\nDCache Disable So Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("DCache Disable So Non-Cacheable Region Test: Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    HUNDRED( result += *base; base ++;)
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DCache Disable So Non-Cacheable Region   total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
    printf(" Load to add result is %ld\r\n", result);
#endif

    unsigned long mcfg_info;

    mcfg_info = __RV_CSR_READ(CSR_MCFG_INFO);
    if (mcfg_info & MCFG_INFO_DCACHE) { // DCache present

    	EnableDCache();
    	printf("L1 DCache Enable !\r\n");

    	if(mcfg_info & MCFG_INFO_SMP) { // SMP present

    		volatile uint32_t *smp_base;
    		smp_base = (uint32_t *)(SystemIRegionInfo.smp_base + 0x10);
    		 *smp_base |= (uint32_t) 0x1;
    		 printf("Cluster Cache Enable !\r\n");

    	}

    	result = 0;
    	base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	#ifdef CACHE_RUN
		printf("\nDCache Enable so Cacheable Region Test (Cold Cache): Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
		User_Cycle = 0;
		for(int i = 0; i<LOOPNUM;i++)
		{
			Begin_Cycle =  __get_rv_cycle();
			HUNDRED( result += *base; base ++;)
			End_Cycle = __get_rv_cycle();
			User_Cycle += End_Cycle - Begin_Cycle;
			//MInvalDCache();
			MFlushInvalDCacheLines((unsigned long)SYSTEM_CHASE_BASE_ADDR, NUM_CHASE/8);
			__RWMB();
			printf(" Load to add result is %ld\r\n ", result);
			result = 0;
			base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
		}
		printf("\nDCache Enable so Cacheable Region Test (Cold Cache)   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));

		// to let next run cache hit
		HUNDRED( result += *base; base ++;)
		printf(" Load to add result is %ld\r\n", result);
		result = 0;
		base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	#else
		printf("\nDCache Enable so Cacheable Region Test (Cold Cache): Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
		//MInvalDCache();
		//__RWMB();
		Begin_Cycle =  __get_rv_cycle();
		HUNDRED( result += *base; base ++;)
		End_Cycle = __get_rv_cycle();
		User_Cycle = End_Cycle - Begin_Cycle;
		printf("DCache Enable so Cacheable Region Test (Cold Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
		printf(" Load to add result is %ld\r\n", result);
	#endif


		result = 0;
		base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
	#ifdef CACHE_RUN
		printf("\nDCache Enable so Cacheable Region Test (Warm Cache): Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
		User_Cycle = 0;
		for(int i = 0; i<LOOPNUM;i++)
		{
			Begin_Cycle =  __get_rv_cycle();
			HUNDRED( result += *base; base ++;)
			End_Cycle = __get_rv_cycle();
			User_Cycle += End_Cycle - Begin_Cycle;
			printf(" Load to add result is %ld\r\n ", result);
			result = 0;
			base = (uintptr_t  *)SYSTEM_CHASE_BASE_ADDR;
		}
		printf("\nDCache Enable so Cacheable Region Test (Warm Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
	#else
		printf("\nDCache Enable so Cacheable Region Test (Warm Cache) Test: Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
		Begin_Cycle =  __get_rv_cycle();
		HUNDRED( result += *base; base ++;)
		End_Cycle = __get_rv_cycle();
		User_Cycle = End_Cycle - Begin_Cycle;
		printf("DCache Enable so Cacheable Region Test (Warm Cache)    total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
		printf(" Load to add result is %d\r\n", result);
	#endif

    }


    // DLM Test
    base = (uintptr_t  *)DLM_CHASE_BASE_ADDR;

    #if REPEAT_CHASE
    *base = DLM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = DLM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP - LOAD_to_ADD_BIAS;
        base ++;
    }
    #endif

    result = 0;
    base = (uintptr_t  *)DLM_CHASE_BASE_ADDR;

#ifdef CFG_HAS_DLM 
#ifdef CACHE_RUN
    printf("\nDLM Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
    User_Cycle = 0;

    for(int i = 0; i<LOOPNUM;i++)
    {
    	Begin_Cycle =  __get_rv_cycle();
    	HUNDRED( result += *base; base ++;)
    	End_Cycle = __get_rv_cycle();
		User_Cycle += End_Cycle - Begin_Cycle;
		printf(" Load to add result is %ld\r\n", result);
		result = 0;
		base = (uintptr_t  *)DLM_CHASE_BASE_ADDR;
    }
    printf("\nDLM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("\nDLM Region Test: Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    HUNDRED( result += *base; base ++;)
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("DLM Region   total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
    printf(" Load to add result is %ld\r\n", result);
#endif
#endif


    // ILM Test
    base = (uintptr_t  *)ILM_CHASE_BASE_ADDR;

    #if REPEAT_CHASE
    *base = ILM_CHASE_BASE_ADDR ;
    #else
    for(int i = 0; i<NUM_CHASE;i++)
    {
        *base = ILM_CHASE_BASE_ADDR + (i+1)*JUMP_STEP - LOAD_to_ADD_BIAS;
        base ++;
    }
    #endif

    result = 0;
    base = (uintptr_t  *)ILM_CHASE_BASE_ADDR;

#ifdef CFG_HAS_ILM 
#ifdef CACHE_RUN

    printf("\nILM Region Test: Begin to chase from addr:0x%lx , num is %d, loop_num:%d\n",base, NUM_CHASE,LOOPNUM);
    User_Cycle = 0;

    for(int i = 0; i<LOOPNUM;i++)
    {
    	Begin_Cycle =  __get_rv_cycle();
    	HUNDRED( result += *base; base ++;)
    	End_Cycle = __get_rv_cycle();
		User_Cycle += End_Cycle - Begin_Cycle;
		printf(" Load to add result is %ld\r\n ", result);
		result = 0;
		base = (uintptr_t  *)ILM_CHASE_BASE_ADDR;
    }
    printf("\nILM Region   total Latency:%d, average latency :%.2f\n", User_Cycle,(float)((float)User_Cycle/(float)(NUM_CHASE*LOOPNUM)));
#else
    printf("\nILM Region Test: Begin to chase from addr:0x%lx , num is %d\n",base, NUM_CHASE);
    Begin_Cycle =  __get_rv_cycle();
    HUNDRED( result += *base; base ++;)
    End_Cycle = __get_rv_cycle();
    User_Cycle = End_Cycle - Begin_Cycle;
    printf("ILM Region   total Latency:%d, average latency :%.2f\n", User_Cycle, (float)((float)User_Cycle/(float)NUM_CHASE));
    printf(" Load to add result is %ld\r\n", result);
#endif
#endif


    return 0;
}

