#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdalign.h>
#include "nuclei_sdk_soc.h"
#include "riscv_mmu.h"
#include "check_cpufeature.h"

#define KiB(x) ((uint64_t)(x) << 10l)
#define MiB(x) (KiB(x) << 10l)
#define GiB(x) (MiB(x) << 10l)

//extern  void mmu_sv39_access_test (uint64_t* test_addr, int par0, int par1); //todo
extern  uint64_t mmu_sv39_access_test (uint64_t test_addr0, uint64_t test_addr1, uint64_t test_addr3); //todo

uintptr_t _noerr_start = 0xD0000000;
uintptr_t _err_start = 0xF0000000;

alignas(4096) uint64_t noerr_base_pa ;
alignas(4096) uint64_t err_base_pa;

typedef struct {
    alignas(4096) uint64_t noerr;    //align 4k
    alignas(4096) uint64_t err;
    alignas(4096) uint64_t test_pa;
    alignas(4096) uint64_t test_va;
} AlgnStruct;

int main(void)
{
    page_mem_int();
    /*** get pages' pa ***/
    //uint64_t *noerr_pa_ptr = &noerr_base_pa;
    //uint64_t *err_pa_ptr = &err_base_pa;
    //uint64_t *code_pa_ptr = &test_code_pa;
    uint64_t (*test_code_va_ptr)(uint64_t, uint64_t, uint64_t) = &mmu_sv39_access_test;
    uint64_t noerr_pa = (uint64_t) &noerr_base_pa;
    uint64_t err_pa = (uint64_t) &err_base_pa;
    //uint64_t code_pa = *code_pa_ptr + 32; 
    uint64_t code_pa = (uint64_t) test_code_va_ptr;
    code_pa = code_pa >>12;
    code_pa = code_pa <<12;
    //uint64_t code_va = test_code_va_ptr + 32; //32=4*8 related to instr num before testcode
    uintptr_t code_va = code_pa;
    AlgnStruct *algn = malloc(sizeof(AlgnStruct));
    algn->noerr = noerr_pa;
    algn->err = err_pa;
    algn->test_pa = code_pa;
    algn->test_va = code_va;


    pgd_t *pgd_base = mmu_get_pdg_address();
    uint64_t pgd_base_addr = (uint64_t) pgd_base;
    mmu_region region;
    uint64_t flag;
    uint64_t flag1;

    /***create two pages: 1. noerr; 2. err ***/
    region.name = "sv39_noerr_region"; 
    region.base_va = (uintptr_t) _noerr_start; 
    region.base_pa = (uintptr_t) algn->noerr;  
    region.size = KiB(4);
    region.attrs.pgprot = _PAGE_READ | _PAGE_WRITE | _PAGE_EXEC;  //provide xwr will be enough, xwr:111
    create_pgd_mapping(pgd_base, region.base_va, region.base_pa, region.size, region.attrs);

    region.name = "sv39_err_region"; 
    region.base_va = (uintptr_t)_err_start; 
    region.base_pa = (uintptr_t)algn->err;  
    region.size = KiB(4);
    region.attrs.pgprot = _PAGE_READ;  //xwr:001
    create_pgd_mapping(pgd_base, region.base_va, region.base_pa, region.size, region.attrs);

    /***set page for test_code***/
    region.name = "sv39_test_code"; 
    region.base_va = (uintptr_t)algn->test_va; 
    region.base_pa = (uintptr_t)algn->test_pa;  
    region.size = KiB(4);
    region.attrs.pgprot = _PAGE_READ | _PAGE_EXEC;  //xwr:101
    create_pgd_mapping(pgd_base, region.base_va, region.base_pa, region.size, region.attrs);
    
    //pmp set
    //uintptr_t pmpaddr_value;
    //uintptr_t pmpaddr_mask = ~((1 << 12)-1); //todo: syntax
    uint64_t pmpaddr_value;
    uint64_t pmpaddr_mask = ~((1 << 12)-1); //todo: syntax

    ////pmpaddr_value = ((noerr_pa & pmpaddr_mask) >> 2) + (1 << 9 -1);
    //pmpaddr_value = (((algn -> x) & pmpaddr_mask) >> 2) + (1 << 9 -1);
    //__set_PMPxCFG(2, 0x1F);          // NAPOT, R/W/X   //index, value
    //__set_PMPADDRx(2, pmpaddr_value); // 40bit physical address

    ////pmpaddr_value = ((err_pa & pmpaddr_mask) >> 2) + (1 << 9 -1);
    //pmpaddr_value = (((algn -> y) & pmpaddr_mask) >> 2) + (1 << 9 -1);
    //__set_PMPxCFG(1, 0x1F);          // NAPOT, R/W/X   //index, value
    //__set_PMPADDRx(1, pmpaddr_value); // 40bit physical address

    ////******set pmp privlege for test code *******/
    //pmpaddr_value = (((test_code_base) & pmpaddr_mask) >> 2) + (1 << 9 -1);
    //__set_PMPxCFG(0, 0x1F);        
    //__set_PMPADDRx(0, pmpaddr_value);

    //pmpaddr_value = (((test_code_base) & pmpaddr_mask) >> 2) + (1 << 9 -1); //todo: set all addr range
    pmpaddr_value = ((uint64_t)1 << 63) - 1;
    __set_PMPxCFG(0, 0x1F);        
    __set_PMPADDRx(0, pmpaddr_value);

    //main test
    //enter in excp
    //mmu_sv39_access_test(&noerr_base_pa, &err_base_pa, flag); 
    flag = mmu_sv39_access_test(_noerr_start, _err_start, pgd_base_addr);

    if (flag == 0){ //todo
        printf("NUCLEI_TEST_PASS\n");
        return 0;
    }
    else {
        printf("NUCLEI_TEST_FAIL\n");
        return 1;
    }

}
