# Geekbench 5 专测

用心做好 GB5 测试，让测试更方便、更迅速、更人性化。

## 脚本特性

1. 一键即用，无需提前做任何准备
2. 针对大陆网络优化，大大缩减 GB5 测试程序下载时间
3. 拥有 SHA-256 校验，杜绝恶意程序
4. 针对内存不足 1G 的服务器，会自动添加 Swap
5. 测试无残留，测试产生的文件、Swap 会自动清除，让服务器保持原样
6. 人性化的交互，操作无门槛
7. 测试结果详细、易于分享

## 使用方法

```
bash <(wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh)
```

## 使用截图

![](https://cdn.staticaly.com/gh/i-abc/GB5/main/images/1.gif)

结果链接：[链接](https://browser.geekbench.com/v5/cpu/21531872)

## 待办

- [] 将分数直接展示到终端
- [] 在测试后会提供同种 CPU 的对比
