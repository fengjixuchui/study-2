
http://chinaunix.net/uid-28541347-id-5789579.html

https://kernelgo.org/mmio.html

https://cloud.tencent.com/developer/article/1087477


intel有个mmio加速: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=68c3b4d1676d870f0453c31d5a52e7e65c7448ae

amd 是否可做???

暂停amd kvm上fast mmio bus的实现, intel kvm上利用ept misconfig来节省遍历页表和解码指令, intel上ept misconfig的时候硬件会解码出指令的长度, 虽然SDM没有规定. amd上没有ept misconfig, 只有npf_intercept, 这个amd硬件不会解码出指令的长度, 也就是说, 快速模拟mmio操作后, 无法skip当前指令, 因为不知道长度是多大, 只能走慢速路径, 软件解码指令的长度, 这样fast mmio bus操作就失去了意义. 

