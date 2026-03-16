/*
 * Copyright (c) 2006-2019, RT-Thread Development Team
 * Copyright (c) 2019-Present Nuclei Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2020-11-24     Wu Han    RTT MSH Demo
 * 2020-11-27     Wu Han    Adapted for Nuclei SDK
 */

#include <rtthread.h>
#ifdef RT_USING_DFS
#include <dfs_fs.h>
#include <dfs_ramfs.h>
#include <dfs_posix.h>

/* 内存池 */
static rt_uint8_t ramfs_pool[4096];
#endif

int main(void)
{
    
    rt_kprintf("Hello RT-Thread!\n");
	#ifdef RT_USING_DFS
    struct dfs_ramfs *ramfs;
    int result;
    int fd;
    /* 1. 创建 ramfs 实例 */
    ramfs = dfs_ramfs_create(ramfs_pool, sizeof(ramfs_pool));
    if (ramfs == RT_NULL)
    {
        rt_kprintf("[FAIL] ramfs create failed\n");
        return -1;
    }
    rt_kprintf("[OK] ramfs created\n");
    
    /* 2. 挂载 ramfs 到根目录 */
    result = dfs_mount(RT_NULL, "/", "ram", 0, ramfs);
    if (result == 0)
    {
        rt_kprintf("[OK] ramfs mounted to /\n");
    }
    else
    {
        rt_kprintf("[FAIL] mount failed: %d\n", result);
        return -1;
    }
    
    /* 3. 创建并写入文件 */
    fd = open("/test.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd >= 0)
    {
        const char *msg = "Hello RT-Thread FileSystem!";
        write(fd, msg, rt_strlen(msg));
        close(fd);
        rt_kprintf("[OK] /test.txt created\n");
    }
    else
    {
        rt_kprintf("[FAIL] create /test.txt failed\n");
        return -1;
    }
    
    /* 4. 读取文件 */
    fd = open("/test.txt", O_RDONLY);
    if (fd >= 0)
    {
        char buf[64] = {0};
        int len = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        rt_kprintf("[OK] Read %d bytes: %s\n", len, buf);
    }
    else
    {
        rt_kprintf("[FAIL] open /test.txt for read failed\n");
        return -1;
    }
    
    rt_kprintf("\n=== ramfs Ready ===\n");
    #endif 
    return 0;
}