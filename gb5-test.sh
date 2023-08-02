#!/bin/bash
# 专用于境内服务器Geekbench 5测试脚本
# 境内从Geekbench官网下测试程序奇慢无比，本脚本对境内使用做了优化，让下载更快。

# 配色
_red() {
    echo -e "\033[0;31;31m$1\033[0m"
}

_yellow() {
    echo -e "\033[0;31;33m$1\033[0m"
}

_blue() {
    echo -e "\033[0;31;36m$1\033[0m"
}

clear

GB5_version="v2023-07-31"

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#          专用于境内服务器的GB5测试           #'
echo -e '#                 '$GB5_version'                  #'
echo -e '#        https://github.com/i-abc/gb5          #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo


# 删除可能存在的残余文件
rm -rf ./GB5-test-32037e55c3

# 创建工作目录
mkdir ./GB5-test-32037e55c3

# 检测内存
mem=$(free -m | awk '/Mem/{print $2}')
old_swap=$(free -m | awk '/Swap/{print $2}')
ms=$((mem+old_swap))
echo -e "
本机内存为：${mem}Mi\n\
本机Swap为：${old_swap}Mi\n\
本机内存加Swap总计：${ms}Mi"

# 判断内存+Swap是否小于1G
if [ "$ms" -ge 1024 ]
then
    echo "经判断，本机内存加Swap和大于1G，满足GB5测试条件，测试开始。"
else
    echo "经判断，本机内存加Swap和小于1G，不满足GB5测试条件，有如下解决方案："
    echo -e "
1. 添加Swap（该操作脚本自动完成，且在GB5测试结束后会把本机恢复原样）\n\
2. 退出测试"
    echo "请输入您的选择："
    # 添加Swap
    read -r choice
    case "$choice" in
        2)
            rm -rf ./GB5-test-32037e55c3
            exit;;
        1)
            need_swap=$((1100-ms))
            dd if=/dev/zero of=./GB5-test-32037e55c3/dd bs=1M count="$need_swap"
            chmod 600 ./GB5-test-32037e55c3/dd
            mkswap ./GB5-test-32037e55c3/dd
            swapon ./GB5-test-32037e55c3/dd;;
        *)
            rm -rf ./GB5-test-32037e55c3
            echo "输入错误，请重新执行脚本"
            exit;;
    esac
fi

# 官方文件的SHA-256值
GB5_official_sha256=32037e55c3dc8f360fe16b7fbb188d31387ea75980e48d8cf028330e3239c404

# 下载GB5测试程序
_yellow "GB5测试程序下载中(该文件较大)"
curl --progress-bar -o ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz https://ghproxy.com/https://raw.githubusercontent.com/i-abc/GB5/main/Geekbench-5/Geekbench-5.5.1-Linux.tar.gz
_blue "GB5测试程序下载完成\n"

# 比对SHA-256
_yellow "文件SHA-256比对中"
GB5_download_sha256=$(sha256sum ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz | awk '{print $1}')


if [ "$GB5_download_sha256" == "$GB5_official_sha256" ]
then
    _blue "经比对，下载的程序与官网SHA-256相同，放心使用\n"
else
    _red "经比对，下载的程序与官网SHA-256不相同，退出脚本执行"
    _red "事关重大，方便的话麻烦到 https://github.com/i-abc/gb5 提一个issue"
    exit
fi

# 解压缩包
tar -xf ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz -C ./GB5-test-32037e55c3

# 测试
_yellow "测试中"

./GB5-test-32037e55c3/Geekbench-5.5.1-Linux/geekbench_x86_64 | \
    awk '/System Information/ {flag=1} flag && count<68 {print; count++} /https.*cpu\/[0-9]*$/{print "测试结果链接：" $0}'

_blue "⬆将链接复制到浏览器即可查看详细结果⬆"

# 删除残余文件
swapoff ./GB5-test-32037e55c3/dd &> /dev/null
rm -rf ./GB5-test-32037e55c3
echo "残余文件清除成功"
