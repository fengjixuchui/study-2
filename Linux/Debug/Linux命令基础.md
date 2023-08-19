
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. Linux 命令基础](#1-linux-命令基础)
- [2. man page](#2-man-page)
- [3. info page](#3-info-page)
- [4. 其他文件](#4-其他文件)

<!-- /code_chunk_output -->

# 1. Linux 命令基础

 - commands not found 的错误原因
     - 输错命令
     - 软件没有安装
     - 这个命令所在的目录, 当前用户没有将它加入命令搜寻路径中, echo $PATH 可以查看.
 - 系统的所有环境变量 env 可以查看
 - Linux 在线求助: man page | info page
 - 中文命令网站: http://man.linuxde.net/

# 2. man page

 - man page 适用于所有 Unix like 系统.
 - man page 的数字说明:

```
1: 用户可以在 shell 环境中操作的命令或可执行文件
2: 系统内核可调用的函数与工具
3: 一些常用的函数(function)与函数库(library), 大部分为 C 的函数库
4: 设备文件的说明, 通常在/dev/下面的文件
5: 配置文件或某些文件的格式
6: 游戏(games)
7: 惯例与协议等, 例如 Linux 文件系统、网络协议、ASCII code 等说明
8: 系统管理员可以使用的管理命令
9: 与 kernel 相关的文件

注: man null 会显示"NULL(4)", 可以看出 null 是一个设备文件
```
 - man page 大致分为如下部分, 见图
 ![man page](images/man1.PNG "man page 说明")
 - man page 的数据也是存放在目录下面, 不同 distribution 通常有点区别, 通常在/usr/share/man 目录, 不过可以通过修改 man page 的查询路径. /etc/man.config(有些是 man.conf 或 manpath.conf), 更多信息通过"man man"查询.
 - 查询出来的结果取决于配置文件(/etc/man.conf)的顺序, **先查询到的说明文件就先显示出来**.
 - man -f <命令或数据>: 查询更多的说明文件. 该命令的简略写法:  whatis <命令或数据>
 - man -k <命令或数据>: 根据关键字查询说明文件. 该命令的简略写法: apropos <命令或数据>

> 注: 这两个特殊命令(whatis、apropos)要可以使用, 必须要创建 whatis 数据库才行, 使用 root 账户, 执行 makewhatis

总结:

> 不用背命令, 记住常用的命令即可. 根据 man page 查找命令并查看用法.

# 3. info page

 - Linux 除了 man, 还提供的一套额外的在线求助方法, Linux 独有的.
 - 目标数据的说明文件只有以 info 格式写成才能使用 info 的特殊功能(例如超链接). 而支持 info 命令的文件默认在/usr/share/info/目录下.

# 4. 其他文件

 - 一般, 命令或软件开发者都会将自己命令或软件的说明制作成"在线帮助文档", 会放置在/usr/share/doc 这个目录下, 包括 bash 信息等.