aysnc fn/block 不会直接执行, 因为它们都是 Future 实例, 而真正的代码执行是要调用 poll 函数的(Future trait)

.await 能触发 future 的调用, 是因为 await 的实现, 其中调用了 poll函数

async(下面称为future)的原理就是, 当执行时候(即调用poll函数时候), 如果resume函数(也就是真正的代码执行)返回 Yield(即真正代码执行有yield调用), poll就会返回Pending, 从而让出执行(比如被加到channel), 从而future对象的下一行代码就可以执行. 而当这个future被再次调度到, 即又执行poll函数, 那就再次调用resume函数(真是代码执行), 从上一次yield的下一条操作继续执行. 直到resume函数最终执行完, 即resume函数返回了 Complete, 从而这个future(即poll函数调用)返回Ready, 这个future才算完全执行完

所以如果 async fn 或 block 中是个不会 exit 的 loop, 那这个future永远不会结束(除非进程退出)

而 future.await 的实现是, loop future.poll, 
1. 如果没有执行完(即 feature.poll 函数返回了 Pending), 则会调用 yield, 从而告诉更外层(也会是future)这里有阻塞, 可以让其他执行, 这也就是.await必须在aysnc fn/block 中使用
2. 如果执行完(即 feature.poll 函数返回了 Ready), 则会调用 break, 跳出loop, 从而表示这个这行代码结束(即future.await)

注, future.poll 函数的实现, 也是调用resume函数来执行真实代码, 根据真实代码是执行到了yield还是执行完全返回complete, future.poll函数从而返回pending或ready

crosvm 代码中, handle_queue 这个 future 永不结束(Ready). 它里面调用了一个 future.await, 从 queue 拿 request, 这个 future 会执行完, 即Ready. 但是因为外层的 handle_queue future 一直 loop, 所以每次也都会创建新的内部future. 而 内部future.poll 函数如果pending, 那因为.await, 从而会调用 yield, 进而说明handle_queue 这个future先不执行, 让其他代码可以执行