#!/bin/bash

##### 自定义常量 ######

# 脚本发布版本
script_version="v2024-03-24"

# geekbench5发布版本
geekbench_version="5.5.1"

# geekbench5官方SHA-256
geekbench_x86_64_official_sha256="32037e55c3dc8f360fe16b7fbb188d31387ea75980e48d8cf028330e3239c404"
geekbench_aarch64_official_sha256="9eb3ca9ec32abf0ebe1c64002b19108bfea53c411c6b556b0c2689514b8cbd6f"
geekbench_riscv64_official_sha256="65070301ccedd33bfd4797a19e9d28991fe719cc38570dbc445b8355a5b9bc64"

# 下载源
url_1="https://cdn.geekbench.com"
url_2="https://asset.bash.icu/https://cdn.geekbench.com"

# 测试工作目录
dir="./gb5-github-i-abc"

##### 配色 #####

_red() {
    echo -e "\033[0;31;31m$1\033[0m"
}

_yellow() {
    echo -e "\033[0;31;33m$1\033[0m"
}

_blue() {
    echo -e "\033[0;31;36m$1\033[0m"
}

##### 横幅 #####
_banner() {
    echo -e "# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #"
    echo -e "#            专用于服务器的GB5测试             #"
    echo -e "#                 $script_version                  #"
    echo -e "#         $(_yellow "bash <(curl -sL bash.icu/gb5)")        #"
    echo -e "#         https://github.com/i-abc/gb5         #"
    echo -e "# ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #"
    echo
}

##### 检测某软件包是否安装，没安则自动安上，目前只支持RedHat、Debian系 #####
_check_package() {
    _yellow "正在检测所需的$1是否安装"
    # 检测软件包是否安装
    if ! command -v $1; then
        # 确认包管理器并安装软件包
        if command -v dnf; then
            sudo dnf -y install $2
        elif command -v yum; then
            sudo yum -y install $2
        elif command -v apt; then
            sudo apt -y install $2
        else
            _blue "本机非RedHat、Debian系，暂不支持自动安装所需的软件包"
            exit
        fi
        # 再次检测软件包是否安装
        if ! command -v $1; then
            _red "自动安装所需的$1失败"
            echo "请手动安装$1后再执行本脚本"
            exit
        fi
    fi
}

##### 确认架构及对应的tar包 #####
# Geekbench 5、6只支持64位，即x86_64、aarch64、riscv64
_check_architecture() {
    # 非64位直接退出
    if [ "$(getconf LONG_BIT)" != "64" ]; then
        echo "本脚本目前只支持64位处理器"
        exit
    fi

    # 判断是x86_64、aarch64还是riscv64
    if [ "$(uname -m)" == "x86_64" ]; then
        _blue "本机架构：x86_64"
        geekbench_tar_name=Geekbench-$geekbench_version-Linux.tar.gz
        geekbench_tar_folder=Geekbench-$geekbench_version-Linux
        geekbench_official_sha256=$geekbench_x86_64_official_sha256
        geekbench_software_name=geekbench5
    elif [ "$(uname -m)" == "aarch64" ]; then
        _blue "本机架构：aarch64"
        geekbench_tar_name=Geekbench-$geekbench_version-LinuxARMPreview.tar.gz
        geekbench_tar_folder=Geekbench-$geekbench_version-LinuxARMPreview
        geekbench_official_sha256=$geekbench_aarch64_official_sha256
        geekbench_software_name=geekbench5
    elif [ "$(uname -m)" == "riscv64" ]; then
        _blue "本机架构：riscv64"
        geekbench_tar_name=Geekbench-$geekbench_version-LinuxRISCVPreview.tar.gz
        geekbench_tar_folder=Geekbench-$geekbench_version-LinuxRISCVPreview
        geekbench_official_sha256=$geekbench_riscv64_official_sha256
        geekbench_software_name=geekbench5
    else
        echo "本脚本目前只支持x86_64、aarch64、riscv64架构"
        exit
    fi
    _blue "本机虚拟：$(systemd-detect-virt)"
}

##### 创建目录 #####
_make_dir() {
    # 删除可能存在的残余文件
    sudo swapoff $dir/swap &>/dev/null
    rm -rf $dir

    # 创建目录
    mkdir $dir
}

