# Radxa Cubie A7Z 体检命令速查手册

> 🩺 **快速了解板子身体状况 - 命令速查表**

---

## 📋 目录

1. [一键体检](#一键体检)
2. [分类检查命令](#分类检查命令)
3. [健康基准值](#健康基准值)
4. [问题诊断](#问题诊断)
5. [定制化开发建议](#定制化开发建议)

---

## 🚀 一键体检

### 方法 1：使用体检脚本（推荐）

```bash
# 赋予执行权限
chmod +x ~/npu_test/board_checkup.sh

# 快速体检
~/npu_test/board_checkup.sh quick

# 详细体检
~/npu_test/board_checkup.sh detail

# 性能测试
~/npu_test/board_checkup.sh perf

# 开发环境检查
~/npu_test/board_checkup.sh dev

# 诊断模式
~/npu_test/board_checkup.sh diag

# 生成报告
~/npu_test/board_checkup.sh report

# 交互式菜单
~/npu_test/board_checkup.sh

# 全部检查
~/npu_test/board_checkup.sh all
```

### 方法 2：快速检查命令

```bash
# 一行命令查看所有关键信息
echo "=== CPU ===" && lscpu | grep "CPU(s)" && \
echo "=== 内存 ===" && free -h && \
echo "=== 存储 ===" && df -h / && \
echo "=== NPU ===" && ls -l /dev/vipcore && \
echo "=== 温度 ===" && cat /sys/class/thermal/thermal_zone*/temp | awk '{print $1/1000"°C"}' && \
echo "=== 负载 ===" && uptime
```

---

## 📊 分类检查命令

### 1. CPU 检查

#### 基本信息
```bash
# CPU 型号和核心数
lscpu | grep -E "Architecture|CPU\(s\)|Model name"

# CPU 频率（当前/最小/最大）
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

# CPU 使用率
top -bn1 | grep "Cpu(s)"

# CPU 调节器
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

#### 性能测试
```bash
# 单核性能测试
time for i in {1..10000}; do echo "scale=20; 4*a(1)" | bc -l > /dev/null; done

# 压力测试（8 核）
stress --cpu 8 --timeout 10s

# 查看调度器
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors
```

### 2. 内存检查

#### 基本信息
```bash
# 内存使用情况
free -h

# 详细内存信息
cat /proc/meminfo | head -20

# Swap 使用
free | awk 'NR==3{print "Swap:", $3, "/", $2}'
```

#### 性能测试
```bash
# 内存读写速度
dd if=/dev/zero of=/tmp/memtest bs=1M count=100 conv=fdatasync
rm /tmp/memtest

# 内存带宽
sysbench memory --memory-block-size=1K --memory-total-size=10G run
```

### 3. 存储检查

#### 基本信息
```bash
# 磁盘使用
df -h

# 分区详情
lsblk

# eMMC 信息
sudo fdisk -l /dev/mmcblk0
```

#### 性能测试
```bash
# 读取速度
sudo hdparm -t /dev/mmcblk0

# 随机读写
sudo f3probe --destructive --time-ops /dev/mmcblk0

# IOPS 测试
sudo hdparm -T /dev/mmcblk0
```

### 4. NPU 检查

#### 基本信息
```bash
# NPU 设备状态
ls -l /dev/vipcore

# NPU 驱动
lsmod | grep vipcore

# NPU 频率
cat /sys/class/devfreq/3600000.npu/cur_freq
cat /sys/class/devfreq/3600000.npu/min_freq
cat /sys/class/devfreq/3600000.npu/max_freq

# NPU 温度
cat /sys/class/thermal/thermal_zone5/temp | awk '{print $1/1000"°C"}'

# NPU 调节器
cat /sys/class/devfreq/3600000.npu/governor
cat /sys/class/devfreq/3600000.npu/available_governors
```

#### 性能测试
```bash
# 设置库路径
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# ResNet50 推理测试
cd ~/npu_test/ai-sdk/examples/vpm_run
./vpm_run -s sample_resnet50.txt -l 100 -b 1

# LeNet 推理测试
./vpm_run -s sample_lenet.txt -l 100 -b 1
```

### 5. GPU 检查

```bash
# GPU 设备
ls -l /dev/dri/*

# GPU 频率
cat /sys/class/devfreq/1800000.gpu/cur_freq 2>/dev/null

# GPU 温度
cat /sys/class/thermal/thermal_zone4/temp | awk '{print $1/1000"°C"}'

# GPU 信息（如果 glxinfo 可用）
glxinfo | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version"
```

### 6. 网络检查

#### WiFi
```bash
# WiFi 接口状态
ip link show wlan0

# WiFi 连接状态
iw dev wlan0 link

# WiFi 扫描
sudo iw dev wlan0 scan | less

# WiFi 信号强度
iwconfig wlan0 2>/dev/null | grep "Link Quality"
```

#### 蓝牙
```bash
# 蓝牙状态
rfkill list bluetooth

# 蓝牙控制器
bluetoothctl list

# 蓝牙适配器信息
bluetoothctl show
```

#### 以太网
```bash
# 以太网接口
ip link show eth0 2>/dev/null || ip link show enp*

# IP 地址
ip addr show

# 网络连通性
ping -c 4 8.8.8.8
```

### 7. 温度检查

```bash
# 所有热区温度
for zone in /sys/class/thermal/thermal_zone*; do
    type=$(cat $zone/type)
    temp=$(cat $zone/temp | awk '{print $1/1000"°C"}')
    printf "%-20s: %s\n" "$type" "$temp"
done

# 触发点温度
cat /sys/class/thermal/thermal_zone*/trip_point_*_temp | head -20

# 风扇状态
cat /sys/class/hwmon/hwmon*/pwm1
cat /sys/class/hwmon/hwmon*/name | grep pwmfan
```

### 8. 电源检查

```bash
# 电池信息（如果有）
cat /sys/class/power_supply/battery/capacity 2>/dev/null

# PMIC 信息
sudo i2cdump -y 1 0x36 0x00 0x10  # AXP2101

# 电源状态
cat /sys/class/power_supply/*/status
```

### 9. 内核与驱动

```bash
# 内核版本
uname -r

# 已加载模块
lsmod

# NPU 相关模块
lsmod | grep -E "vip|npu|vivante"

# WiFi 驱动
lsmod | grep aic8800

# 驱动版本
modinfo vipcore

# 设备树
cat /proc/device-tree/model
cat /proc/device-tree/compatible
```

### 10. 接口检查

```bash
# GPIO
ls -la /sys/class/gpio/

# I2C 总线
ls -la /dev/i2c-*
i2cdetect -y 1  # I2C-1

# UART 串口
ls -la /dev/tty*

# SPI
ls -la /dev/spidev*

# USB 设备
lsusb
```

---

## 📈 健康基准值

### 正常运行参考值

| 检查项 | 健康值 | 警告值 | 危险值 |
|--------|--------|--------|--------|
| **CPU 温度** | < 60°C | 60-80°C | > 80°C |
| **NPU 温度** | < 60°C | 60-80°C | > 80°C |
| **GPU 温度** | < 70°C | 70-90°C | > 90°C |
| **系统负载** | < 2.0 | 2.0-4.0 | > 4.0 |
| **内存使用** | < 80% | 80-90% | > 90% |
| **存储使用** | < 80% | 80-90% | > 90% |
| **Swap 使用** | < 10% | 10-30% | > 30% |
| **NPU 频率** | 1008 MHz | - | < 492 MHz |

### 快速健康检查命令

```bash
# 综合健康检查（一行命令）
echo "健康评分:" && \
score=0 && \
[ $(cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}') -lt 60 ] && ((score+=20)) && \
[ $(free | awk 'NR==2{printf "%.0f", ($3/$2)*100}') -lt 80 ] && ((score+=20)) && \
[ $(df / | awk 'NR==2{print $5}' | sed 's/%//') -lt 80 ] && ((score+=20)) && \
[ -e /dev/vipcore ] && ((score+=20)) && \
[ $(echo "$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}') < 2" | bc) -eq 1 ] && ((score+=20)) && \
echo "$score/100" && \
[ $score -ge 80 ] && echo "状态: 优秀" || [ $score -ge 60 ] && echo "状态: 良好" || echo "状态: 需要关注"
```

---

## 🔍 问题诊断

### 问题 1：CPU 温度过高

**症状**：CPU 温度 > 70°C

**诊断**：
```bash
# 检查当前温度
cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000"°C"}'

# 检查风扇状态
cat /sys/class/hwmon/hwmon*/pwm1

# 检查负载
top -bn1 | grep "Cpu(s)"
```

**解决**：
```bash
# 1. 降低 CPU 频率
echo powersave | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

# 2. 检查散热片
# 3. 减少后台任务
```

---

### 问题 2：NPU 不工作

**症状**：/dev/vipcore 不存在或 vpm_run 失败

**诊断**：
```bash
# 检查设备
ls -l /dev/vipcore

# 检查驱动
lsmod | grep vipcore

# 检查库路径
echo $LD_LIBRARY_PATH | grep viplite

# 检查频率
cat /sys/class/devfreq/3600000.npu/cur_freq
```

**解决**：
```bash
# 1. 加载驱动（如果未加载）
sudo modprobe vipcore

# 2. 设置库路径
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# 3. 永久设置（加入 ~/.bashrc）
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/' >> ~/.bashrc
```

---

### 问题 3：内存不足

**症状**：内存使用 > 90%

**诊断**：
```bash
# 检查内存使用
free -h

# 查看占用进程
ps aux --sort=-%mem | head -10

# 检查 Swap
free | awk 'NR==3'
```

**解决**：
```bash
# 1. 清理缓存
sudo sync && sudo sysctl -w vm.drop_caches=3

# 2. 杀掉占用内存的进程
# 3. 增加 Swap（zram）
```

---

### 问题 4：WiFi 连接问题

**症状**：无法连接 WiFi 或频繁断线

**诊断**：
```bash
# 检查接口状态
ip link show wlan0

# 检查驱动
lsmod | grep aic8800

# 检查连接
iw dev wlan0 link
```

**解决**：
```bash
# 1. 重启 WiFi
sudo ip link set wlan0 down
sudo ip link set wlan0 up

# 2. 重新加载驱动
sudo modprobe -r aic8800_fdrv
sudo modprobe aic8800_fdrv

# 3. 检查配置
nmcli connection show
```

---

### 问题 5：存储空间不足

**症状**：磁盘使用 > 90%

**诊断**：
```bash
# 查看占用
df -h

# 查找大文件
du -sh ~/* 2>/dev/null | sort -hr | head -20

# 查看 APT 缓存
du -sh /var/cache/apt/archives
```

**解决**：
```bash
# 1. 清理 APT 缓存
sudo apt clean
sudo apt autoremove

# 2. 清理日志
sudo journalctl --vacuum-time=7d

# 3. 清理大文件
# （根据具体情况）
```

---

## 🎯 定制化开发建议

### 场景 1：AI 推理优化

**目标**：最大化 NPU 性能

**体检重点**：
```bash
# 1. NPU 频率（应该在 1008 MHz）
cat /sys/class/devfreq/3600000.npu/cur_freq

# 2. NPU 温度（应该 < 60°C）
cat /sys/class/thermal/thermal_zone5/temp | awk '{print $1/1000"°C"}'

# 3. 可用内存（建议 > 2GB）
free -h | awk 'NR==2{print $7}'
```

**优化建议**：
- 使用性能调节器：`echo performance | sudo tee /sys/class/devfreq/3600000.npu/governor`
- 选择小模型（1B-3B）避免内存不足
- 批处理推理提高吞吐量

---

### 场景 2：低功耗应用

**目标**：最小化功耗

**体检重点**：
```bash
# 1. CPU 频率（应该最低）
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

# 2. 温度（应该 < 50°C）
cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000"°C"}'

# 3. 负载（应该 < 1.0）
uptime | awk -F'load average:' '{print $2}'
```

**优化建议**：
- 使用节能调节器：`echo powersave | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
- 关闭不必要的外设
- 降低 NPU 频率：`echo userspace | sudo tee /sys/class/devfreq/3600000.npu/governor`

---

### 场景 3：边缘计算部署

**目标**：稳定长期运行

**体检重点**：
```bash
# 1. 磁盘健康
df -h
sudo smartctl -H /dev/mmcblk0 2>/dev/null

# 2. 热管理
cat /sys/class/thermal/thermal_zone*/temp | awk '{print $1/1000"°C"}'

# 3. 系统日志
sudo journalctl -p err -n 20
```

**优化建议**：
- 配置定期清理任务
- 监控温度和风扇
- 使用 zram 减少 eMMC 磨损

---

### 场景 4：实时处理

**目标**：最小化延迟

**体检重点**：
```bash
# 1. CPU 调度器
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 2. 中断负载
cat /proc/interrupts | head -20

# 3. 上下文切换
vmstat 1 5
```

**优化建议**：
- 使用 performance 调节器
- 绑定中断到特定 CPU
- 禁用不必要的服务

---

### 场景 5：高并发服务

**目标**：最大化吞吐量

**体检重点**：
```bash
# 1. 文件描述符限制
ulimit -n

# 2. 网络连接数
ss -s

# 3. 内存压力
free -h
vmstat 1
```

**优化建议**：
- 增加文件描述符限制
- 调整 TCP 参数
- 使用连接池

---

## 📝 体检报告模板

### 每日体检

```bash
# 快速检查（30 秒）
~/npu_test/board_checkup.sh quick > ~/npu_test/daily_check.txt 2>&1
```

### 每周体检

```bash
# 完整检查（5 分钟）
~/npu_test/board_checkup.sh all > ~/npu_test/weekly_check_$(date +%Y%m%d).txt 2>&1
```

### 性能基准

```bash
# 性能测试（10 分钟）
~/npu_test/board_checkup.sh perf > ~/npu_test/benchmark_$(date +%Y%m%d).txt 2>&1
```

---

## 🔧 快速命令别名

### 添加到 ~/.bashrc

```bash
# 体检命令别名
alias checkup='~/npu_test/board_checkup.sh quick'
alias checkall='~/npu_test/board_checkup.sh all'
alias checkperf='~/npu_test/board_checkup.sh perf'

# 硬件信息别名
alias mycpu='lscpu | grep "CPU(s)"'
alias mymem='free -h'
alias mytemp='cat /sys/class/thermal/thermal_zone*/temp | awk "{print \$1/1000\"°C\"}"'
alias mynpu='ls -l /dev/vipcore && cat /sys/class/devfreq/3600000.npu/cur_freq | awk "{print \$1/1000000\" GHz\"}"'
alias mygpu='ls -l /dev/dri/renderD128'

# 系统状态别名
alias myload='uptime'
alias mydisk='df -h'
alias mynet='ip addr show'
```

### 使用方法

```bash
# 编辑 .bashrc
nano ~/.bashrc

# 添加上面的别名

# 重新加载
source ~/.bashrc

# 使用
checkup      # 快速体检
mycpu        # 查看 CPU
mymem        # 查看内存
mynpu        # 查看 NPU
```

---

## 📞 常见问题

### Q: 如何定期自动体检？

```bash
# 添加 crontab
crontab -e

# 每天早上 8 点体检
0 8 * * * ~/npu_test/board_checkup.sh quick > ~/npu_check/$(date +\%Y\%m\%d).txt 2>&1
```

### Q: 如何远程监控？

```bash
# 使用 SSH 远程执行
ssh radxa@board-ip "~/npu_test/board_checkup.sh quick"

# 或使用 Web 服务（需要额外配置）
```

### Q: 如何对比历史数据？

```bash
# 查看历史报告
ls -lt ~/npu_test/health_report_*

# 对比两次报告
diff ~/npu_test/health_report_20250117.txt ~/npu_test/health_report_20250118.txt
```

---

## ✅ 体检检查清单

### 每日检查
- [ ] CPU 温度 < 60°C
- [ ] NPU 频率 1008 MHz
- [ ] 内存使用 < 80%
- [ ] 磁盘使用 < 90%
- [ ] 系统负载 < 2.0
- [ ] WiFi 已连接

### 每周检查
- [ ] 完整硬件扫描
- [ ] 性能基准测试
- [ ] 日志错误检查
- [ ] 磁盘健康检查
- [ ] 固件更新检查

### 每月检查
- [ ] 深度性能分析
- [ ] 历史数据对比
- [ ] 系统更新评估
- [ ] 备份重要数据

---

## 📚 相关文档

- [A7Z_开发基础信息_身份证.md](./A7Z_开发基础信息_身份证.md) - 完整硬件信息
- [A7Z_NPU_完整使用手册.md](./A7Z_NPU_完整使用手册.md) - NPU 开发指南
- [board_checkup.sh](./board_checkup.sh) - 体检脚本

---

*文档版本: v1.0*
*最后更新: 2025-01-18*
*作者: Claude & 用户共创*
