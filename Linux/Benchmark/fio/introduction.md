
源码: https://git.kernel.dk/cgit/fio/

git://git.kernel.dk/fio.git

https://git.kernel.dk/fio.git

Fio 的入口函数在 `fio.c` 的 main 函数，其结构如下所示:

```cpp
int main(int argc, char *argvO, char *envp0) {
    if(initialize_fio(envp)) // libfio.c 文件————进行 fio 初始化，有 64 位对齐、大端小端模式、hash、文件锁等
        return 1;
    if(fio_server_create_sk_key()) // server.c 文件－为线程创建私有数据 TSD 池
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

`fio_server_create_sk_key()` 函数是为线程创建私有数据，关于线程私有数据的概念可以参考该链接 - https://www.cnblogs.com/smarty/p/4046215.html;

`fio_backend()` 函数—— `backend.c` 文件：