##### 检测内存，增加Swap #####
_check_swap() {
    # 检测内存
    mem=$(free -m | awk '/Mem/{print $2}')
    old_swap=$(free -m | awk '/Swap/{print $2}')
    old_ms=$((mem + old_swap))
    _blue "本机内存：${mem}Mi"
    _blue "本机Swap：${old_swap}Mi"
    _blue "内存加Swap总计：${old_ms}Mi\n"

    # 判断内存是否小于1G、或内存+Swap是否小于1.25G，若都小于则加Swap
    if [ "$mem" -ge "1024" ]; then
        _yellow "经判断，本机内存大于1G，满足GB5测试条件\n"
    elif [ "$old_ms" -ge "1280" ]; then
        _yellow "经判断，本机内存加Swap总计大于1.25G，满足GB5测试条件\n"
    else
        echo "经判断，本机内存小于1G，且内存加Swap总计小于1.25G，不满足GB5测试条件，有如下解决方案："
        echo "1. 添加Swap (该操作脚本自动完成，且在GB5测试结束后会把本机恢复原样)"
        echo -e "2. 退出测试\n"
        _yellow "请输入您的选择 (序号)：\c"
        read -r choice_1
        echo -e "\033[0m"
        case "$choice_1" in
        2)
            exit
            ;;
        # 添加Swap
        1)
            _yellow "添加Swap任务开始，完成时间取决于硬盘速度，请耐心等候\n"
            need_swap=$((1300 - old_ms))
            # fallocate -l "$need_swap"M $dir/swap
            # fallocate在RHEL6、7上创建swap失败，见https://access.redhat.com/solutions/4570081
            sudo dd if=/dev/zero of=$dir/swap bs=1M count=$need_swap
            sudo chmod 0600 $dir/swap
            sudo mkswap $dir/swap
            sudo swapon $dir/swap

            # 再次判断内存+Swap是否小于1.25G
            new_swap=$(free -m | awk '/Swap/{print $2}')
            new_ms=$((mem + new_swap))
            if [ "$new_ms" -ge "1280" ]; then
                echo
                _blue "经判断，现在内存加Swap总计${new_ms}Mi，满足GB5测试条件\n"
            else
                echo
                echo "很抱歉，由于未知原因，Swap未能成功新增，现在内存加Swap总计${new_ms}Mi，仍不满足GB5测试条件，有如下备选方案："
                echo "1. 强制执行GB5测试"
                echo -e "2. 退出测试\n"
                _yellow "请输入您的选择 (序号)：\c"
                read -r choice_2
                echo -e "\033[0m"
                case "$choice_2" in
                2)
                    exit
                    ;;
                1)
                    echo
                    ;;
                *)
                    _red "输入错误，请重新执行脚本"
                    exit
                    ;;
                esac
            fi
            ;;
        *)
            _red "输入错误，请重新执行脚本"
            exit
            ;;
        esac
    fi
}

##### 判断IP类型 #####
# 对 IPv6 单栈的服务器来说进行测试没有意义，
# 因为要将结果上传到 browser.geekbench.com 后才能拿到最后的跑分，
# 但 browser.geekbench.com 仅有 IPv4、不支持 IPv6，测了也是白测。
_check_ip() {
    if ! curl -s 'https://browser.geekbench.com' --connect-timeout 5 >/dev/null; then
        echo -e "对 IPv6 单栈的服务器来说进行测试没有意义，\n因为要将结果上传到 browser.geekbench.com 后才能拿到最后的跑分，\n但 browser.geekbench.com 仅有 IPv4、不支持 IPv6，测了也是白测。"
        exit 1
    fi
}

##### 判断IP所在地，选择相应下载源 #####
_check_region() {
    local loc
    loc="$(curl -s -L 'https://www.qualcomm.cn/cdn-cgi/trace' | awk -F '=' '/loc/{print $2}')"
    echo "loc: ${loc}"
    if [ -z "$loc" ]; then
        echo "使用镜像源"
        geekbench_tar_url=${url_2}/${geekbench_tar_name}
    elif [ "$loc" != "CN" ]; then
        echo "使用默认源"
        geekbench_tar_url=${url_1}/${geekbench_tar_name}
    else
        echo "使用镜像源"
        geekbench_tar_url=${url_2}/${geekbench_tar_name}
    fi
}

