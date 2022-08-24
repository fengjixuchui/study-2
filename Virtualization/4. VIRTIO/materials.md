
specification: https://github.com/oasis-tcs/virtio-spec



VirtIO实现原理——PCI基础: https://blog.csdn.net/huang987246510/article/details/103379926

Linux虚拟化KVM-Qemu分析(九)之virtio设备: https://www.cnblogs.com/LoyenWang/p/14399642.html

qemu Virtio设备创建流程: https://www.blogsebastian.cn/?p=58



逻辑清晰: https://blog.csdn.net/huang987246510/category_9626816.html


virtio前端通知机制分析: http://lihanlu.cn/virtio-frontend-kick/

VIRTIO VRING工作机制分析: https://oenhan.com/virtio-vring

virtIO前后端notify机制详解: https://www.cnblogs.com/ck1020/p/6066007.html

VirtIO实现原理——前端通知机制(core): https://blog.csdn.net/huang987246510/article/details/105496843




---

https://blog.csdn.net/qq_20817327/article/details/106655211

qemu 有个参数配置 queues 的数目

```
-device virtio-blk-pci,num-queues=2
```

虚拟机内部查看如下: 

```
root@ubuntu:/sys/block/vdb# ll mq/
total 0
drwxr-xr-x  4 root root 0 Jun 22 03:36 ./
drwxr-xr-x 10 root root 0 Jun 22 03:34 ../
drwxr-xr-x  6 root root 0 Jun 22 03:36 0/
drwxr-xr-x  6 root root 0 Jun 22 03:36 1/
```

多队列可以提高IO性能, 默认多队列个数与vcpu个数相同, 让每个vcpu可以处理一个队列, 当虚拟机IO压力大的时候, IO数据可以平均到各个队列分别让每个cpu单独处理, 从而提高传输效率

---

