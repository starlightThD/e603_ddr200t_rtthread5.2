    #include "check_cpufeature.h"
.text
.global dcache_lock_operation
dcache_lock_operation:
    //a0 = addr  a1 = success
//lock
        li a2, 0x3
        csrw ccm_mbeginaddr, a0
        csrw ccm_mcommand, a2
        csrr a2,ccm_mdata 
        bne a1,a2, lock_fail
        ret

        lock_fail:
        li a0, 1 

.global dcache_unlock_operation
dcache_unlock_operation:
    //a0 = addr  a1 = success
//lock
        li a2, 0x4
        csrw ccm_mbeginaddr, a0
        csrw ccm_mcommand, a2
        ret