##### 下载Geekbench tar包 ######
_download_geekbench() {
    _yellow "测试软件下载中"
    curl --progress-bar -o "$dir/${geekbench_tar_name}" -L "$geekbench_tar_url"
}

##### 计算SHA-256并比对 #####
_check_sha256() {
    # 计算SHA-256
    geekbench_download_sha256=$(sha256sum $dir/${geekbench_tar_name} | awk '{print $1}')
    # 比对SHA-256
    if [ "$geekbench_download_sha256" == "$geekbench_official_sha256" ]; then
        _blue "经比对，下载的程序与官网SHA-256相同，放心使用"
    else
        _red "经比对，下载的程序与官网SHA-256不相同，退出脚本执行"
        _red "事关重大，方便的话麻烦到 https://github.com/i-abc/gb5 提一个issue"
        exit
    fi
}

##### 解tar包 #####
_unzip_tar() {
    tar -xf $dir/${geekbench_tar_name} -C ./$dir
}

##### 运行测试 #####
_run_test() {
    _yellow "测试中\n"

    # 计时开始
    run_start_time=$(date +"%s")

    # $dir/${geekbench_tar_folder}/${geekbench_software_name} |  tee $dir/result.txt |  awk '/System Information/,/Uploading results to the Geekbench Browser/ {if ($0 ~ /Uploading results to the Geekbench Browser/) exit; print}'
    # 由于未知原因，在Debian上逐行滚动失效，故awk换为perl
    $dir/${geekbench_tar_folder}/${geekbench_software_name} | tee $dir/result.txt | perl -ne 'if (/System Information/../Uploading results to the Geekbench Browser/) {if (/Uploading results to the Geekbench Browser/) {exit;} print;}'

    # 计时结束
    run_end_time=$(date +"%s")

    # 计算测试运行时间
    run_time=$((run_end_time - run_start_time))
    run_time_minutes=$((run_time / 60))
    run_time_seconds=$((run_time % 60))
}

##### 下载含测试结果的html ######
_download_result_html() {
    result_html_url=$(grep -E "https.*cpu/[0-9]*$" $dir/result.txt)

    if wget -4 --spider $result_html_url 2>/dev/null; then
        wget -4 -O $dir/result.html $result_html_url 2>/dev/null
    else
        wget --no-check-certificate -4 -O $dir/result.html $result_html_url 2>/dev/null
    fi
}

##### 输出结果 (含时间、参数、分数、链接) #####
_output_summary() {
    # 时间
    echo "当前时间：$(date +"%Y-%m-%d %H:%M:%S %Z")"
    echo -e "净测试时长：$run_time_minutes分$run_time_seconds秒\n"

    # 参数
    _yellow "Geekbench 5 测试结果\n"
    awk '/System Information/,/Size/{sub("System Information", "系统信息"); sub("Processor Information", "处理器信息"); sub("Memory Information", "内存信息"); print}' $dir/result.txt

    # 分数
    echo
    awk -F'>' '/<div class='"'"'score'"'"'>/{print $2}' $dir/result.html |
        awk -F'<' '{if (NR==1) {print "单核测试分数："$1} else {print "多核测试分数："$1}}'

    # 链接
    awk '/https.*cpu\/[0-9]*$/{print "详细结果链接：" $1}' $dir/result.txt
    cpu=$(awk -F 'with an? | processor' '/Benchmark results for/{gsub(/ /,"%20",$2); print $2}' $dir/result.html)
    echo "可供参考链接：https://browser.geekbench.com/search?k=v5_cpu&q=$cpu"

    echo
    awk '/https.*key=[0-9]*$/{print "个人保存链接：" $1}' $dir/result.txt
}

##### 删除残余文件 #####
_rm_dir() {
    sudo swapoff $dir/swap &>/dev/null
    rm -rf $dir
    echo -e "\033[0m"
}

##### main #####
_main() {
    trap '_rm_dir' EXIT
    clear
    _banner
    _check_ip
    _check_package wget wget
    _check_package tar tar
    # _check_package fallocate util-linux
    _check_package perl perl
    clear
    _banner
    _check_architecture
    _make_dir
    _check_swap
    clear
    _banner
    _check_region
    _download_geekbench
    echo
    _check_sha256
    _unzip_tar
    clear
    _banner
    _run_test
    _download_result_html
    clear
    echo
    _banner
    _output_summary
}

_main
