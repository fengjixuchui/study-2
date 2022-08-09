
简介

在实际业务中, guest执行**HLT指令**是导致虚拟化overhead的一个重要原因. 如[1].

KVM halt polling特性就是为了解决这一个问题被引入的, 它在Linux 4.3-rc1被合入主干内核, 其基本原理是当guest idle发生vm-exit时, host 继续polling一段时间, 用于减少guest的业务时延. 进一步讲, 在vcpu进入idle之后, guest内核默认处理是执行HLT指令, 就会发生vm-exit, host kernel并不马上让出物理核给调度器, 而是poll一段时间, 若guest在这段时间内被唤醒, 便可以马上调度回该vcpu线程继续运行. 

polling机制带来时延上的降低, 至少是一个线程调度周期, 通常是几微妙, 但最终的性能提升是跟guest内业务模型相关的. 如果在host kernel polling期间, 没有唤醒事件发生或是运行队列里面其他任务变成runnable状态, 那么调度器就会被唤醒去干其他任务的事. 因此, halt polling机制对于那些在很短时间间隔就会被唤醒一次的业务特别有效. 

代码流程
guest执行HLT指令发生vm-exit后, kvm处理该异常, 在kvm_emulate_halt处理最后调用kvm_vcpu_halt(vcpu). 

int kvm_vcpu_halt(struct kvm_vcpu *vcpu){