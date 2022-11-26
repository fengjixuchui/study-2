深入了解UEFI, 这里有几个问题可以深入思考一下: 

1. 为什么UEFI采用PE/COFF格式作为UEFI驱动和应用的标准, 而不是ELF格式?

2. 绝大多数UEFI核心代码都是C语言写的, 为什么不用C++, 可以不可以用C++?热门的OO和他有什么关系?

3. UEFI和其他的uboot, coreboot等各自的优点和关系如何?

4. UEFI为什么选择FAT作为UEFI分区标准?

- 知乎专栏: https://zhuanlan.zhihu.com/UEFIBlog?topic=UEFI
- UEFI学习: http://blog.csdn.net/jiangwei0512/article/category/6259511
- UEFI+BIOS探秘: https://zhuanlan.zhihu.com/UEFIBlog

- Linux/Init/开机启动流程
- GPT+UEFI与BIOS+MBR有什么不同?: https://zhuanlan.zhihu.com/p/22510295
- BIOS和UEFI的启动项: https://zhuanlan.zhihu.com/p/31365115
- BIOS与UEFI 、MBR和GPT介绍: https://zhuanlan.zhihu.com/p/30452319
- BIOS, UEFI, MBR, Legacy, GPT等概念整理: https://zhuanlan.zhihu.com/p/36976698
- UEFI到操作系统的虚拟地址转换: https://zhuanlan.zhihu.com/p/26035864
- UEFI和UEFI论坛: https://zhuanlan.zhihu.com/p/25676417
- UEFI+BIOS探秘: https://zhuanlan.zhihu.com/UEFIBlog
- 全局唯一标识分区表(GPT)维基百科: https://zh.wikipedia.org/wiki/GUID%E7%A3%81%E7%A2%9F%E5%88%86%E5%89%B2%E8%A1%A8


ACPI与UEFI核心概念的区别: https://zhuanlan.zhihu.com/p/25893464

ACPI提供了OS可用的硬件抽象和接口(method), UEFI也提供了抽象和接口, 是不是也有冲突?其实两者面向的方面不同, ACPI主要是从硬件抽象的角度来抽象硬件, UEFI是从软件一致方向定义规范. 这也是他们不但没有替代关系, 反而从ACPI 5.0 开始ACPI并入UEFI论坛管理的原因. 需要指出的是ACPI和UEFI没有绑定关系, ACPI可以在uboot上实现, 而UEFI也可以报告DT, 但他们一起工作起来会更加顺畅. UEFI提供了帮助安装更新ACPI table的接口(protocol).大家可以在UEFI/PI spec里面找到相应的接口定义. 




《UEFI编程实践》作者: 罗冰

《UEFI原理与编程》


UEFI 取代 BIOS: https://www.ituring.com.cn/book/tupubarticle/26793

edk2 环境搭建: https://github.com/yuanzhaoming/uefi

UEFI 基础教程: https://blog.csdn.net/xiaopangzi313/category_8898913.html


初步了解计算机与操作系统启动原理: https://www.jianshu.com/p/26e184605952