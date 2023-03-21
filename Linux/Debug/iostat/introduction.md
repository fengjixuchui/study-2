iostat 用于报告**中央处理器(CPU)统计信息**和整个系统、适配器、tty 设备、磁盘和 CD\-ROM 的输入/输出统计信息, 默认显示了与vmstat相同的cpu使用信息

```
[root@gerry ~]# iostat -d 2 3
Linux 3.10.0-957.27.2.el7.x86_64 (gerry) 	2019年08月19日 	_x86_64_	(4 CPU)

Device:            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda              25.45       852.88       807.15   51703735   48931304
dm-0             26.06       851.46       803.85   51617441   48731539
dm-1              0.98         0.93         3.04      56404     184244

Device:            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda               0.50         4.00         0.00          8          0
dm-0              0.50         4.00         0.00          8          0
dm-1              0.00         0.00         0.00          0          0

Device:            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda               0.00         0.00         0.00          0          0
dm-0              0.00         0.00         0.00          0          0
dm-1              0.00         0.00         0.00          0          0
```

对上面每项的输出解释如下: 

- Blk\_read/s表示每秒读取的数据块数. 
- Blk\_wrtn/s表示每秒写入的数据块数. 
- Blk\_read表示读取的所有块数. 
- Blk\_wrtn表示写入的所有块数. 

1 可以通过Blk\_read/s和Blk\_wrtn /s的值对磁盘的读写性能有一个基本的了解, 如果Blk_wrtn/s值很大, 表示磁盘的写操作很频繁, 可以考虑优化磁盘或者优化程序, 如果 Blk\_read/s值很大, 表示磁盘直接读取操作很多, 可以将读取的数据放入内存中进行操作. 

2 对于这两个选项的值没有一个固定的大小, 根据系统应用的不同, 会有不同的值, 但是有一个规则还是可以遵循的: 长期的、超大的数据读写, 肯定是不正常的, 这种情况一定会影响系统性能. 

使用以下命令显示扩展的设备统计: 

```
[root@localhost ~]# iostat -dx 5
Linux 3.10.0-957.5.1.el7.x86_64 (localhost.localdomain) 	2019年04月04日 	_x86_64_	(12 CPU)

Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
sda               0.00     0.00    0.00    0.00     0.01     0.00    34.98     0.00    1.27    0.97   10.21   1.18   0.00
sdb               0.00     0.02    0.08    0.60     5.50     6.80    35.99     0.00    0.58    0.99    0.52   0.35   0.02
dm-0              0.00     0.00    0.04    0.56     0.93     6.33    24.29     0.00    0.56    0.50    0.57   0.38   0.02
dm-1              0.00     0.00    0.00    0.00     0.01     0.00    57.06     0.00    0.50    0.50    0.00   0.33   0.00
dm-2              0.00     0.00    0.04    0.02     4.50     0.44   158.03     0.00    1.21    1.40    0.72   0.25   0.00



Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
sda               0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00
sdb               0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00
dm-0              0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00
dm-1              0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00
dm-2              0.00     0.00    0.00    0.00     0.00     0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00

^C
```

第一个显示的是自系统启动以来的平均值, 然后显示**增量的平均值**, 每个设备一行. 

常见**linux的磁盘IO指标的缩写习惯**: **rq是request**, **r是read**, **w是write**, **qu是queue**, **sz是size**, **a是average**, **tm是time**, **svc是service**. 

rrqm/s 和 wrqm/s: 每秒**合并的读和写请求**, "合并的"意味着**操作系统**从**队列**中拿出**多个逻辑请求合并为一个请求**到实际磁盘. 

r/s和w/s: 每秒**发送到设备**的读和写请求数. 

rsec/s和wsec/s: 每秒**读和写的扇区数**. 

avgrq–sz: 请求的扇区数. 

avgqu–sz: 在**设备队列**中**等待的请求数**. 

await: 每个IO请求花费的时间. 

svctm: 实际请求(服务)时间. 

%util: 至少有一个活跃请求所占时间的百分比. 

- Blk\_read/s表示每秒读取的数据块数. 
- Blk\_wrtn/s表示每秒写入的数据块数. 
- Blk\_read表示读取的所有块数. 
- Blk\_wrtn表示写入的所有块数. 





rrqms: 每秒这个设备相关的读取请求有多少被Merge了(当系统调用需要读取数据的时候, VFS将请求发到各个FS, 如果FS发现不同的读取请求读取的是相同Block的数据, FS会将这个请求合并Merge)
wrqm/s: 每秒这个设备相关的写入请求有多少被Merge了. 
rsec/s: The number of sectors read from the device per second.
wsec/s: The number of sectors written to the device per second.
rKB/s: The number of kilobytes read from the device per second.
wKB/s: The number of kilobytes written to the device per second.
avgrq-sz: 平均请求扇区的大小,The average size (in sectors) of the requests that were issued to the device.
avgqu-sz: 是平均请求队列的长度. 毫无疑问, 队列长度越短越好,The average queue length of the requests that were issued to the device.   
await: 每一个IO请求的处理的平均时间(单位是微秒毫秒). 这里可以理解为IO的响应时间, 一般地系统IO响应时间应该低于5ms, 如果大于10ms就比较大了. 这个时间包括了队列时间和服务时间, 也就是说, 一般情况下, await大于svctm, 它们的差值越小, 则说明队列时间越短, 反之差值越大, 队列时间越长, 说明系统出了问题. 
svctm: 表示平均每次设备I/O操作的服务时间(以毫秒为单位). 如果svctm的值与await很接近, 表示几乎没有I/O等待, 磁盘性能很好. 如果await的值远高于svctm的值, 则表示I/O队列等待太长, 系统上运行的应用程序将变慢. 
%util:  在统计时间内所有处理IO时间, 除以总共统计时间. 例如, 如果统计间隔1秒, 该设备有0.8秒在处理IO, 而0.2秒闲置, 那么该设备的%util = 0.8/1 = 80%, 所以该参数暗示了设备的繁忙程度, 一般地, 如果该参数是100%表示磁盘设备已经接近满负荷运行了(当然如果是多磁盘, 即使%util是100%, 因为磁盘的并发能力, 所以磁盘使用未必就到了瓶颈). 



