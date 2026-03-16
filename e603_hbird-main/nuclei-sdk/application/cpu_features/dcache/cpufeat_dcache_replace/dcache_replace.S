    #include "check_cpufeature.h"
.text
.global dcache_full_replace
dcache_full_replace:
    //a0 = loop_num a1 = test addr 
    li a2,0xffff0000
    and a1, a1,a2 //aligned

    li a2,0
    continue0:
    blt a2, a0,  loop_refill


    li a2,0x3
    div a0,a0,a2
    li a2,0
    continue1:
    blt a2, a0,  read_must_hit
    ret

    loop_refill:
    lw a3,0x0(a1)
    addi a1,a1,0x4
    addi a2, a2,0x1
    j continue0

    read_must_hit:
    addi a1,a1,-4
    lw a3,0x0(a1)
    addi a2, a2,0x1
    j continue1



