#!/bin/bash

# Radxa Cubie A7Z 板子体检脚本
# 版本: v1.0
# 作者: Claude & 用户共创
# 日期: 2025-01-18

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的标题
print_title() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# 打印带颜色的状态
print_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 快速体检
quick_checkup() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════╗
║   Radxa Cubie A7Z 快速体检报告            ║
║   版本: v1.0                             ║
║   日期: $(date +%Y-%m-%d)               ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    print_title "1. 核心硬件检查"

    # CPU 检查
    cpu_cores=$(nproc)
    cpu_ok="✅"
    if [ "$cpu_cores" -eq 8 ]; then
        print_ok "CPU: 8 核心 (2×A76 + 6×A55)"
    else
        print_fail "CPU: 核心数异常 ($cpu_cores)"
    fi

    # 内存检查
    mem_total=$(free -m | awk 'NR==2{print $2}')
    mem_avail=$(free -m | awk 'NR==2{print $7}')
    if [ "$mem_total" -gt 7000 ]; then
        print_ok "内存: ${mem_avail}MB / ${mem_total}MB 可用"
    else
        print_warn "内存: ${mem_avail}MB / ${mem_total}MB (可能不足)"
    fi

    # 存储检查
    root_avail=$(df -h / | awk 'NR==2{print $4}')
    root_used=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$root_used" -lt 80 ]; then
        print_ok "存储: ${root_avail} 可用 (已用 ${root_used}%)"
    else
        print_warn "存储: ${root_avail} 可用 (已用 ${root_used}% - 空间不足)"
    fi

    print_title "2. AI 加速器检查"

    # NPU 检查
    if [ -e /dev/vipcore ]; then
        print_ok "NPU 设备: /dev/vipcore 存在"
        npu_freq=$(cat /sys/class/devfreq/3600000.npu/cur_freq 2>/dev/null | awk '{print $1/1000000 " GHz"}')
        print_info "NPU 频率: $npu_freq"
        lsmod | grep -q vipcore && print_ok "NPU 驱动: vipcore 已加载" || print_fail "NPU 驱动: 未加载"
    else
        print_fail "NPU 设备: 不存在"
    fi

    # GPU 检查
    if [ -e /dev/dri/renderD128 ]; then
        print_ok "GPU 设备: /dev/dri/renderD128 存在"
    else
        print_fail "GPU 设备: 不存在"
    fi

    print_title "3. 网络检查"

    # WiFi 检查
    if ip link show wlan0 &>/dev/null; then
        wifi_status=$(ip link show wlan0 | grep -o "state [A-Z]*" | cut -d' ' -f2)
        if [ "$wifi_status" = "UP" ]; then
            print_ok "WiFi: wlan0 已启用"
        else
            print_warn "WiFi: wlan0 未启用"
        fi
    else
        print_fail "WiFi: wlan0 不存在"
    fi

    # 蓝牙检查
    if lsmod | grep -q bluetooth; then
        print_ok "蓝牙: 驱动已加载"
    else
        print_fail "蓝牙: 驱动未加载"
    fi

    print_title "4. 热管理检查"

    # 温度检查
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}')
    npu_temp=$(cat /sys/class/thermal/thermal_zone5/temp 2>/dev/null | awk '{print $1/1000}')

    if [ $(echo "$cpu_temp < 60" | bc) -eq 1 ]; then
        print_ok "CPU 温度: ${cpu_temp}°C (正常)"
    else
        print_warn "CPU 温度: ${cpu_temp}°C (偏高)"
    fi

    if [ $(echo "$npu_temp < 60" | bc) -eq 1 ]; then
        print_ok "NPU 温度: ${npu_temp}°C (正常)"
    else
        print_warn "NPU 温度: ${npu_temp}°C (偏高)"
    fi

    # 风扇检查
    for d in /sys/class/hwmon/hwmon*; do
        if [ "$(cat $d/name 2>/dev/null)" = "pwmfan" ]; then
            pwm=$(cat $d/pwm1 2>/dev/null)
            if [ "$pwm" -gt 0 ]; then
                print_ok "风扇: 运行中 (PWM=$pwm)"
            else
                print_info "风扇: 待机 (PWM=$pwm)"
            fi
            break
        done
    done

    print_title "5. 系统状态"

    # 内核版本
    kernel_ver=$(uname -r)
    print_info "内核: $kernel_ver"

    # 系统负载
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    load_1min=$(echo $load_avg | awk '{print $1}')
    if [ $(echo "$load_1min < 2.0" | bc) -eq 1 ]; then
        print_ok "系统负载: $load_avg (正常)"
    else
        print_warn "系统负载: $load_avg (偏高)"
    fi

    # Swap 使用
    swap_used=$(free | awk 'NR==3{print ($3/$2)*100}')
    if [ $(echo "$swap_used < 10" | bc) -eq 1 ]; then
        print_info "Swap 使用: ${swap_used}% (正常)"
    else
        print_warn "Swap 使用: ${swap_used}% (较高)"
    fi

    echo ""
    echo -e "${GREEN}体检完成！${NC}"
    echo ""
}

