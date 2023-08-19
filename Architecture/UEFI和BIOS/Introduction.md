UEFI 大事年表

90 年代初: 传统 BIOS 的天下. 计算机系统的创新严重受限.

1997 年: 英特尔开始为安腾电脑设计 BIOS.

1999 年: EFI 1.0 推出.

2000 年: EFI 1.02 发布.

2002 年: EFI 1.10 发布.

2005 年: UEFI 论坛成立.

2006 年: UEFI 2.0 发布.

2007 年: UEFI 2.1

2008 年: UEFI 2.2

## 基本概念

新型 UEFI, 全称"统一的可扩展固件接口"(Unified Extensible Firmware Interface), 是一种详细描述类型接口的标准. 这种接口用于操作系统自动从预启动的操作环境, 加载到一种操作系统上.

可扩展固件接口(Extensible Firmware Interface, EFI)是 Intel 为 PC 固件的体系结构、接口和服务提出的建议标准. 其主要目的是为了提供一组在 OS 加载之前(启动前)在所有平台上一致的、正确指定的启动服务, 被看做是有近 20 多年历史的 BIOS 的继任者.

UEFI 是由 EFI1.10 为基础发展起来的, 它的所有者已不再是 Intel, 而是一个称作 Unified EFI Form 的国际组织.

## 区别

与 legacy BIOS(传统 BIOS)相比, UEFI 最大的几个区别在于:
1. 编码 99%都是由 C 语言完成;

2. 一改之前的中断、硬件端口操作的方法, 而采用了 Driver/protocol 的新方式;

3. 将不支持 X86 实模式, 而直接采用 Flat mode(也就是不能用 DOS 了, 现在有些 EFI 或 UEFI 能用是因为做了兼容, 但实际上这部分不属于 UEFI 的定义了);

4. 输出也不再是单纯的二进制 code, 改为 Removable Binary Drivers;

5. OS 启动不再是调用 Int19, 而是直接利用 protocol/device Path;

6. 对于第三方的开发, 前者基本上做不到, 除非参与 BIOS 的设计, 但是还要受到 ROM 的大小限制, 而后者就便利多了.

7. 弥补 BIOS 对新硬件的支持不足的问题.
