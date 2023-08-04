#!/bin/bash
# 一键即用，无需提前做任何准备
# 针对大陆网络优化，大大缩减 GB5 测试程序下载时间
# 拥有 SHA-256 校验，杜绝恶意程序
# 针对内存不足 1G 的服务器，会自动添加 Swap
# 测试无残留，测试产生的文件、Swap 会自动清除，让服务器保持原样
# 人性化的交互，操作无门槛
# 测试结果详细、易于分享

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

GB5_version="v2023-08-03"

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#            专用于服务器的GB5测试             #'
echo -e '#                 '$GB5_version'                  #'
echo -e '#        https://github.com/i-abc/gb5          #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo

# 检测curl、fallocate、tar是否安装
_yellow "检测所需软件包是否安装\n"
if ! (command -v curl && command -v fallocate && command -v tar)
then
    # 安装curl、fallocate、tar
    if command -v dnf
    then
        dnf -y install curl util-linux tar
    elif command -v yum
    then
        yum -y install curl util-linux tar
    elif command -v apt
    then
        apt -y install curl util-linux tar
    fi
    # 再次检测curl、fallocate、tar是否安装成功
    if ! (command -v curl && command -v fallocate && command -v tar)
    then
        _red "自动安装curl、fallocate、tar失败"
        echo "请手动安装curl、fallocate、tar后再执行该脚本"
        exit
    fi
fi

clear

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#            专用于服务器的GB5测试             #'
echo -e '#                 '$GB5_version'                  #'
echo -e '#        https://github.com/i-abc/gb5          #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo

# 源
url_1="https://cdn.geekbench.com/Geekbench-5.5.1-Linux.tar.gz"
url_2="https://ghproxy.com/https://raw.githubusercontent.com/i-abc/GB5/main/Geekbench-5/Geekbench-5.5.1-Linux.tar.gz"

# 删除可能存在的残余文件
rm -rf ./GB5-test-32037e55c3

# 创建工作目录
mkdir ./GB5-test-32037e55c3

# 检测内存
mem=$(free -m | awk '/Mem/{print $2}')
old_swap=$(free -m | awk '/Swap/{print $2}')
old_ms=$((mem+old_swap))
_blue "本机内存为：${mem}Mi"
_blue "本机Swap为：${old_swap}Mi"
_blue "本机内存加Swap总计：${old_ms}Mi\n"

# 判断内存+Swap是否小于1G
if [ "$old_ms" -ge 1024 ]
then
    _yellow "经判断，本机内存加Swap和大于1G，满足GB5测试条件，测试开始。\n"
else
    echo "经判断，本机内存加Swap和小于1G，不满足GB5测试条件，有如下解决方案："
    echo "1. 添加Swap (该操作脚本自动完成，且在GB5测试结束后会把本机恢复原样)"
    echo -e "2. 退出测试\n"
    _yellow "请输入您的选择 (序号)：\c"
    # 添加Swap
    read -r choice_1
    echo -e "\033[0m"
    case "$choice_1" in
        2)
            rm -rf ./GB5-test-32037e55c3
            exit;;
        1)
            _yellow "添加Swap任务开始，完成时间取决于硬盘速度，请耐心等候\n"
            need_swap=$((1100-old_ms))
#             dd if=/dev/zero of=./GB5-test-32037e55c3/dd bs=1M count="$need_swap"
            fallocate -l "$need_swap"M ./GB5-test-32037e55c3/dd
            chmod 600 ./GB5-test-32037e55c3/dd
            mkswap ./GB5-test-32037e55c3/dd
            swapon ./GB5-test-32037e55c3/dd
            # 再次判断内存+Swap是否小于1G
            new_swap=$(free -m | awk '/Swap/{print $2}')
            new_ms=$((mem+new_swap))
            if [ "$new_ms" -ge 1024 ]
            then
                echo
                _blue "经判断，现在内存加Swap和为${new_ms}Mi，满足GB5测试条件，测试开始。\n"
            else
                echo
                echo "很抱歉，由于未知原因，Swap未能成功新增，现在内存加Swap和为${new_ms}Mi，仍不满足GB5测试条件，有如下备选方案："
                echo "1. 强制执行GB5测试"
                echo -e "2. 退出测试\n"
                _yellow "请输入您的选择 (序号)：\c"
                read -r choice_2
                echo -e "\033[0m"
                case "$choice_2" in
                    2)
                        swapoff ./GB5-test-32037e55c3/dd &> /dev/null
                        rm -rf ./GB5-test-32037e55c3
                        exit;;
                    1)
                        echo ;;
                    *)
                        rm -rf ./GB5-test-32037e55c3
                        _red "输入错误，请重新执行脚本"
                        exit;;
                esac
            fi;;
        *)
            rm -rf ./GB5-test-32037e55c3
            _red "输入错误，请重新执行脚本"
            exit;;
    esac
fi

# 官方文件的SHA-256值
GB5_official_sha256=32037e55c3dc8f360fe16b7fbb188d31387ea75980e48d8cf028330e3239c404

# 下载GB5测试程序
_yellow "GB5测试程序下载中 (该文件较大)"
# 判断是否为境内IP
country=$(curl ipinfo.io/country 2> /dev/null)
if [ -z "$country" ] || echo "$country" | grep "{" > /dev/null
then
    echo "使用镜像源"
    curl --progress-bar -o ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz "$url_2"
elif [ "$country" != "CN" ]
then
    echo "使用默认源"
    curl --progress-bar -o ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz "$url_1"
else
    echo "使用镜像源"
    curl --progress-bar -o ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz "$url_2"
fi
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
_yellow "程序处理中\n"
tar -xf ./GB5-test-32037e55c3/Geekbench-5.5.1-Linux.tar.gz -C ./GB5-test-32037e55c3

clear

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#            专用于服务器的GB5测试             #'
echo -e '#                 '$GB5_version'                  #'
echo -e '#        https://github.com/i-abc/gb5          #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #'
echo

# 测试
_yellow "测试中"

./GB5-test-32037e55c3/Geekbench-5.5.1-Linux/geekbench_x86_64 | \
    tee >(awk '/System Information/ {flag=1} flag && count<68 {print; count++}') > ./GB5-test-32037e55c3/gb5-output.txt

# 下载测试结果
result_download_url=$(grep -E "https.*cpu\/[0-9]*$" ./GB5-test-32037e55c3/gb5-output.txt)
if wget --spider $result_download_url 2> /dev/null
then
    wget -O ./GB5-test-32037e55c3/index.html $result_download_url 2> /dev/null
else
    wget --no-check-certificate  -O ./GB5-test-32037e55c3/index.html $result_download_url 2> /dev/null
fi

# 输出分数、链接
_yellow "Geekbench 5 测试结果"
awk -F'>' '/<div class='"'"'score'"'"'>/{print $2}' ./GB5-test-32037e55c3/index.html | awk -F'<' '{if (NR==1) {print "单核测试分数: "$1} else {print "多核测试分数: "$1}}'
awk 'BEGIN{i=1}/https.*cpu/{if (i==1) {print "详细结果链接: " $1} else {print "个人保存链接: " $1}; i++}' ./GB5-test-32037e55c3/gb5-output.txt
_blue "⬆将链接复制到浏览器即可查看详细结果⬆\n"

# 删除残余文件
swapoff ./GB5-test-32037e55c3/dd &> /dev/null
rm -rf ./GB5-test-32037e55c3
_yellow "残余文件清除成功"
