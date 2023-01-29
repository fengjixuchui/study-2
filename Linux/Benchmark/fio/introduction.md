
源码: https://git.kernel.dk/cgit/fio/

git://git.kernel.dk/fio.git

https://git.kernel.dk/fio.git

命令示例:

/root/workspace/fio-3.30/fio -filename=/dev/nvme0n1 -direct=1 -iodepth 32 -rw=read -ioengine=libaio -size=4K -numjobs=4 -cpus_allowed=0-3 -cpus_allowed_policy=split -runtime=300 -name=read

Fio 的入口函数在 `fio.c` 的 main 函数，其结构如下所示:

```cpp
int main(int argc, char *argvO, char *envp0) {
    if(initialize_fio(envp)) // libfio.c 文件————进行 fio 初始化，有 64 位对齐、大端小端模式、hash、文件锁等
        return 1;
    if(fio_server_create_sk_key()) // server.c 文件－为线程创建私有数据 TSD
        goto done;
    if(parse_options(argc,argv)) // read-to-pipe-async 文件 - 解析 main 函数的参数
        goto done_key;
    fio_time_init(); // 初始化时钟相关
    if(nr_clients){
        set_genesis_time();
        if(fio_start_all_clients()) // 与一些驱动进行远程连接操作，例如 SPKD
            goto done_key;
        ret=fio_hanuie_clienis(&tio_cliei.t_ops);
    ｝else
        ret=fio_backend(NULL); // backend.c 文件 fio 逻辑走向，开始处理问题
}
```

```cpp
// libfio.c
int initialize_fio(char *envp[])
{
    endian_check(); // 大小端模式检查
    arch_init(envp); // 架构相关初始化, 主要是检查 tsc 支持, 

```

`fio_server_create_sk_key()` 函数是为线程创建私有数据，关于线程私有数据的概念可以参考 TSD池

```cpp
// server.c
int fio_server_create_sk_key(void)
{
    if (pthread_key_create(&sk_out_key, NULL)) {
            log_err("fio: can't create sk_out backend key\n");
            return 1;
    }

    pthread_setspecific(sk_out_key, NULL);
    return 0;
}
```

接下来, `fio_backend()` 函数:

```cpp
// backend.c
int fio_backend(struct sk_out *sk_out)
{
    ...... // 加载文件、mmap映射、锁初始化、获取时间、创建helper线程
    run_threads(sk_out); // 会建立主要的I0线程
    ...... // 用于一些变量的销毁、环境的收尾
}
```

该函数中最主要的是 `run_threads(sk_out)` 函数，该函数会根据需要启动 jobs 和处理 jobs

```cpp
// backend.c
static void run_threads(struct sk_out *sk_out)
{
    ...... // 在io线程之前设置其他线程、设置信号量、缓冲、检查挂载、设置文件处理顺序、修改线程状态
    while (todo) {
        for_each_td(td, i) {
            ......
            if (td->o.use_thread) {
                ......
            } else {
                pid_t pid;
                void *eo;
                dprint(FD_PROCESS, "will fork\n");
                eo = td->eo;
                read_barrier();
                pid = fork();
                if (!pid) {
                    int ret;

                    ret = (int)(uintptr_t)thread_main(fd); // 建立IO提交过程
                    _exit(ret);
                } else if (i == fio_debug_jobno)
                        *fio_debug_jobp = pid;
                free(eo);
                free(fd);
                fd = NULL;
            }
            dprint(FD_MUTEX, "wait on startup_sem\n");
            if (fio_sem_down_timeout(startup_sem, 10000)) {
                log_err("fio: job startup hung? exiting.\n");
                fio_terminate_threads(TERMINATE_ALL, TERMINATE_ALL);
                fio_abort = true;
                nr_started--;
                free(fd);
                break;
            }
        ...... // 线程状态收尾
}
```

最关键的是 `thread_main(fd)` 函数，其主要是建立了 IO 提交过程;

```cpp
// backend.c
static void *thread_main(void *data)
{
    ...... // 获取任务 pid,初始化时钟、锁，设置 uid,设置优先级（会影响内存分配），参数转换／初始化，
    while (keep_running(td)) {
        ......
        if (td->o.verify_only && td_write(td))
            verify_bytes = do_dry_run(td);
        else {
            do_io(td, bytes_done); // 进行IO的提交和处理过程
            if (!ddir_rw_sum(bytes_done)) {
                fio_mark_td_terminate(td);
                verify_bytes = 0;
            } else {
                verify_bytes = bytes_done[DDIR_WRITE] +
                                bytes_done[DDIR_TRIM];
            }
        }
    }
    ...... //超时保护，线程竞争锁，err处理
}
```

