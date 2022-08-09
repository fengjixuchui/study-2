
This kernel requires the following features not present on the CPU:
la57

1. 查看la57对应的feature

LA57    ⟷ 5-level page tables

arch/x86/include/asm/cpufeatures.h


2. 查找cpu flag

3. 在qemu命令行减去这个feature