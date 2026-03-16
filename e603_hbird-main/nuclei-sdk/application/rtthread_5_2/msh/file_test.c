#include <rtthread.h>
#ifdef RT_USING_DFS
#include <dfs_posix.h>

#define THREAD_STACK_SIZE 1024
#define THREAD_PRIORITY   10
#define THREAD_TIMESLICE  10
#define TEST_COUNT        50

static rt_sem_t write_sem;
static rt_sem_t read_sem;

static void writer_thread(void *parameter)
{
    int fd;
    char msg[64];
    for (int i = 0; i < TEST_COUNT; i++)
    {
        rt_snprintf(msg, sizeof(msg), "Thread Write Test! [%d]", i);
        fd = open("/thread_test.txt", O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd >= 0)
        {
            write(fd, msg, rt_strlen(msg));
            write(fd, "\n", 1);
            close(fd);
            rt_kprintf("[Writer] Write success: %d\n", i);
        }
        else
        {
            rt_kprintf("[Writer] Write failed\n");
        }
        rt_sem_release(read_sem); // 通知读线程可以读
        rt_sem_take(write_sem, RT_WAITING_FOREVER); // 等待读线程读完
    }
}

static void reader_thread(void *parameter)
{
    int fd;
    char buf[64] = {0};
    int offset = 0;
    for (int i = 0; i < TEST_COUNT; i++)
    {
        rt_sem_take(read_sem, RT_WAITING_FOREVER); // 等待写线程写完
        fd = open("/thread_test.txt", O_RDONLY);
        if (fd >= 0)
        {
            lseek(fd, offset, SEEK_SET);
            int len = 0, total = 0;
            // 只读一行
            while ((len = read(fd, buf + total, 1)) == 1)
            {
                total++;
                if (buf[total - 1] == '\n' || total >= sizeof(buf) - 1)
                    break;
            }
            buf[total] = '\0';
            offset += total;
            close(fd);
            rt_kprintf("[Reader] Read %d bytes: %s", total, buf);
        }
        else
        {
            rt_kprintf("[Reader] Read failed\n");
        }
        rt_sem_release(write_sem); // 通知写线程可以继续写
    }
    rt_kprintf("File thread test finished!\n");
}

int file_test(void)
{
    rt_kprintf("RT-Thread File Thread Test Start!\n");

    write_sem = rt_sem_create("write_sem", 0, RT_IPC_FLAG_PRIO);
    read_sem = rt_sem_create("read_sem", 0, RT_IPC_FLAG_PRIO);

    rt_thread_t tid_writer = rt_thread_create("writer", writer_thread, RT_NULL,
                                             THREAD_STACK_SIZE, THREAD_PRIORITY, THREAD_TIMESLICE);
    rt_thread_t tid_reader = rt_thread_create("reader", reader_thread, RT_NULL,
                                             THREAD_STACK_SIZE, THREAD_PRIORITY, THREAD_TIMESLICE);

    if (tid_writer) rt_thread_startup(tid_writer);
    if (tid_reader) rt_thread_startup(tid_reader);

    // 启动时先让写线程写
    rt_sem_release(write_sem);

    return 0;
}
MSH_CMD_EXPORT(file_test, RT-Thread file thread test)
#endif