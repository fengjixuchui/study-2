
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 两种BIOS](#1-两种bios)
  - [1.1. 传统BIOS](#11-传统bios)
  - [1.2. UEFI](#12-uefi)
- [2. UEFI的DXE](#2-uefi的dxe)
  - [2.1. 文件系统驱动](#21-文件系统驱动)
  - [2.2. 设备驱动](#22-设备驱动)
  - [2.3. DXE作用](#23-dxe作用)
  - [2.4. 设备固件](#24-设备固件)
  - [2.5. UEFI相关启动过程](#25-uefi相关启动过程)
- [3. EFI系统分区](#3-efi系统分区)
  - [设置UEFI启动项](#设置uefi启动项)
- [4. Windows 的启动顺序](#4-windows-的启动顺序)
  - [4.1. BIOS](#41-bios)
  - [4.2. UEFI](#42-uefi)
- [举例](#举例)
- [5. Q&A](#5-qa)
  - [5.1. Ghost](#51-ghost)
  - [5.2. 无法定位分区](#52-无法定位分区)
  - [5.3. 无工具制作安装盘](#53-无工具制作安装盘)
  - [5.4. 无U盘安装](#54-无u盘安装)
  - [5.5. 默认grub](#55-默认grub)
  - [5.6. 安装在 MBR](#56-安装在-mbr)
- [6. 参考](#6-参考)

<!-- /code_chunk_output -->

# 1. 两种BIOS

## 1.1. 传统BIOS

一句话概括: **BIOS 只认识设备, 不认识分区, 不认识文件**.

BIOS 启动的时候按照 **CMOS** 设置里的顺序**挨个存储设备检查**: (此处不讨论PXE和光盘)

* 这个存储设备的前512字节是不是以0x55 0xAA结尾?

* 不是那就跳过. 找下一个设备.

* 是的话, 这个磁盘可以启动, **加载这 512 字节里的代码然后执行**.

* **执行之后后面的事几乎就跟BIOS没啥关系(那些代码可能会使用BIOS的一些中断**)了.

至于后面**启动什么系统**取决于这 512 字节里**存了谁家的代码**. 这个代码是**各家的系统安装程序**写进去的目的是启动自家系统.

* 比如你装了 Windows, 这里面就变成了 **Windows 的启动代码**.
* 比如你装了 Linux, 这里面就会变成 **Grub 的启动代码**.

顺便这 512 字节包含了 **MBR 分区表**的信息. 但是有人可能注意到, 上面半句没提 "系统装在哪个分区上"了, 硬盘有几个分区.

其实 **BIOS 并不认识分区表(不关心, BIOS开始执行512字节代码就不管了)**. 哪怕磁盘上没有分区表, 没分过区, 只要前512字节有0x55 0xAA的结尾有合适的引导代码也是能启动的.

## 1.2. UEFI

(此处只讨论民用64位架构下的UEFI.)

一句话概括: UEFI认识**设备**, 还认识**设备ROM**, 还认识**分区表**, 认识**文件系统**以及**文件**.

UEFI 启动的时候, 经过一系列初始化(SEC、CAR、DXE什么的SEC、CAR不需要懂. 下一节里会说DXE阶段是干嘛的), 然后按照**设置里的顺序找启动项**.

启动项分两种:

- **文件启动项**, 大约记录的是**某个磁盘的某个分区的某个路径下的某个文件**. 对于文件启动项, **固件**会直接加载这个**EFI文件**并执行. 类似于 DOS 下你敲了个 win.com 就执行了 Windows 3.2/95/98 的启动. 文件不存在则失败.

- **设备启动项**, 大约记录的就是"某个U盘"、"某个硬盘". (此处只讨论U盘、硬盘)对于设备启动项, UEFI 标准规定了**默认的路径** "`\EFI\Boot\bootX64.efi`". UEFI 会加载**磁盘**上的**这个文件(\EFI\Boot\bootX64.efi)**. 文件不存在则失败.

至于**这个EFI文件会干嘛主板是不管**的.

但是随着 Windows8.x 以及 UEFI 标准 2.x 推出了一个叫做 **SecureBoot**的功能. 开了 SecureBoot 之后, **主板会验证即将加载的 efi 文件的签名**, 如果开发者不是受信任的开发者, 就会拒绝加载.

比如 CloverX64.efi 就好像没有签名.

# 2. UEFI的DXE

## 2.1. 文件系统驱动

一个磁盘**分区**, 要**格式化**之后才能往里存**文件**. 格式化的时候又能选择不同的**文件系统**. 比如

* Win10 可以选 FAT32、NTFS、exFAT、ReFS 几种;

* Linux 可以选 ext2、ext3、ext4、FAT32 等;

* macOS 可以选 FAT32、HFS+、APFS、exFAT 几种.

其实**每个操作系统**, 都先有**文件系统驱动**, 然后才能读取某种**文件系统**.

## 2.2. 设备驱动

**设备**也是一样的, 先有**设备驱动**然后才能**读取设备**.

* 原版的 WinXP 只带了 IDE 驱动, 没有 SATA 驱动;

* 原版 Win7 只带了 IDE 和 SATA 驱动, 没有 NVMe 驱动;

* Win8/Win10 则带了 IDE/SATA 和 NVMe 三种驱动;

* macOS10.12 带了 SATA 驱动以及苹果专用 NVMe 磁盘的驱动;

* macOS10.13 带了 SATA 和标准 NVMe 驱动.

先有设备驱动识别设备, 再文件系统驱动识别文件系统

## 2.3. DXE作用

UEFI 作为一个模糊了**固件**和**操作系统界限**的东西, 作为一个设计之初就考虑到了**扩展性的东西**, 它也是**有驱动程序**的. 启动过程中的 **DXE 阶段**全称叫 `Driver eXecution Environment` 就是**加载驱动**用的.

## 2.4. 设备固件

首先各种 **PCI-E 的设备**(比如显卡, 比如 PCI-E NVMe)都有**固件**. 其中**支持 UEFI** 的设备(比如 10 系列的 Nvidia 显卡)**固件**里就会有**对应的 UEFI 的驱动**.

> 题外话：浦科特的 NVMe 固态硬盘，UEFI 版固件是没有那个 Logo 的。那个 Logo 是浦科特的BIOS版（Legacy版）固件。它被加载是因为主板默认为了兼容性，“StorageOptionROM” 选项默认是 Legacy 的。改成UEFI，就见不到那个浦科特 Logo 页了。

## 2.5. UEFI相关启动过程

> 这里只说相关过程

1. UEFI 启动后, **进入了 DXE 阶段**, 就开始**加载设备驱动**(这里是设备驱动), 然后 UEFI 就会有**设备列表**了.

2. 对于其中的**磁盘设备**, UEFI 会**加载对应的设备驱动**, 解析其中的**分区表**(**GPT** 和 **MBR**). 然后 UEFI 就会有**所有分区的列表**了. 

3. 然后 UEFI 就会用**内置的文件系统驱动**(这里是文件系统驱动), **解析**每个**分区**. 然后 UEFI 就会**认识分区里的文件**了. 比如 "`\EFI\Boot\bootX64.efi`"(一般是 **ESP** 分区).

作为 UEFI 标准里**钦定的文件系统**, `FAT32.efi` 是**每个主板！！！都会带的**. **所有 UEFI 的主板都认识FAT32分区**. 这就是 UEFI 的 Windows 安装盘为啥非得是 FAT32 的. 除此之外苹果的主板还会支持 hfs 分区.

如同 Windows 可以安装驱动一样, **UEFI 也能在后期加载驱动**. 比如 CloverX64.efi 启动之后会加载 `\EFI\Clover\drivers64UEFI` 下的所有驱动. 包括 VboxHFS.efi 等各种efi. 网上你也能搜到NTFS.efi. 再比如**UEFI Shell** 下你可以**手动执行命令加载驱动**.

再说一句，Apple 随着 macOS10.13 推出了 APFS，很良心的放出了 apfs.efi，广大 Hackintosh 用户的福音啊，把这玩意放进 Clover 里就能识别 APFS 分区里的 HighSierra 了！

# 3. EFI系统分区

UEFI 规范里, 在 **GPT 分区表**的基础上, 规定了一个 **EFI 系统分区**(`EFI System Partition`, ESP), ESP 要格式化成 **FAT32** 文件系统(这个分区是要格式化为某个文件系统的), **EFI 启动文件**要放在"`\EFI\<厂商>`" 文件夹下面.

- 比如 Windows 的 UEFI 启动文件都在 "`\EFI\Microsoft`" 下面.
- 比如 Clover 的东西全都放在 "`\EFI\Clover`"下面.

但是 Apple 比较特殊它的主板直接去 HFS/APFS 分区找启动文件. 然而即便如此 Mac 的 ESP 里还是会有一堆 Apple 的文件.

Macbook 上的 ESP 分区里的 "\EFI\Apple" 文件夹:

![config](images/12.jpg)

**UEFI 下启动盘是 ESP 分区跟 Windows 不是同一个分区**.

## 设置UEFI启动项

根据 UEFI 标准, 你可以把 U 盘里的 "`\EFI\Clover`" 文件夹拷贝到**硬盘里的 ESP 对应的路径**下. 然后把 "`\EFI\Clover\CloverX64.efi`" 添加为 **UEFI 的文件启动项**就行了.

**Windows** 的 **BCD** 命令其实也可以**添加 UEFI 启动项**. 也可以用 EasyUEFI 来搞这些操作. 但是免费版的 EasyUEFI 不支持企业版Windows.

"`\EFI\BOOT`" 这个文件夹**放谁家的程序都行**. 无论是 "`\EFI\Microsoft\Boot\Bootmgfw.efi`", 还是 "`\EFI\Clover\CloverX64.efi`", 只要放到 "`\EFI\Boot`" 下并且**改名** "`BOOTX64.EFI`"(**设备启动项**), 就能在**没添加文件启动项**的情况下**默认加载对应的系统**.

举个例子: 一个 U 盘, 想做成 **Windows 安装盘 + Hackintosh 安装盘**该怎么做?

- 划分**两个分区**, 第一个分区格式化成 `FAT32`, 第二个分区 `HFS+`.
- 苹果系统下把第二个分区做成安装盘. 苹果启动盘做好了.
- 把 Windows 的 ISO 镜像里的文件拷贝到第一个分区. Windows 安装盘做好了.
- 然后 Clover 拷贝到第一个分区的 "`\EFI\Clover`" 文件夹下. Clover 的东西也做好了.
- 最后怎么让这个 U 盘插到任何电脑上都默认启动 Clover 呢?答案是把 "\EFI\Boot" 下的 "bootX64.efi" 换成 Clover 的就可以了. 那个文件夹放谁家的 efi 文件都要改名 "bootX64.efi".

# 4. Windows 的启动顺序

Windows 8/8.1/10 在 UEFI 和 BIOS 下各种启动文件的顺序

## 4.1. BIOS

BIOS 启动:

MBR->PBR->bootmgr->WinLoad.exe

![config](images/13.jpg)

按照前文说的**BIOS加载某个磁盘MBR的启动代码**这里特指Windows的引导代码这段代码会查找活动分区(**BIOS不认识活动分区而是这段代码认识活动分区0x80**)的位置加载并执行活动分区的PBR(另一段引导程序).

Windows的PBR认识FAT32和NTFS两种分区找到分区根目录的bootmgr文件加载、执行bootmgr.

bootmgr没了MBR和PBR的大小限制可以做更多的事. 它会加载并分析BCD启动项存储. 而且bootmgr可以跨越磁盘读取文件了. 所以无论你有几个磁盘你在多少块磁盘上装了Windows一个电脑只需要一个bootmgr就行了. bootmgr会去加载某磁盘某NTFS分区的"\Windows\System32\WinLoad.exe"后面启动Windows的事就由WinLoad.exe来完成了.

重点来了为什么图中有两组虚线?

**因为"启动磁盘"和"装系统的磁盘"可以是同一个磁盘也可以不是同一个**. "启动分区"和"系统分区"可以是不同磁盘的不同分区也可以是相同磁盘的不同分区也可以是同一个分区.

这就解释了为什么有的时候Windows装在磁盘2上却要在BIOS里选磁盘0启动了. 因为bootmgr可能在磁盘0上.

## 4.2. UEFI

UEFI 启动:

UEFI固件->bootmgfw.efi->WinLoad.efi

![config](images/14.jpg)

根据前文说的**UEFI启动项分为文件启动项和设备启动项**.

给UEFI指定特定的文件启动项(**某个设备某个分区某个文件但是必须手动加载设备驱动和文件系统驱动**)或直接指定特定的设备启动项(该设备必须存在FAT分区并且在里面必须是\EFI\Boot\bootX64.efi).

> ubuntu 的是 /boot/efi/EFI/ubuntu/grubx64.efi

UEFI查找**硬盘分区**中第一个**FAT分区**内的引导文件进行系统引导.

通常情况: 主板UEFI初始化然后找到了默认启动项"Windows Boot Manager". 里面写了 bootmgfw.efi 的位置. 固件加载bootmgfw.efi(**ESPEFI系统分区FAT32文件系统**). bootmgfw.efi 根据**BCD启动项存储找到装Windows的磁盘的具体分区**加载其中的 WinLoad.efi. 由 WinLoad.efi 完成剩下的启动工作.

其中的虚线跟上面的一样意思是**Windows启动盘和EFI启动盘可以是一个硬盘也可以是不同的硬盘**. 所以**对于UEFI来说启动盘是bootmgfw.efi所在的那个盘**.

# 举例

所有的 UEFI 启动项

![2022-11-24-20-26-46.png](./images/2022-11-24-20-26-46.png)

进入 ``

![2022-11-24-20-31-42.png](./images/2022-11-24-20-31-42.png)

通过 `bcfg boot dump` 查看所有启动项

![2022-11-24-21-01-31.png](./images/2022-11-24-21-01-31.png)

可以看到 ubuntu 的 UEFI 启动项是 `\EFI\UBUNTU\SHIMX64.EFI`

# 5. Q&A

## 5.1. Ghost

> 以前我一直装Ghost版的WindowsUEFI之后真的没法Ghost了么?

先说一句真不推荐用网上的Ghost版Windows安装盘来装系统了. 微软公开放出了官方的原版Win10下载链接而且还有启动盘制作程序. 链接在这: [下载 Windows 10](https://link.zhihu.com/?target=https%3A//www.microsoft.com/zh-cn/software-download/windows10). 写这个的原因是因为有时候自己做的Ghost备份还是挺好用的.

并不是不能Ghost了. 但是**传统的Ghost盘都是只Clone了C盘**没有考虑到"**UEFI下启动盘是ESP分区(FAT32文件系统)跟Windows不是同一个分区**"的事.

其次Ghost备份并**不能备份分区的GUID**. 还原之后ESP分区里的BCD中记录的Windows在"某某GUID的分区上"就可能找不到对应的GUID了. 这时候需要用bcdedit命令或者BCDBoot命令修改BCD存储. 鉴于目前的Ghost盘很少基于DOS了如果是基于WinPE的bcdedit命令和bcdboot命令都是已经内置了的. 只要制作者在批处理文件里在Ghost之后调用bcdedit命令改一下bcd配置就行了.

而且即使没Ghost备份ESP分区你依然可以用**bcdboot命令来生成ESP分区的内容**. 同样在WinPE下批处理文件里Ghost还原之后使用BCDBoot命令生成启动文件就行了.

总结一下Ghost还原Windows分区之后调用BCDBoot配置启动项即可.

## 5.2. 无法定位分区

> Windows无法定位现有分区也无法

这种报错信息如果是**在UEFI模式下一般是因为你有多块硬盘而且超过一块硬盘上有ESP分区**. 只要把不想用的ESP分区删掉或者拔掉对应的硬盘保证装Windows的时候只有一个硬盘上有ESP分区即可.

如果实在做不到考虑用DISM.exe安装Windows吧. Win7的DISM.exe真的太弱了. 尽量用Win10安装盘或者Win10PE里的DISM.exe.

## 5.3. 无工具制作安装盘

> 不需要第三方工具就能做UEFI下的Windows安装盘?

确实啊根据上文说的**U盘格式化成FAT32**然后把Windows安装盘的ISO里面的东西拷贝到U盘就行了. (适用于Win8/8.1/10以及WinServer2012/2012R2/2016. WinVista x64/Win7x64以及WinServer2008x64/2008R2需要额外操作WinVista x86/Win7x86/WinServer2008x86不支持UEFI)

打开ISO之后是这四个文件夹、四个文件拷贝到优盘.

![config](images/15.jpg)

## 5.4. 无U盘安装

> 我电脑是UEFI的想装Linux但我手头没优盘听说也能搞定?

对搞个FAT32的分区把Linux安装盘的iso镜像里面的文件拷贝进去然后在Windows下用工具给那个分区的BOOTx64.efi添加为UEFI文件启动项开机时候选那个启动项就能启动到Linux安装盘了. 下面示意图是Ubuntu的. 记得查看一下你的Linux支不支持SecureBoot哦！如果你要装的Linux不支持SecureBoot记得**关掉主板的SecureBoot设置**哦.

Ubuntu安装盘ISO镜像内的UEFI启动文件:

![config](images/16.jpg)

## 5.5. 默认grub

> 装个Linux但我希望默认还是Windows; 重装Windows可是我开机不再默认Grub怎么回Linux?

如果是UEFI模式那就跟之前一样改启动项顺序就行了.

如果是传统BIOS的要么用bootsect.exe把MBR改成Windows的. 要么用工具把MBR刷成Grub的. 也可以考虑Linux下用dd命令备份MBR的前446字节到时候再还原回去.

## 5.6. 安装在 MBR

> 重装Windows提示我什么MBR、GPT不让装?

这个就是Windows安装程序的限制了. BIOS模式下的Windows只允许被装在MBR分区表下面. UEFI模式下的Windows只允许被装在GPT分区下.

但事实上MBR分区表也能启动UEFI模式下的Windows.

# 6. 参考

本文来自: https://zhuanlan.zhihu.com/p/31365115