# Geekbench 5 专测

用心做好 GB5 测试，让测试更方便、更迅速、更人性化。

## 脚本特性

1. 适配 x86_64、aarch64、riscv64
2. 针对大陆优化，缩减 GB5 程序下载时间
3. 拥有 SHA-256 校验，杜绝恶意程序
4. 针对内存不足 1G 的服务器，会自动添加 Swap
5. 测试无残留，测试产生的文件、Swap 会清除
6. 提供详细结果、个人保存链接
7. 提供同类型 CPU 参考

## 使用方法

<a target="_blank" href="https://bash.icu/gb5"><img src="https://img.shields.io/website?url=https%3A%2F%2Fbash.icu%2Fgb5&label=bash.icu%2Fgb5&cacheSeconds=300" />

```
bash <(curl -sL bash.icu/gb5)
```

或

```
bash <(wget -qO- https://raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh)
```

## 使用截图

- 输出结果

![](https://github.com/i-abc/GB5/raw/main/images/1.png)

```
# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #
#            专用于服务器的GB5测试             #
#                 v2023-08-07                  #
#        https://github.com/i-abc/gb5          #
# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #

当前时间：2023-08-07 08:22:28 UTC
净测试时长：2分47秒

Geekbench 5 测试结果

系统信息
  Operating System              Red Hat Enterprise Linux 9.2 (Plow)
  Kernel                        Linux 5.14.0-284.11.1.el9_2.x86_64 x86_64
  Model                         Xen HVM domU
  Motherboard                   N/A
  BIOS                          Xen 4.11.amazon

处理器信息
  Name                          Intel Xeon E5-2676 v3
  Topology                      1 Processor, 1 Core
  Identifier                    GenuineIntel Family 6 Model 63 Stepping 2
  Base Frequency                2.39 GHz
  L1 Instruction Cache          32.0 KB
  L1 Data Cache                 32.0 KB
  L2 Cache                      256 KB
  L3 Cache                      30.0 MB

内存信息
  Size                          769 MB

单核测试分数：683
多核测试分数：681
详细结果链接：https://browser.geekbench.com/v5/cpu/21552304
可供参考链接：https://browser.geekbench.com/search?k=v5_cpu&q=Intel%20Xeon%20E5-2676%20v3

个人保存链接：https://browser.geekbench.com/v5/cpu/21552304/claim?key=485945
```

- 完整过程

![](https://github.com/i-abc/GB5/raw/main/images/1.gif)

- x86_64

![](https://github.com/i-abc/GB5/raw/main/images/2.png)

- aarch64

![](https://github.com/i-abc/GB5/raw/main/images/3.png)

## 待办

- [x] 将分数直接展示到终端
- [x] 在测试后会提供同种 CPU 的对比
- [ ] 增加更多 CPU 方面的测试
- [ ] lxc 添加 Swap 失败
- [x] 支持 ARM
- [ ] 添加 GB6
- [ ] 在进行 GB 测试前先进行简单的 CPU 测试，若涉及 Swap 还要测试硬盘，通过后才进行 GB 测试，见 [issue 1](https://github.com/i-abc/GB5/issues/1)
