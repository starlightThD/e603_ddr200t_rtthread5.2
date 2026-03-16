INCDIRS += $(NUCLEI_SDK_RTOS)/include
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/src

INCDIRS += $(NUCLEI_SDK_RTOS)/include/klibc
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/src/klibc

ASM_SRCDIRS += $(NUCLEI_SDK_RTOS)/libcpu/risc-v/nuclei/gcc


INCDIRS += $(NUCLEI_SDK_RTOS)/libcpu/risc-v/nuclei
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/libcpu/risc-v/nuclei

INCDIRS += $(NUCLEI_SDK_RTOS)/components

INCDIRS += $(NUCLEI_SDK_RTOS)/components/finsh
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/finsh

INCDIRS += $(NUCLEI_SDK_RTOS)/components/mm
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/mm

INCDIRS += $(NUCLEI_SDK_RTOS)/components/dfs/dfs_v1/include
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/dfs/dfs_v1/src

INCDIRS += $(NUCLEI_SDK_RTOS)/components/dfs/dfs_v1/filesystems/ramfs
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/dfs/dfs_v1/filesystems/ramfs

INCDIRS += $(NUCLEI_SDK_RTOS)/components/libc/compilers/common/include
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/libc/compilers/common

INCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/include
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/core
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/serial
INCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/include/drivers

INCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/include/ipc
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/ipc


#INCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/ofw
#INCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/ofw/libfdt
#C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/ofw
#C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/ofw/libfdt
#C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/drivers/serial

INCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/avl
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/avl
INCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/bitmap
INCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/hashmap
INCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/ref
INCDIRS += $(NUCLEI_SDK_RTOS)/components/utilities/libadt/uthash

INCDIRS += $(NUCLEI_SDK_RTOS)/components/legacy/fdt
C_SRCDIRS += $(NUCLEI_SDK_RTOS)/components/legacy/fdt