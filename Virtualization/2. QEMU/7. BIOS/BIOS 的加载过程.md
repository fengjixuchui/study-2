
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 简介](#1-简介)
  - [1.1. BIOS 二进制文件](#11-bios-二进制文件)
  - [1.2. BIOS 子模块源码](#12-bios-子模块源码)
  - [1.3. Makefile 中关于 BIOS 的拷贝操作](#13-makefile-中关于-bios-的拷贝操作)
- [2. QEMU 加载 BIOS 过程分析](#2-qemu-加载-bios-过程分析)
  - [2.1. x86_64 QEMU 中支持的类型](#21-x86_64-qemu-中支持的类型)
  - [2.2. QEMU 中 MemoryRegion 结构体](#22-qemu-中-memoryregion-结构体)
  - [2.3. 清单 6 old_pc_system_rom_init 函数中将 BIOS 映射到物理内存空间的代码:](#23-清单-6-old_pc_system_rom_init-函数中将-bios-映射到物理内存空间的代码)
- [3. 小结](#3-小结)

<!-- /code_chunk_output -->

https://www.linuxidc.com/Linux/2014-12/110472.htm

本文将介绍 QEMU 代码中使用到的 BIOS, 通过分析 QEMU 代码, 讲解 BIOS 是如何加载到虚拟机的物理内存.

# 1. 简介

BIOS 提供**主板或者显卡**的**固件信息**以及**基本输入输出功能**, QEMU 使用的是一些开源的项目, 如 Bochs、openBIOS 等.

QEMU 中使用到的 BIOS 以及固件一部分以**二进制文件的形式**保存在**源码树的 pc-bios 目录下**, pc-bios 目录里包含了 QEMU 使用到的**固件**.

还有一些 BIOS 以 **git 源代码子模块**的形式**保存在 QEMU 的源码仓库**中, 当编译 QEMU 程序的时候, 也同时编译出这些 BIOS 或者固件的二进制文件.

QEMU 支持多种启动方式, 比如说 efi、pxe 等, 都包含在该目录下, 这些都需要特定 BIOS 的支持.

## 1.1. BIOS 二进制文件

```
# ls pc-bios/
bamboo.dtb                      efi-e1000.rom                           optionrom                 README
bamboo.dts                      efi-eepro100.rom                        palcode-clipper           s390-ccw
bios-256k.bin                   efi-ne2k_pci.rom                        petalogix-ml605.dtb       s390-ccw.img
bios.bin                        efi-pcnet.rom                           petalogix-ml605.dts       s390-netboot.img
bios-microvm.bin                efi-rtl8139.rom                         petalogix-s3adsp1800.dtb  skiboot.lid
canyonlands.dtb                 efi-virtio.rom                          petalogix-s3adsp1800.dts  slof.bin
canyonlands.dts                 efi-vmxnet3.rom                         pvh.bin                   u-boot.e500
descriptors                     hppa-firmware.img                       pxe-e1000.rom             u-boot-sam460-20100605.bin
edk2-aarch64-code.fd.bz2        keymaps                                 pxe-eepro100.rom          vgabios-ati.bin
edk2-arm-code.fd.bz2            kvmvapic.bin                            pxe-ne2k_pci.rom          vgabios.bin
edk2-arm-vars.fd.bz2            linuxboot.bin                           pxe-pcnet.rom             vgabios-bochs-display.bin
edk2-i386-code.fd.bz2           linuxboot_dma.bin                       pxe-rtl8139.rom           vgabios-cirrus.bin
edk2-i386-secure-code.fd.bz2    meson.build                             pxe-virtio.rom            vgabios-qxl.bin
edk2-i386-vars.fd.bz2           multiboot.bin                           qboot.rom                 vgabios-ramfb.bin
edk2-licenses.txt               multiboot_dma.bin                       QEMU,cgthree.bin          vgabios-stdvga.bin
edk2-riscv-code.fd.bz2          npcm7xx_bootrom.bin                     qemu_logo.svg             vgabios-virtio.bin
edk2-riscv-vars.fd.bz2          openbios-ppc                            qemu-nsis.bmp             vgabios-vmware.bin
edk2-x86_64-code.fd.bz2         openbios-sparc32                        qemu-nsis.ico             vof
edk2-x86_64-microvm.fd.bz2      openbios-sparc64                        qemu.rsrc                 vof.bin
edk2-x86_64-secure-code.fd.bz2  opensbi-riscv32-generic-fw_dynamic.bin  QEMU,tcx.bin              vof-nvram.bin
efi-e1000e.rom                  opensbi-riscv64-generic-fw_dynamic.bin  qemu_vga.ndrv
```

## 1.2. BIOS 子模块源码

```
$ cat .gitmodules
[submodule "roms/seabios"]
        path = roms/seabios
        url = https://gitlab.com/qemu-project/seabios.git/
[submodule "roms/SLOF"]
        path = roms/SLOF
        url = https://gitlab.com/qemu-project/SLOF.git
[submodule "roms/ipxe"]
        path = roms/ipxe
        url = https://gitlab.com/qemu-project/ipxe.git
[submodule "roms/openbios"]
        path = roms/openbios
        url = https://gitlab.com/qemu-project/openbios.git
[submodule "roms/qemu-palcode"]
        path = roms/qemu-palcode
        url = https://gitlab.com/qemu-project/qemu-palcode.git
[submodule "roms/u-boot"]
        path = roms/u-boot
        url = https://gitlab.com/qemu-project/u-boot.git
[submodule "roms/skiboot"]
        path = roms/skiboot
        url = https://gitlab.com/qemu-project/skiboot.git
[submodule "roms/QemuMacDrivers"]
        path = roms/QemuMacDrivers
        url = https://gitlab.com/qemu-project/QemuMacDrivers.git
[submodule "roms/seabios-hppa"]
        path = roms/seabios-hppa
        url = https://gitlab.com/qemu-project/seabios-hppa.git
[submodule "roms/u-boot-sam460ex"]
        path = roms/u-boot-sam460ex
        url = https://gitlab.com/qemu-project/u-boot-sam460ex.git
[submodule "roms/edk2"]
        path = roms/edk2
        url = https://gitlab.com/qemu-project/edk2.git
[submodule "roms/opensbi"]
        path = roms/opensbi
        url =   https://gitlab.com/qemu-project/opensbi.git
[submodule "roms/qboot"]
        path = roms/qboot
        url = https://gitlab.com/qemu-project/qboot.git
[submodule "roms/vbootrom"]
        path = roms/vbootrom
        url = https://gitlab.com/qemu-project/vbootrom.git
[submodule "tests/lcitool/libvirt-ci"]
        path = tests/lcitool/libvirt-ci
        url = https://gitlab.com/libvirt/libvirt-ci.git
```

当源代码编译 QEMU 时候, QEMU 的 Makefile 会将这些二进制文件拷贝到 QEMU 的数据文件目录中.

## 1.3. Makefile 中关于 BIOS 的拷贝操作

```
ifneq ($(BLOBS),)
    set -e; for x in $(BLOBS); do \
        $(INSTALL_DATA) $(SRC_PATH)/pc-bios/$$x "$(DESTDIR)$(qemu_datadir)"; \
    done
endif
```

# 2. QEMU 加载 BIOS 过程分析

当 QEMU 用户空间进程开始启动时, QEMU 进程会根据所**传递的参数**以及当前**宿主机平台类型(host 类型)**, 自动加载适当的 BIOS 固件.

QEMU 进程启动初始阶段, 会通过 `module_call_init` 函数调用 `qemu_register_machine` 注册**该平台支持的全部机器类型**, 接着调用 `find_default_machine` **选择一个默认的机型**进行初始化.  以 QEMU 代码(1.7.0)的 x86_64 平台为例, 支持的机器类型有:

## 2.1. x86_64 QEMU 中支持的类型

```
pc-q35-1.7 pc-q35-1.6 pc-q35-1.5 pc-q35-1.4 pc-i440fx-1.7 pc-i440fx-1.6 pc-i440fx-1.5
pc-i440fx-1.4 pc-1.3 pc-1.2 pc-1.1 pc-1.0 pc-0.15 pc-0.14
pc-0.13    pc-0.12    pc-0.11    pc-0.10    isapc
```

代码中使用的默认机型为 pc-i440fx-1.7, 使用的 BIOS 文件为:

```
pc-bios/bios.bin
Default machine name : pc-i440fx-1.7
bios_name = bios.bin
```

pc-i440fx-1.7 解释为 QEMU 模拟的是 INTEL 的 i440fx 硬件芯片组, 1.7 为 QEMU 的版本号. **找到默认机器之后, 为其初始化物理内存**, QEMU 首先**申请一块内存空间用于模拟虚拟机的物理内存空间**, 申请完好内存之后, 根据不同平台或者启动 QEMU 进程的参数, 为虚拟机的**物理内存初始化**. 具体函数调用过程见图 1.

图 1. QEMU 硬件初始化函数调用流程图:

![config](images/2.jpg)

在 QEMU 中, 整个物理内存以一个结构体 struct MemoryRegion 表示, 具体定义见清单 5.

## 2.2. QEMU 中 MemoryRegion 结构体

```
struct MemoryRegion {
    /* All fields are private - violators will be prosecuted */
    const MemoryRegionOps *ops;
    const MemoryRegionIOMMUOps *iommu_ops;
    void *opaque;
    struct Object *owner;
    MemoryRegion *parent;
    Int128 size;
    hwaddr addr;
    void (*destructor)(MemoryRegion *mr);
    ram_addr_t ram_addr;
    bool subpage;
    bool terminates;
    bool romd_mode;
    bool ram;
    bool readonly; /* For RAM regions */
    bool enabled;
    bool rom_device;
    bool warning_printed; /* For reservations */
    bool flush_coalesced_mmio;
    MemoryRegion *alias;
    hwaddr alias_offset;
    unsigned priority;
    bool may_overlap;
    QTAILQ_HEAD(subregions, MemoryRegion) subregions;
    QTAILQ_ENTRY(MemoryRegion) subregions_link;
    QTAILQ_HEAD(coalesced_ranges, CoalescedMemoryRange) subregions_link;
    const char *name;
    uint8_t dirty_log_mask;
    unsigned ioeventfd_nb;
    MemoryRegionIoeventfd *ioeventfds;
    NotifierList iommu_notify;
};
```

**每一个 MemoryRegion 代表一块内存区域**. 仔细观察 MemoryRegion 的成员函数, 它包含一个 Object 的成员函数用于指向它的所有者, 以及一个 MemoryRegion 成员用于指向他的父节点(有点类似链表). 另外还有三个尾队列(QTAILQ) subregions,  subregions\_link, subregions\_link.  也就是说, 一个 MemoryRegion 可以包含多个内存区, 根据不同的参数区分该内存域的功能.  在使用 MemoryRegion 之前要先为其分配内存空间并调用 memory\_region\_init 做必要的初始化. BIOS 也是通过一个 MemoryRegion 结构指示的. 它的 MemoryRegion.name 被设置为"pc.bios",  size 设置为 BIOS 文件的大小(65536 的整数倍). 接着调用 rom\_add\_file\_fixed 将其 BIOS 文件加载到一个全局的 rom 队列中.

最后, 回到 old\_pc\_system\_rom\_init 函数中, 将 BIOS 映射到内存的最上方的地址空间.

## 2.3. 清单 6 old_pc_system_rom_init 函数中将 BIOS 映射到物理内存空间的代码:

```
hw/i386/pc_sysfw.c

    /* map all the bios at the top of memory */
    memory_region_add_subregion(rom_memory,
                                (uint32_t)(-bios_size),
                                bios);
```

(uint32\_t)(\-bios\_size) 是一个 32 位无符号数字, 所以-bios\_size 对应的地址就是 FFFFFFFF 减掉 bios\_size 的大小.  bios size 大小为 ./pc-bios/bios.bin = 131072 (128KB)字节, 十六进制表示为 0x20000, 所以 bios 在内存中的位置为 bios position = fffe0000, bios 在内存中的位置就是 0xfffdffff~0xffffffff 现在 BIOS 已经加在到虚拟机的物理内存地址空间中了.

最后 QEMU 调用 CPU 重置函数重置 VCPU 的寄存器值 IP=0x0000fff0, CS=0xf000, CS.BASE= 0xffff0000,CS.LIMIT=0xffff. 指令从 0xfffffff0 开始执行, 正好是 ROM 程序的开始位置. 虚拟机就找到了 BIOS 的入口.

# 3. 小结

通过阅读 QEMU 程序的源代码, 详细介绍了 QEMU 中使用到的 BIOS 文件, QEMU 中物理内存的表示方法, 以及 QEMU 是如何一步步将 BIOS 的二进制载入到通过 QEMU 创建的虚拟机中的内存的过程.

参考 http://wiki.qemu.org/Main_Page: 关于 QEMU 项目的介绍.

参考 git://git.qemu.org/qemu.git 中 QEMU 的源代码.

Ubuntu 12.04 之找不到 Qemu 命令 http://www.linuxidc.com/Linux/2012-11/73419.htm

Arch Linux 上安装 QEMU+EFI BIOS http://www.linuxidc.com/Linux/2013-02/79560.htm

QEMU 的翻译框架及调试工具 http://www.linuxidc.com/Linux/2012-09/71211.htm

QEMU 的详细介绍: [请点这里](https://www.linuxidc.com/Linux/2013-08/88894.htm)

QEMU 的下载地址: [请点这里](https://www.linuxidc.com/down.aspx?id=960)

