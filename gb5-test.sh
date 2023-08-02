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

GB5_version="v2023-08-02"

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

# 检测curl是否安装
if ! command -v curl &> /dev/null
then
    # 安装curl
    if command -v dnf &> /dev/null
    then
        dnf -y install curl
    elif command -v yum &> /dev/null
    then
        yum -y install curl
    elif command -v apt &> /dev/null
    then
        apt -y install curl
    fi
    # 再次检测curl是否安装成功
    if ! command -v curl &> /dev/null
    then
        exit
    fi
fi

# 检测内存
mem=$(free -m | awk '/Mem/{print $2}')
old_swap=$(free -m | awk '/Swap/{print $2}')
old_ms=$((mem+old_swap))
_blue "本机内存为：${mem}Mi"
_blue "本机Swap为：${old_swap}Mi"
_blue "本机内存加Swap总计：${old_ms}Mi\n"

# 判断内存+Swap是否小于1G
if [ "$old_ms" -ge 1100 ]
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
            dd if=/dev/zero of=./GB5-test-32037e55c3/dd bs=1M count="$need_swap"
            chmod 600 ./GB5-test-32037e55c3/dd
            mkswap ./GB5-test-32037e55c3/dd
            swapon ./GB5-test-32037e55c3/dd
            # 再次判断内存+Swap是否小于1G
            new_swap=$(free -m | awk '/Swap/{print $2}')
            new_ms=$((mem+new_swap))
            if [ "$new_ms" -ge 1100 ]
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
    awk '/System Information/ {flag=1} flag && count<68 {print; count++} /https.*cpu\/[0-9]*$/{print "测试结果链接：" $0} /https.*key=[0-9]*$/{print "保存链接：" $0}'

_blue "⬆将链接复制到浏览器即可查看详细结果⬆"

# 删除残余文件
swapoff ./GB5-test-32037e55c3/dd &> /dev/null
rm -rf ./GB5-test-32037e55c3
_yellow "残余文件清除成功"
