# Geekbench 5 专测

用心做好 GB5 测试，让测试更方便、更迅速、更人性化。

## 脚本特性

1. 一键即用，无需提前做任何准备
2. 适配 x86_64、aarch64
3. 自动选源，国内启用镜像源
4. 拥有 SHA-256 校验，杜绝恶意程序
5. 针对内存不足 1G 的服务器，会自动添加 Swap
6. 测试无残留，测试产生的文件、Swap 会自动清除
7. 测试结果易于分享
8. 提供个人保存链接
9. 提供同类型 CPU 供比对参考

## 使用方法

```
bash <(curl -sL gb5.top)
```

或

```
bash <(wget -qO- gb5.top)
```

或
```
bash <(wget -qO- https://gb5.top)
```

或

```
bash <(wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh)
```

## 使用截图

- 输出结果

![](https://github.com/i-abc/GB5/raw/main/images/1.png)

- 完整过程

![](https://github.com/i-abc/GB5/raw/main/images/1.gif)

## 待办

- [x] 将分数直接展示到终端
- [x] 在测试后会提供同种 CPU 的对比
- [ ] 增加更多 CPU 方面的测试
- [ ] lxc 添加 Swap 失败
- [x] 支持 ARM
- [ ] 添加 GB6
- [ ] 在进行 GB 测试前先进行简单的 CPU 测试，若涉及 Swap 还要测试硬盘，通过后才进行 GB 测试，见 [issue 1](https://github.com/i-abc/GB5/issues/1)
