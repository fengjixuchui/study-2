
FIO是测试IOPS的非常好的工具，用来对硬件进行压力测试和验证，支持13种不同的 I/O 引擎, 包括: sync, mmap, libaio, posixaio, SG v3, splice, null, network, syslet, guasi, solarisaio 等等。 

# 编译安装

```
$ ./configure
$ make
$ make install
```

注意，GNU make 是必需的。在 BSD 上，它可以从 ports 目录中的 devel/gmake 获得; 在 Solaris 上，它位于 SUNWgmake 包中。在默认不是 GNU make 的平台上，键入 `gmake` 而不是 `make`。

Configure 将打印已启用的选项。注意，在基于 Linux 的平台上，必须安装 libaio 开发包才能使用 libaio 引擎。根据发行版的不同，它通常被称为 libaio-devel 或 libaio-dev。

对于 gfio，需要安装 gtk 2.18（或更高版本）、关联的 glib 线程和 cairo。GFIO 不是自动构建的，可以使用 “--enable-GFIO” 选项进行 configure。

交叉编译:

```
$ make clean
$ make CROSS_COMPILE=/path/to/toolchain/prefix
```

配置将尝试自动确定目标平台。

也可以为 ESX 构建 fio，使用 `--esx` 开关进行配置。

# 文档

Fio 使用 Sphinx_ 从 reStructuredText_ 文件生成文档。 要构建HTML格式的文档，请运行 “`make -C doc html`” 并将浏览器定向到：file：`./doc/output/html/index.html`。 要构建手册页，请运行 “`make -C doc man`”，然后运行 “`man doc/output/man/fio.1`”。 要查看支持哪些其他输出格式，请运行 “`make -C doc help`”。   

```
.._reStructuredText：https://www.sphinx-doc.org/rest.html
.._Sphinx：https://www.sphinx-doc.org
```

# 平台

Fio（至少）在 Linux，Solaris，AIX，HP-UX，OSX，NetBSD，OpenBSD，Windows，FreeBSD 和 DragonFly 上工作。某些功能和/或选项可能仅在某些平台上可用，通常是因为这些功能仅适用于该平台（如 solarisaio 引擎或 Linux 上的 splice 引擎）。



