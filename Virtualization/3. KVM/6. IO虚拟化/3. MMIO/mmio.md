
# MMIO和PIO的区别

I/O作为CPU和外设交流的一个渠道, 主要分为两种, 一种是Port I/O, 一种是MMIO(Memory mapping I/O).  

前者就是我们常说的I/O端口, 它实际上的应该被称为I/O地址空间.  对于x86架构来说, 通过IN/OUT指令访问. PC架构一共有65536个8bit的I/O端口, 组成64KI/O地址空间, 编号从0~0xFFFF. 连续两个8bit的端口可以组成一个16bit的端口, 连续4个组成一个32bit的端口. I/O地址空间和CPU的物理地址空间是两个不同的概念, 例如I/O地址空间为64K, 一个32bit的CPU物理地址空间是4G.  

MMIO占用CPU的物理地址空间, 对它的访问可以使用CPU访问内存的指令进行. 一个形象的比喻是把文件用mmap()后, 可以像访问内存一样访问文件、同样, MMIO是用访问内存一样的方式访问I/O资源, 如设备上的内存. MMIO不能被cache(有特殊情况, 如VGA).  

Port I/O和MMIO的主要区别在于: 

(1) 前者不占用CPU的物理地址空间, 后者占有(这是对x86架构说的, 一些架构, 如IA64, port I/O占用物理地址空间). 

(2) 前者是顺序访问. 也就是说在一条I/O指令完成前, 下一条指令不会执行. 例如通过Port I/O对设备发起了操作, 造成了设备寄存器状态变化, 这个变化在下一条指令执行前生效. uncache的MMIO通过uncahce memory的特性保证顺序性. 

(3) 使用方式不同.  

由于port I/O有独立的64KI/O地址空间, 但CPU的地址线只有一套, 所以必须区分地址属于物理地址空间还是I/O地址空间. 早期的CPU有一个M/I针脚来表示当前地址的类型, 后来似乎改了. 刚才查了一下, 叫request command line, 没搞懂, 觉得还是一个针脚. 

IBM PC架构规定了一些固定的I/O端口, ISA设备通常也有固定的I/O端口, 这些可以通过ICH(南桥)的规范查到. PCI设备的I/O端口和MMIO基地址通过设备的PCI configure space报告给操作系统, 这些内容以前的帖子都很多, 可以查阅一下.  

通常遇到写死在I/O指令中的I/O端口, 如果不是ISA设备, 一般都是架构规定死的端口号, 可查阅规范. 

# qemu-kvm中的MMIO

我们知道X86体系结构上对设备进行访问可以通过PIO方式和MMIO(Memory Mapped I/O)两种方式进行,  那么`QEMU-KVM`具体是如何实现设备MMIO访问的呢?

MMIO是直接将设备I/O映射到物理地址空间内, 虚拟机物理内存的虚拟化又是通过EPT机制来完成的,  那么模拟设备的MMIO实现也需要利用EPT机制．虚拟机的EPT页表是在`EPT_VIOLATION`异常处理的时候建立起来的,  对于模拟设备而言访问MMIO肯定要触发`VM_EXIT`然后交给QEMU/KVM去处理, 那么怎样去标志MMIO访问异常呢? 查看Intel SDM知道这是通过利用`EPT_MISCONFIG`来实现的．那么`EPT_VIOLATION`与`EPT_MISCONFIG`的区别是什么?

EXIT_REASON_EPT_VIOLATION is similar to a "page not present" pagefault.

EXIT_REASON_EPT_MISCONFIG is similar to a "reserved bit set" pagefault.

EPT_VIOLATION表示的是对应的物理页不存在, 而EPT_MISCONFIG表示EPT页表中有非法的域．

那么这里有２个问题需要弄清楚．

## KVM如何标记EPT是MMIO类型 ?

`hardware_setup`时候虚拟机如果开启了ept支持就调用`ept_set_mmio_spte_mask`初始化shadow_mmio_mask,  设置EPT页表项**最低 3 bit**为: `110b`就会触发ept_msconfig(110b表示该页**可读可写**但是**还未分配**或者**不存在**, 这显然是一个错误的EPT页表项).

```cpp
#define VMX_EPT_WRITABLE_MASK                   0x2ull
#define VMX_EPT_EXECUTABLE_MASK                 0x4ull

/* The mask to use to trigger an EPT Misconfiguration in order to track MMIO */
#define VMX_EPT_MISCONFIG_WX_VALUE              (VMX_EPT_WRITABLE_MASK |       \
                                                 VMX_EPT_EXECUTABLE_MASK)


static void ept_set_mmio_spte_mask(void)
{
        /*
         * EPT Misconfigurations can be generated if the value of bits 2:0
         * of an EPT paging-structure entry is 110b (write/execute).
         */
        kvm_mmu_set_mmio_spte_mask(VMX_EPT_MISCONFIG_WX_VALUE, 0);
}
```

同时还要对EPT的一些特殊位进行标记来标志该spte表示MMIO而不是虚拟机的物理内存, 例如这里

(1)set the special mask:  SPTE_SPECIAL_MASK．

(2)reserved physical address bits:  the setting of a bit in the range `51:12` that is beyond the logical processor’s physic

关于EPT_MISCONFIG在SDM中有详细说明．

![2020-09-04-16-28-42.png](./images/2020-09-04-16-28-42.png)

