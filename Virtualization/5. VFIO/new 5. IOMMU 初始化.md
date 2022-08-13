
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 架构](#1-架构)
- [2. IOMMU 驱动初始化](#2-iommu-驱动初始化)
- [3. 设备分组](#3-设备分组)
- [4. IOMMU 的作用和效果](#4-iommu-的作用和效果)
- [5. reference](#5-reference)

<!-- /code_chunk_output -->

# 1. 架构

IOMMU 驱动所处的位置位于 DMA 驱动之上, 其上又封装了一层 VFIO 驱动框架, 便于用户空间编写设备驱动直接调用底层的api操作设备.

```
                   +-------------+
                   | QEMU/CROSVM |
                   +-------------+
                          |
        .-----------------|--------------.
........|.................|..............|..........
        |                 |              |
 +---------------+  +-----------+  +-----------+
 | container API |  | group API |  | device API |
 +---------------+  +-----------+  +-----------+
        |                 |              |
        '-----------------|--------------'
                          |
                          v
                   +-------------+
                   | VFIO driver |
                   +-------------+
                          |
                          v
                .---------'---------.
                |                   |
                v                   v
         +-------------+     +--------------+
         | SMMU driver |     | IOMMU driver |
         +-------------+     +--------------+
	        |                   |
                '-------------------'
                          |
                          v
                    +------------+
                    | DMA driver |
                    +------------+
                          |
     .--------------------'--------------------.
     |             |             |             |
     v             v             v             v
+----------+  +----------+  +----------+  +----------+
|  Device  |  |  Device  |  |  Device  |  |  Device  |
+----------+  +----------+  +----------+  +----------+
```

# 2. IOMMU 驱动初始化

内核在启动的时候就会**初始化好设备的信息**, 给**设备**分配相应的 **iommu group**, 其过程如下.

系统启动的时候会执行 `iommu_init` 函数进行内核对象 iommu 的初始化. 主要是调用了 `kset_create_and_add` 函数创建了 `iommu_groups` 对象. 在 `/sys/kernel` 目录下会出现 `iommu_groups` 目录.

可以使用内核调试方法, 在 `iommu_init` 函数处打断点, 查看系统对iommu初始化的过程.

![2021-10-21-11-50-13.png](./images/2021-10-21-11-50-13.png)

注意需要内核打开相应的配置开关才能使得IOMMU功能生效.

<table style="width:100%">
<caption>内核配置选项</caption>
  <tr>
    <th>体系结构</th>
    <th>配置项</th>
  </tr>
  <tr>
    <td>armv1/v2</td>
    <td>CONFIG_ARM_SMMU</td>
  </tr>
  <tr>
    <td>armv3</td>
    <td>CONFIG_ARM_SMMU_V3</td>
  </tr>
  <tr>
    <td>intel x86</td>
    <td>CONFIG_INTEL_IOMMU</td>
  </tr>
  <tr>
    <td>amd x86</td>
    <td>CONFIG_AMD_IOMMU</td>
  </tr>
</table>

# 3. 设备分组



# 4. IOMMU 的作用和效果

iommu实现了类似MMU的功能, 主要是做地址翻译. 其主要通过底层的DMA api来实现设备地址空间的映射. 其最终效果类似于下图:

```
               CPU                  CPU                  Bus
             Virtual              Physical             Address
             Address              Address               Space
              Space                Space

            +-------+             +------+             +------+
            |       |             |MMIO  |   Offset    |      |
            |       |  Virtual    |Space |   applied   |      |
          C +-------+ --------> B +------+ ----------> +------+ A
            |       |  mapping    |      |   by host   |      |
  +-----+   |       |             |      |   bridge    |      |   +--------+
  |     |   |       |             +------+             |      |   |        |
  | CPU |   |       |             | RAM  |             |      |   | Device |
  |     |   |       |             |      |             |      |   |        |
  +-----+   +-------+             +------+             +------+   +--------+
            |       |  Virtual    |Buffer|   Mapping   |      |
          X +-------+ --------> Y +------+ <---------- +------+ Z
            |       |  mapping    | RAM  |   by IOMMU
            |       |             |      |
            |       |             |      |
            +-------+             +------+
```

这里存在三种地址, 虚拟地址空间, 物理地址空间, 总线地址空间. 从 CPU 的视角看到的是虚拟机地址空间, 如我们调用 `kmalloc`、`vmalloc` 分配的都是**虚拟地址空间**. 然后通过 **MMU** 转换成 ram 或寄存器中的**物理地址**. 如 `C->B` 的过程. 物理地址可以在 `/proc/iomem` 中查看.

IO 设备通常使用的是总线地址, 在一些系统上, 总线地址就等于物理地址. 但是通常有 iommu 和南桥的设备则会做总线地址到物理地址之间的映射.

如上图 A->C 未进行DMA的过程, 内核首先扫到 IO 设备和他们的 MMIO 空间以及将设备挂到系统上的 host bridge 信息. 假如设备有一个 BAR, 内核从 BAR 中读取总线地址A, 然后转换成物理地址B. 物理地址B可以在 `/proc/iomem` 中查看到. 当驱动挂载到设备上时, 调用 `ioremap( )` 将物理地址B转换成虚拟地址C. 之后就可以通过读写C的地址来访问到最终的设备寄存器A的地址.

如上图 `X->Y`, `Z->Y` 使用DMA的过程, 驱动首先使用 kmalloc 或类似接口分配一块缓存空间即地址X, 内存管理系统会将X映射到 ram 中的物理地址Y. 设备本身不能使用类似的方式映射到同一块物理地址空间, 因为 DMA 没有使用 MMU 内存管理系统. 在一些系统上, 设备可以直接 DMA 到物理地址Y, 但是通常有 IOMMU 硬件的系统会 DMA 设备到地址Z, 然后通过IOMMU转换到物理地址Y. 这是因为调用 DMA API 的时候, 驱动将**虚拟地址**X传给类似 `dma_map_single( )` 的接口后, 会建立起必须的IOMMU映射关系, 然后返回DMA需要映射的地址Z. 驱动然后通知设备做DMA映射到地址Z, 最后 IOMMU 映射地址Z到ram中的缓存地址Y.

从上面的两个例子中客户看出, IOMMU硬件的存在会加速地址的转换速度, 从X->Y是通过CPU完成的, 而Z->Y则是通过IOMMU硬件完成. 同时能够做到安全, IOMMU会校验Y->Z地址的合法性, 避免了直接DMA到Y可能带来的安全问题.




# 5. reference

https://www.kernel.org/doc/Documentation/DMA-API-HOWTO.txt

https://www.blogsebastian.cn/?p=116