
这些年依赖 I/O Virtualization 的发展路线:

![2023-02-28-13-27-43.png](./images/2023-02-28-13-27-43.png)

IO 设备虚拟化经历了从**全虚拟化**(`full-virtualization`)到**半虚拟化**(`para-virtualization`), 到**设备直通**的变革.

Intel® Virtualization Technology for Directed I/O(Intel VT-d)是英特尔发布的 IO 虚拟化技术. 通过 Intel VT-d, 可以把物理设备直通(pass-through)给虚拟机, 使虚拟机直接访问物理设备, 其性能近似无虚拟机环境下的 IO 性能.

**SR-IOV**(`Single Root I/O Virtualization and Sharing`)是 **PCI 标准组织**制定的在 PCI 设备级对虚拟化进行的支持. 基于 PCI SR-IOV 技术, 同一个 PCIe 设备可以实现逻辑上隔离的多个轻量级 "PF(physical function)" —— VF(`virtual function`) . 同一个 PF 创建的多个 VF 可以独立隔离地分配给不同的虚拟机或者容器, 极大地提高了性能和资源使用效率. 高性能 IO 设备如网卡、存储、GPU 等都支持 SR-IOV.

随着**容器**的广泛使用, 实例的密度增加, 使用 VF 存在以下限制:

1)可扩展性差: 由于 VF 是通过 BDF 号进行隔离的, 所以**每个 VF** 都需要**各自的配置空间**, 由此产生的**额外开销较大**; 且硬件资源上的 **VF 数量有限**, 比如英特尔 E810 的网卡可以创建的最大 VF 数量为 256 个.

2)灵活性不好: VF 资源需要在**使用前一次性创建**和销毁所有的实例.

3)设备快照不容易创建: 因为**设备是直通给虚拟机**的, **hypervisor** 对于**设备状态是无感知的**, 因此难以记录设备状态.

Intel® Scalable I/O Virtualization(Intel 可扩展 IOV)是针对下一代 CPU 服务器平台的虚拟化解决方案, 是一种硬件辅助的 I/O 设备直通技术. 它采用了现有的 PCI Express 功能结构, 实现了高性能和更灵活的 I/O 设备共享的架构.

https://mp.weixin.qq.com/s?__biz=MzI3NDA4ODY4MA==&mid=2653338642&idx=1&sn=7d21d5bb7b69280a0d0321292c44b9ec&chksm=f0cb4b95c7bcc2831c76e5963b2b80c1abe46f888e004a8cdc1469014a053599993eebc3ca7c

















