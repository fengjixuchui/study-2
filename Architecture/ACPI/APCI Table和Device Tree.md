
ACPI Table 与 Windows 的关系 犹如 Device Tree 与 embedded-Linux 的关系. 

ACPI SPEC定义了`ACPI-compatible OS`与 **BIOS** 之间的**接口 ACPI Tables 就是 BIOS 提供给 OS 的硬件配置数据**包括系统硬件的电源管理和配置管理. 

BIOS 在 **POST 过程**中将 RSDP 存在 0xE0000--0xFFFFF 的内存空间中然后Move RSDT/XSDT, FADT, DSDT到ACPI Recleam Area, Move FACS到ACPI NVS Area最后填好表的Entry链接和Checksum. 

控制权交给OS之后由OS来开启ACPI Mode首先在内存中搜寻ACPI Table然后写ACPI_Enable到SMI_CMDSCI_EN也会被HW置起来. 

ACPI Tables根据存储的位置可以分为: 

1).  RSDP位于F段用于OSPM搜索ACPI TableRSDP可以定位其他所有ACPI Table

2).  FACS位于ACPI NVS内存用于系统进行S3保存的恢复指针内存为NV Store

3). 剩下所有ACPI Table都位于ACPI Reclaim内存进入OS后内存可以释放

ACPI Table根据版本又分为1.0B2.03.04.0. 

2.0以后支持了64-bit的地址空间因此几个重要的Table会不大一样比如: RSDPRSDTFADTFACS. 简单的列举一下不同版本的ACPI Table: 

1) ACPI 1.0B: RSDP1RSDTFADT1FACS1DSDTMADTSSDTHPETMCFG等

2) ACPI 3.0 : RSDP3RSDTXSDTFADT3FACS3DSDTMADTHPETMCFGSSDT等

以系统支持ACPI3.0为例子说明系统中ACPI table之间的关系如图: 

