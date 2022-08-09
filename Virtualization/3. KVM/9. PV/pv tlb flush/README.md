https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=858a43aae23672d46fe802a41f4748f322965182


检查下flushmask是否为NULL

为NULL表示, 表明没有running的vCPUs, 都是preempted vCPUs

不用调用 native_flush_tlb_others


ebizzy -M