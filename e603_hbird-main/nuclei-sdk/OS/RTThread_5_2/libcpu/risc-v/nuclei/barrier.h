#ifndef RISCV_BARRIERS_H
#define RISCV_BARRIERS_H

/* 基础宏定义 - 这些是必需的依赖 */
#define __RT_STRINGIFY(x...) #x
#define RT_STRINGIFY(x...)   __RT_STRINGIFY(x)

/* 核心屏障宏 */
#define rt_hw_barrier(cmd, ...) \
    __asm__ volatile(RT_STRINGIFY(cmd) " " RT_STRINGIFY(__VA_ARGS__)::: "memory")

/* RISC-V 内存屏障宏 */
#define rt_hw_isb() rt_hw_barrier(fence.i)        /* 指令同步屏障 */
#define rt_hw_dmb() rt_hw_barrier(fence, rw, rw)  /* 数据内存屏障 */
#define rt_hw_wmb() rt_hw_barrier(fence, w, w)    /* 写内存屏障 */
#define rt_hw_rmb() rt_hw_barrier(fence, r, r)    /* 读内存屏障 */
#define rt_hw_dsb() rt_hw_barrier(fence, rw, rw)  /* 数据同步屏障 */

/* 通用内存屏障 (可选) */
#ifndef barrier
#define barrier() __asm__ __volatile__("fence" : : : "memory")
#endif

#endif /* RISCV_BARRIERS_H */