# 详细体检
detailed_checkup() {
    print_title "🔍 详细硬件信息"

    echo -e "${BLUE}=== CPU 信息 ===${NC}"
    lscpu | grep -E "Architecture|CPU\(s\)|Thread|Core|Model name|CPU MHz|CPU max"
    echo ""

    echo -e "${BLUE}=== 内存信息 ===${NC}"
    free -h
    echo ""

    echo -e "${BLUE}=== 存储信息 ===${NC}"
    df -h
    echo ""
    lsblk
    echo ""

    echo -e "${BLUE}=== NPU 信息 ===${NC}"
    echo "设备节点: $(ls -l /dev/vipcore 2>/dev/null || echo '不存在')"
    echo "驱动状态: $(lsmod | grep vipcore || echo '未加载')"
    echo "当前频率: $(cat /sys/class/devfreq/3600000.npu/cur_freq 2>/dev/null | awk '{print $1/1000000" GHz"}')"
    echo "频率范围: $(cat /sys/class/devfreq/3600000.npu/min_freq 2>/dev/null | awk '{print $1/1000000" GHz"}') - $(cat /sys/class/devfreq/3600000.npu/max_freq 2>/dev/null | awk '{print $1/1000000" GHz"}')"
    echo ""

    echo -e "${BLUE}=== GPU 信息 ===${NC}"
    ls -l /dev/dri/*
    echo ""

    echo -e "${BLUE}=== 温度信息 ===${NC}"
    for zone in /sys/class/thermal/thermal_zone*; do
        type=$(cat $zone/type 2>/dev/null)
        temp=$(cat $zone/temp 2>/dev/null | awk '{print $1/1000"°C"}')
        printf "%-20s: %s\n" "$type" "$temp"
    done
    echo ""

    echo -e "${BLUE}=== 网络接口 ===${NC}"
    ip link show
    echo ""

    echo -e "${BLUE}=== USB 设备 ===${NC}"
    lsusb
    echo ""

    echo -e "${BLUE}=== 内核模块 (前 20) ===${NC}"
    lsmod | head -20
    echo ""
}

# 性能基准测试
performance_test() {
    print_title "⚡ 性能基准测试"

    echo -e "${YELLOW}警告: 此测试将消耗一定系统资源，大约需要 1-2 分钟${NC}"
    read -p "是否继续？(y/N): " choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo "已取消"
        return
    fi

    echo -e "${BLUE}=== CPU 性能测试 ===${NC}"
    echo "测试中 (单核计算性能)..."
    start_time=$(date +%s.%N)
    for i in {1..100000}; do
        echo "scale=20; 4*a(1)" | bc -l > /dev/null
    done
    end_time=$(date +%s.%N)
    cpu_time=$(echo "$end_time - $start_time" | bc)
    echo "CPU 计算耗时: ${cpu_time} 秒"
    echo ""

    echo -e "${BLUE}=== 内存性能测试 ===${NC}"
    echo "测试中 (读写速度)..."
    mem_speed=$(dd if=/dev/zero of=/tmp/memtest bs=1M count=100 2>&1 | grep copied | awk '{print $11}')
    rm -f /tmp/memtest
    echo "内存写入速度: $mem_speed"
    echo ""

    echo -e "${BLUE}=== 存储性能测试 ===${NC}"
    echo "测试中 (随机读写)..."
    disk_read=$(hdparm -t /dev/mmcblk0 2>&1 | grep -oP "Timing buffered disk reads: \K[0-9.]* MB/sec" || echo "N/A")
    echo "磁盘读取速度: $disk_read"
    echo ""

    echo -e "${BLUE}=== NPU 性能测试 ===${NC}"
    if [ -x ~/npu_test/ai-sdk/examples/vpm_run/vpm_run ]; then
        echo "测试中 (ResNet50 推理)..."
        cd ~/npu_test/ai-sdk/examples/vpm_run
        export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
        npu_time=$(./vpm_run -s sample_resnet50.txt -l 10 -b 1 2>&1 | grep "profile inference time" | awk '{print $4/1000" ms"}')
        echo "NPU 推理时间: $npu_time"
    else
        echo "NPU 工具不存在，跳过测试"
    fi
    echo ""

    echo -e "${GREEN}性能测试完成！${NC}"
}

# 开发环境检查
dev_env_check() {
    print_title "🛠️ 开发环境检查"

    echo -e "${BLUE}=== 编译工具 ===${NC}"
    which gcc && echo "GCC: $(gcc --version | head -1)" || echo "GCC: 未安装"
    which g++ && echo "G++: $(g++ --version | head -1)" || echo "G++: 未安装"
    which make && echo "Make: $(make --version | head -1)" || echo "Make: 未安装"
    echo ""

    echo -e "${BLUE}=== Python 环境 ===${NC}"
    python3 --version
    echo "已安装包:"
    pip3 list 2>/dev/null | grep -E "numpy|opencv|pillow" || echo "  (无)"
    echo ""

    echo -e "${BLUE}=== NPU SDK ===${NC}"
    if [ -d ~/npu_test/ai-sdk ]; then
        echo "SDK 路径: ~/npu_test/ai-sdk"
        if [ -x ~/npu_test/ai-sdk/examples/vpm_run/vpm_run ]; then
            echo "vpm_run: 已编译"
        else
            echo "vpm_run: 未编译"
        fi
    else
        echo "SDK: 未安装"
    fi
    echo ""

    echo -e "${BLUE}=== 库路径 ===${NC}"
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
    echo ""
}

# 诊断模式
diagnosis_mode() {
    print_title "🔧 诊断模式"

    echo -e "${BLUE}=== 检查常见问题 ===${NC}"

    # 检查 NPU 库路径
    if echo "$LD_LIBRARY_PATH" | grep -q viplite; then
        print_ok "NPU 库路径已设置"
    else
        print_fail "NPU 库路径未设置"
        echo "   解决方法: export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/"
    fi

    # 检查 NPU 设备权限
    if [ -r /dev/vipcore ] && [ -w /dev/vipcore ]; then
        print_ok "NPU 设备权限正常"
    else
        print_warn "NPU 设备权限异常"
        ls -l /dev/vipcore
    fi

    # 检查磁盘空间
    disk_used=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$disk_used" -gt 90 ]; then
        print_fail "磁盘空间不足"
        df -h /
    else
        print_ok "磁盘空间充足"
    fi

    # 检查内存压力
    mem_percent=$(free | awk 'NR==2{printf "%.0f", ($3/$2)*100}')
    if [ "$mem_percent" -gt 90 ]; then
        print_fail "内存使用率过高 (${mem_percent}%)"
        free -h
    else
        print_ok "内存使用正常 (${mem_percent}%)"
    fi

    # 检查温度
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}')
    if [ $(echo "$cpu_temp > 80" | bc 2>/dev/null || echo 0) -eq 1 ]; then
        print_fail "CPU 温度过高 (${cpu_temp}°C)"
    else
        print_ok "CPU 温度正常 (${cpu_temp}°C)"
    fi

    echo ""
}

# 生成报告
generate_report() {
    report_file="~/npu_test/health_report_$(date +%Y%m%d_%H%M%S).txt"
    report_file=$(eval echo $report_file)

    print_title "📄 生成健康报告"

    {
        echo "========================================="
        echo "   Radxa Cubie A7Z 健康报告"
        echo "   生成时间: $(date)"
        echo "========================================="
        echo ""

        echo "=== 系统信息 ==="
        uname -a
        echo ""

        echo "=== 硬件信息 ==="
        echo "CPU: $(nproc) 核心"
        echo "内存: $(free -h | awk 'NR==2{print $2}')"
        echo "存储: $(df -h / | awk 'NR==2{print $2}')"
        echo ""

        echo "=== 当前状态 ==="
        echo "CPU 温度: $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000"°C"}')"
        echo "NPU 温度: $(cat /sys/class/thermal/thermal_zone5/temp 2>/dev/null | awk '{print $1/1000"°C"}')"
        echo "系统负载: $(uptime | awk -F'load average:' '{print $2}')"
        echo "内存使用: $(free | awk 'NR==2{printf "%.0f%%", ($3/$2)*100}')"
        echo "存储使用: $(df / | awk 'NR==2{print $5}')"
        echo ""

        echo "=== 设备状态 ==="
        ls -l /dev/vipcore 2>/dev/null || echo "NPU: 不存在"
        ls -l /dev/dri/renderD128 2>/dev/null || echo "GPU: 不存在"
        ip link show wlan0 2>/dev/null | grep -q "state UP" && echo "WiFi: 已启用" || echo "WiFi: 未启用"
        lsmod | grep -q bluetooth && echo "蓝牙: 已加载" || echo "蓝牙: 未加载"
        echo ""

        echo "=== 已加载模块 (前 20) ==="
        lsmod | head -20
        echo ""

    } > "$report_file"

    print_ok "报告已保存到: $report_file"
    echo ""
}

# 主菜单
show_menu() {
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Radxa Cubie A7Z 体检工具              ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1. 快速体检 (推荐)"
    echo "  2. 详细硬件信息"
    echo "  3. 性能基准测试"
    echo "  4. 开发环境检查"
    echo "  5. 诊断模式"
    echo "  6. 生成健康报告"
    echo "  7. 全部检查"
    echo "  0. 退出"
    echo ""
}

# 全部检查
run_all() {
    quick_checkup
    read -p "按回车继续..."
    detailed_checkup
    read -p "按回车继续..."
    dev_env_check
    read -p "按回车继续..."
    diagnosis_mode
    read -p "按回车继续..."
    generate_report
}

# 主循环
main() {
    if [ $# -eq 0 ]; then
        # 交互模式
        while true; do
            show_menu
            read -p "请选择 [0-7]: " choice
            case $choice in
                1) quick_checkup ;;
                2) detailed_checkup ;;
                3) performance_test ;;
                4) dev_env_check ;;
                5) diagnosis_mode ;;
                6) generate_report ;;
                7) run_all ;;
                0) echo "退出"; exit 0 ;;
                *) echo -e "${RED}无效选择${NC}" ;;
            esac
            read -p "按回车继续..."
            clear
        done
    else
        # 命令行模式
        case "$1" in
            quick|q) quick_checkup ;;
            detail|d) detailed_checkup ;;
            perf|p) performance_test ;;
            dev|e) dev_env_check ;;
            diag) diagnosis_mode ;;
            report|r) generate_report ;;
            all|a) run_all ;;
            *) echo "用法: $0 [quick|detail|perf|dev|diag|report|all]" ;;
        esac
    fi
}

main "$@"