我们可以通过以两个函数对比一下kvm对MMIO pte的处理: 

```cpp
void kvm_mmu_set_mmio_spte_mask(u64 mmio_value, u64 access_mask)
{
        BUG_ON((u64)(unsigned)access_mask != access_mask);
        WARN_ON(mmio_value & (shadow_nonpresent_or_rsvd_mask << shadow_nonpresent_or_rsvd_mask_len));
        WARN_ON(mmio_value & shadow_nonpresent_or_rsvd_lower_gfn_mask);
        shadow_mmio_value = mmio_value | SPTE_MMIO_MASK;
        shadow_mmio_access_mask = access_mask;
}
EXPORT_SYMBOL_GPL(kvm_mmu_set_mmio_spte_mask);

static void kvm_set_mmio_spte_mask(void)
{
        u64 mask;

        /*
         * Set a reserved PA bit in MMIO SPTEs to generate page faults with
         * PFEC.RSVD=1 on MMIO accesses.  64-bit PTEs (PAE, x86-64, and EPT
         * paging) support a maximum of 52 bits of PA, i.e. if the CPU supports
         * 52-bit physical addresses then there are no reserved PA bits in the
         * PTEs and so the reserved PA approach must be disabled.
         */
        if (shadow_phys_bits < 52)
                mask = BIT_ULL(51) | PT_PRESENT_MASK;
        else
                mask = 0;

        kvm_mmu_set_mmio_spte_mask(mask, ACC_WRITE_MASK | ACC_USER_MASK);
}
```

KVM在建立EPT页表项之后设置了这些标志位再访问对应页的时候会触发`EPT_MISCONFIG`退出了, 然后调用`handle_ept_misconfig`-->`handle_mmio_page_fault`来完成MMIO处理操作. 

```cpp
KVM内核相关代码: 
handle_ept_misconfig --> kvm_emulate_instruction --> x86_emulate_instruction --> x86_emulate_insn
writeback
    --> segmented_write
        --> emulator_write_emulated
            --> emulator_read_write
              --> emulator_read_write_onepage
                --> ops->read_write_mmio [write_mmio]
                  --> vcpu_mmio_write
                    --> kvm_io_bus_write
                      --> __kvm_io_bus_write
                        --> kvm_iodevice_write
                          --> dev->ops->write [ioeventfd_write]

最后会调用到ioeventfd_write, 写eventfd给QEMU发送通知事件
/* MMIO/PIO writes trigger an event if the addr/val match */
static int
ioeventfd_write(struct kvm_vcpu *vcpu, struct kvm_io_device *this, gpa_t addr,
                int len, const void *val)
{
        struct _ioeventfd *p = to_ioeventfd(this);

        if (!ioeventfd_in_range(p, addr, len, val))
                return -EOPNOTSUPP;

        eventfd_signal(p->eventfd, 1);
        return 0;
}
```

## QEMU如何标记设备的MMIO

这里以e1000网卡模拟为例, 设备初始化MMIO时候时候注册的MemoryRegion为IO类型(不是RAM类型)．

```cpp
static void
e1000_mmio_setup(E1000State *d)
{
    int i;
    const uint32_t excluded_regs[] = {
        E1000_MDIC, E1000_ICR, E1000_ICS, E1000_IMS,
        E1000_IMC, E1000_TCTL, E1000_TDT, PNPMMIO_SIZE
    };
    // 这里注册MMIO, 调用memory_region_init_io, mr->ram = false！！！
    memory_region_init_io(&d->mmio, OBJECT(d), &e1000_mmio_ops, d,
                          "e1000-mmio", PNPMMIO_SIZE);
    memory_region_add_coalescing(&d->mmio, 0, excluded_regs[0]);
    for (i = 0; excluded_regs[i] != PNPMMIO_SIZE; i++)
        memory_region_add_coalescing(&d->mmio, excluded_regs[i] + 4,
                                     excluded_regs[i+1] - excluded_regs[i] - 4);
    memory_region_init_io(&d->io, OBJECT(d), &e1000_io_ops, d, "e1000-io", IOPORT_SIZE);
}
```

对于MMIO类型的内存QEMU不会调用kvm_set_user_memory_region对其进行注册,  那么KVM会认为该段内存的pfn类型为KVM_PFN_NOSLOT,  进而调用set_mmio_spte来设置该段地址对应到spte,  而该函数中会判断pfn是否为NOSLOT标记以确认这段地址空间为MMIO．

```cpp
static bool set_mmio_spte(struct kvm_vcpu *vcpu, u64 *sptep, gfn_t gfn,
              kvm_pfn_t pfn, unsigned access)
{
    if (unlikely(is_noslot_pfn(pfn))) {
        mark_mmio_spte(vcpu, sptep, gfn, access);
        return true;
    }

    return false;
}
```

# 总结

MMIO是通过设置spte的保留位来标志的．

* 虚拟机内部第一次访问MMIO的gpa时, 发生了EPT_VIOLATION然后check gpa发现对应的pfn不存在(QEMU没有注册), 那么认为这是个MMIO, 于是set_mmio_spte来标志它的spte是一个MMIO．
*  后面再次访问这个gpa时就发生EPT_MISCONFIG了, 进而愉快地调用handle_ept_misconfig -> handle_mmio_page_fault -> x86_emulate_instruction 来处理所有的MMIO操作了．