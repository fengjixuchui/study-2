
linux线程私有数据 --- TSD池

# 背景

**进程内**的**所有线程共享进程的数据空间**，所以**全局变量**为**所有线程共有**。

在某些场景下，**线程**需要保存自己的**私有数据**，这时可以**创建线程私有数据**(`Thread-specific Data`, TSD) 来解决。在线程内部，私有数据可以被线程的各个接口访问，但**对其他线程屏蔽**。

# 原理

线程私有数据采用了**一键多值**技术，即一个key对应多个值。访问数据都是通过键值来访问的。

使用线程私有数据时，需要对**每个线程**创建一个**关联 的key**，linux中主要有四个接口来实现：

1. `pthread_key_create`: 创建一个键

```cpp
int pthread_key_create(pthread_key_t *key, void (*destr_function) (void*));
```

首先从 linux 的 TSD 池中分配一项，然后将其值赋给 key 供以后访问使用。接口的第一个参数是指向参数的指针，第二参数是函数指针，如果该指针不为空，那么在线程执行完毕退出时，已 key 指向的内容为入参调用 `destr_function()`, 释放分配的缓冲区以及其他数据。

key 被创建之后，因为是**全局变量**，所以**所有的线程**都可以访问。**各个线程**可以根据需求往 key 中，**填入不同的值**，这就相当于提供了一个**同名而值不同**的**全局变量**，即一键多值。一键多值依靠的一个结构体数组，即

```cpp
static struct pthread_key_struct pthread_keys[PTHREAD_KEYS_MAX] ={{0,NULL}};
```

`pthread_key_struct` 的定义为：

```cpp
struct pthread_key_struct
{
  /* Sequence numbers.  Even numbers indicated vacant entries.  Note
     that zero is even.  We use uintptr_t to not require padding on
     32- and 64-bit machines.  On 64-bit machines it helps to avoid
     wrapping, too.  */
  uintptr_t seq;

  /* Destructor for the data.  */
  void (*destr) (void *);
};
```



# reference

https://www.cnblogs.com/smarty/p/4046215.html
