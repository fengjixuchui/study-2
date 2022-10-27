
# 背景

## IOMMU Recap

![2022-10-27-10-59-46.png](./images/2022-10-27-10-59-46.png)

IOMMU: (I/O Memory Management Unit)

IOMMU 用来将支持 DMA 的 I/O 总线连接到系统内存, [参考](https://en.wikipedia.org/wiki/Input%E2%80%93output_memory_management_unit)

IOVA(I/O Virtual Address) 用于 DMA

I/O 页表用于 IOVA 到 PA 的转换

DMA isolation:

![2022-10-27-11-10-09.png](./images/2022-10-27-11-10-09.png)




## Userspace Driver Recap




## Changes for software



# reference

https://lkml.org/lkml/2021/9/19/17

IOMMUFD：选择将IOMMU的改进应用于用户空间驱动程序: 附件 

