#ifndef CFG_HAS_MMU
#error "This case require CPU mmu feature"
#endif
#if __riscv_xlen != 64
#error "This case require CPU xlen = 64"
#endif
