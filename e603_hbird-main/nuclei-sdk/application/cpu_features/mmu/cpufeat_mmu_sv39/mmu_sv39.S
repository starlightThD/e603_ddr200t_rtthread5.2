.text
.global mmu_sv39_access_test
mmu_sv39_access_test:
    
    //csrr a4, mtvec
    /***set satp_mode:sv39***/
    srai a2, a2, 12
    csrw satp, a2
    li a2, 1<<63
    csrs satp, a2
    /***store csr***/
    csrr a2, mstatus
    csrr a6, mepc
    csrr a7, mtvec    
    /***set mtvec***/
    la a5, page_fault_handler
    csrw mtvec, a5
    /***switch to smode***/
    li a5, 0x1000
    csrc mstatus, a5
    li a5, 0x800         
    csrs mstatus, a5
    la a5, mmu_test
    csrw mepc, a5
    mret

.global ecall_handler_smode
ecall_handler_smode:
    csrw mstatus,a2
    csrw mepc, a6
    csrw mtvec, a7
    ret

.align 4
.global page_fault_handler
page_fault_handler:
    csrr a5, mepc
    addi a5, a5, 4
    csrw mepc, a5
    li a0,0x0


    la a5, ecall_handler_smode
    csrw mtvec, a5
    mret
 
.global mmu_test
mmu_test:
    //test code
    /***noerr region***/
    li a2, 0x87654321
    sw a2, 0(a0) //offset could change  //todo: size follow xlen
    lwu a3, 0(a0)
    bne a2, a3, 1f  //todo: self-check
    li a0, 0x0

    li a2, 0x789abcde
    sw a2, 7(a0) //offset could change
    lwu a3, 7(a0)
    bne a2, a3, 1f
    li a0, 0x0

    /***err region***/
    li a2, 0x87654321
    sw a2, 0(a1) //offset could change


    jal pass
    //li a2, 0x9862defa
    //sd a2, 5(a1) //offset could change
    //ld a3, 5(a1)
    //bne a2, a3, 2f
    //li a2, 0x0
    1:
    li a0, 0x1  //flag

    //maybe need rewrite excp_handler
    //mtvec
    //csrw mtvec, a4  //todo
    //csrw mtvec, a3  
    pass:
    //return to main function
    ecall 