在该函数中，最重要的是 `do_io(td,bytes_done)` 这个函数，其进行 IO 的提交和进一步的处理：

```cpp
static void do_io(struct thread_data *td, uint64_t *bytes_done)
{
    ...... // 写模式字节数计算、10异常判断、验证end_io、记录IO动作
    while ((td->o.read_iolog_file && !flist_empty(&td->io_log_list)) ||
            (!flist_empty(&td->trim_list)) || !io_issue_bytes_exceeded(td) ||
            td->o.time_based) {
        ......
        if (td->o.io_submit_mode == IO_MODE_OFFLOAD) {
            ......
        } else {
            ret = io_u_submit(td, io_u); // 调用实际存储引擎注册的 io_submit 函数
            if (should_check_rate(td))
                td->rate_next_io_time[ddir] = usec_for_io(td, ddir);
            if (io_queue_event(td, io_u, &ret, ddir, &bytes_issued, 0, &comp_time)) // 判断当前是否还有没有处理完的 io events
                break; // 判断是否进一步处理
reap:
            full = queue_full(td) || (ret == FIO_Q_BUSY && td->cur_depth);
            if (full || io_in_polling(td))
                ret = wait_for_completions(td, &comp_time); // 会调用后端实际存储引擎注册的 getevents 函数
        }
        ......
    }
}
```

`do_io` 函数主要进行 `io_u` 的处理和排队，在此过程中会检查速率和错误，其返回被处理完的字节数；该函数中有三处关键点，分别为 `io_u_submit()`、`io_queue_event()` 和 `wait_for_completions()`

首先看 `io_u_submit()` 函数：

```cpp
// backend.c
static enum fio_q_status io_u_submit(struct thread_data *td, struct io_u *io_u)
{
    /*
    * Check for overlap if the user asked us to, and we have
    * at least one IO in flight besides this one.
    */
    // 确保有一个IO运行在队列中
    if (td->o.serialize_overlap && td->cur_depth > 1 &&
        in_flight_overlap(&td->io_u_all, io_u))
        return FIO_Q_BUSY;

    return td_io_queue(td, io_u);
}

// ioengines.c
enum fio_q_status td_io_queue(struct thread_data *td, struct io_u *io_u)
{
    // 检查并释放锁、保存write io、错误处理、O_DIRECT添加警告声明等
}
```

接着看 `io_queue_event()` 函数：

```cpp
// backend.c
int io_queue_event(struct thread_data *td, struct io_u *io_u, int *ret,
        enum fio_ddir ddir, uint64_t *bytes_issued, int from_verify,
        struct timespec *comp_time)
{
    // 根据状态来确定处理逻辑－FIO_Q_COMPLETED/FIO_Q_QUEUED/FIO_Q_BUSY
}
```

接下来看下 `wait_for_completions()` 函数：

特别要关注的是何时收割event的逻辑：当可用来提交 io 请求的空闲槽位都占满了，或者前端有正在执行的 polling 操作的时候，就调用注册的存储引擎的 `get_events` 函数。

```cpp
// backend.c
static int wait_for_completions(struct thread_data *td, struct timespec *time)
{
    /*
    * if the queue is full, we MUST reap at least 1 event
    */
    // 队列满，则处理一个事件
    min_evts = min(td->o.iodepth_batch_complete_min, td->cur_depth);
    if ((full && !min_evts) || !td->o.iodepth_batch_complete_min)
            min_evts = 1;

    if (time && should_check_rate(td))
        fio_gettime(time, NULL);
    do {
        ret = io_u_queued_complete(td, min_evts); // io_u.c文件
        if (ret < 0)
                break;
    } while (full && (td->cur_depth > td->o.iodepth_low));
}

// io_u.c
// 调用异步10引擎来完成 min_events 事件
int io_u_queued_complete(struct thread_data *td, int min_evts)
{
    ret = td_io_getevents(td, min_evts, td->o.iodepth_batch_complete_max, tvp); // ioengines.c 文件－修复min_evts的min和max
}
```

上面就是fio的大概框架，更具体的需要研究每一个函数的细枝末节

# reference

https://blog.csdn.net/weixin_38428439/article/details/121642171
