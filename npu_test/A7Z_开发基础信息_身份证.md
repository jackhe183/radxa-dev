# Radxa Cubie A7Z 开发基础信息手册

> 📘 **板子"身份证" - 完整硬件配置与开发指南**

---

## 📋 目录

1. [硬件规格](#硬件规格)
2. [系统信息](#系统信息)
3. [处理器架构](#处理器架构)
4. [NPU 配置](#npu-配置)
5. [GPU 配置](#gpu-配置)
6. [内存与存储](#内存与存储)
7. [接口定义](#接口定义)
8. [网络与无线](#网络与无线)
9. [热管理](#热管理)
10. [内核与驱动](#内核与驱动)
11. [开发环境](#开发环境)
12. [引脚定义](#引脚定义)
13. [性能基准](#性能基准)

---

## 🖥️ 硬件规格

### 板子型号

```bash
Product: Radxa Cubie A7Z
Device Tree Compatible: radxa,cubie-a7z / arm,sun60iw2p1 / sun60iw2
SoC: Allwinner A733
```

### 核心参数

| 项目 | 规格 | 说明 |
|------|------|------|
| **SoC** | Allwinner A733 | ARM64 8核 |
| **CPU** | 2× Cortex-A76 @ 2.0GHz + 6× Cortex-A55 @ 1.8GHz | big.LITTLE 架构 |
| **NPU** | VeriSilicon VIPCore | 3 TOPS 算力 |
| **GPU** | Imagination BXM-4-64 MC1 | OpenGL ES 3.2 |
| **RAM** | LPDDR4/4X 8GB | 本机 8GB |
| **存储** | eMMC 29GB | 可扩展 TF 卡 |
| **尺寸** | 65mm × 30mm | Pi Zero 尺寸 |

### 官方规格书

- [产品规格书 PDF](https://dl.radxa.com/cubie/a7z/docs/radxa_cubie_a7z_product_brief_zh.pdf)
- [官方文档](https://docs.radxa.com/cubie/a7z)

---

## 💻 系统信息

### 操作系统

```bash
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
VERSION_ID="11"
VERSION_CODENAME=bullseye
Architecture: aarch64
```

### 内核版本

```bash
Linux radxa-cubie-a7z 5.15.147-7-a733 #7 SMP PREEMPT Wed Aug 20 13:06:29 UTC 2025 aarch64
Kernel: 5.15.147-7-a733 (Radxa 定制内核)
```

### 启动参数

```bash
root=UUID=dda3891f-a196-4377-be03-6fda49c5c988
console=ttyAS0,115200n8
rootwait clk_ignore_unused
mac_addr=08:51:49:dc:49:bf
mac1_addr=08:51:49:dc:49:be
cgroup_enable=cpuset
cgroup_enable=memory
swapaccount=1
```

---

## ⚡ 处理器架构

### CPU 核心配置

```
CPU implementer: 0x41 (ARM)
CPU variant: 0x2
CPU part: 0xd05 (Cortex-A55)
CPU revision: 0

核心布局:
- CPU 0-1: Cortex-A76 (性能核) @ 416-2002 MHz
- CPU 2-7: Cortex-A55 (能效核) @ 416-1800 MHz

Total: 8 核心 / 8 线程
BogoMIPS: 48.00
```

### CPU 频率调节

```bash
# 查看当前频率
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

# 查看频率范围
min_freq: 416000 KHz
max_freq: 2002000 KHz

# 调节器
governor: schedutil / performance / powersave
```

### 性能核 vs 能效核

| 核心类型 | 数量 | 频率范围 | 用途 |
|---------|------|----------|------|
| **Cortex-A76** | 2 | 416MHz - 2.0GHz | 高性能任务 |
| **Cortex-A55** | 6 | 416MHz - 1.8GHz | 低功耗任务 |

---

## 🧠 NPU 配置

### NPU 基本信息

```bash
设备节点: /dev/vipcore
权限: crw-rw-rw- (所有用户可读写)
设备ID: 199, 0

驱动模块: vipcore (249KB)
驱动版本: 0x00020003
软件版本: VIPLite 2.0.3.2-AW-2024-08-30
```

### NPU 规格

| 项目 | 值 | 说明 |
|------|---|------|
| **NPU 型号** | VeriSilicon VIPCore | 全志 A733 集成 |
| **算力** | 3 TOPS | 每秒 3 万亿次运算 |
| **设备地址** | 0x3600000 | 内存映射地址 |
| **设备数量** | 1 | 单 NPU |
| **核心数** | 1 | 单核心 |

### NPU 频率控制

```bash
设备路径: /sys/class/devfreq/3600000.npu/

Governor: performance (性能模式)
当前频率: 1008000000 Hz (1008 MHz)
最低频率: 492000000 Hz (492 MHz)
最高频率: 1008000000 Hz (1008 MHz)

可用调节器:
- performance    (性能优先)
- simple_ondemand (按需调节)
- userspace      (用户空间控制)
- sunxi_actmon   (全志活动监控)
```

### NPU 软件栈

```bash
SDK: VIPLite / ACUITY Toolkit
NPU_SW_VERSION: v2.0 (A733 专用)

库文件路径:
~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

核心库:
- libNBGlinker.so  (NBG 模型链接器)
- libVIPhal.so     (VIP 硬件抽象层)
```

### NPU 热管理

```bash
热区: /sys/class/thermal/thermal_zone5 (npu_thermal_zone)

当前温度: 38°C
触发点:
- 60°C: 风扇启动
- 110°C: 临界温度
```

### 模型格式

| 格式 | 扩展名 | 用途 |
|------|--------|------|
| NBG | .nb / .nbg | NPU 可执行模型 |
| ONNX | .onnx | 中间格式（需转换） |
| PyTorch | .pth | 训练模型（需转换） |

---

## 🎮 GPU 配置

### GPU 基本信息

```bash
设备节点:
/dev/dri/card0        (主显示设备)
/dev/dri/card1        (GPU 设备)
/dev/dri/renderD128   (渲染设备)

驱动: panfrost / lima (Mesa)
GPU: platform-1800000.gpu (Allwinner GPU)
```

### GPU 规格

| 项目 | 值 | 说明 |
|------|---|------|
| **GPU 型号** | Imagination BXM-4-64 MC1 | PowerVR 系列 |
| **设备地址** | 0x18000000 | 内存映射 |
| **API 支持** | OpenGL ES 3.2 | 移动端图形 |
| **Vulkan** | 待确认 | 可能支持 |

### GPU 频率控制

```bash
设备路径: /sys/class/devfreq/1800000.gpu/

Governor: (待确认)
当前频率: (待确认)
```

---

## 💾 内存与存储

### 内存配置

```bash
总内存: 8118572 kB (约 8GB)
可用内存: 5821484 kB (约 5.6GB)
缓存: 4836864 kB (约 4.6GB)
Swap: 3999996 kB (约 4GB, zram 压缩)

实际可用: ~5.6GB
```

### 内存分区

| 分区 | 大小 | 说明 |
|------|------|------|
| **MemTotal** | 7.7GB | 总物理内存 |
| **MemAvailable** | 5.6GB | 可用内存 |
| **Buffers** | 146MB | 文件缓冲 |
| **Cached** | 4.6GB | 页缓存 |
| **Swap** | 3.9GB | zram 压缩交换 |

### 存储配置

```bash
设备: /dev/mmcblk0 (eMMC)
总容量: 29.1GB
分区:
├─ mmcblk0p1:   16MB   /config  (配置)
├─ mmcblk0p2:  300MB   /boot/efi (EFI)
└─ mmcblk0p3: 28.8GB   /        (根文件系统)

已用: 12GB (43%)
可用: 16GB
```

### 文件系统

| 挂载点 | 设备 | 大小 | 已用 | 可用 |
|--------|------|------|------|------|
| `/` | mmcblk0p3 | 29G | 12G | 16G |
| `/boot/efi` | mmcblk0p2 | 300M | 8K | 300M |
| `/config` | mmcblk0p1 | 16M | 6K | 16M |

---

## 🔌 接口定义

### I2C 总线

```bash
I2C 控制器: 3 个
/dev/i2c-13  (TWI 3: PMIC, 0x36 - AXP2101)
/dev/i2c-14  (TWI 4: HDMI, 0x4e)
/dev/i2c-20  (HDMI CEC)

已知设备:
- 13-0036: AXP2101 PMIC (电源管理)
- 14-004e: HDMI EDID
```

### UART 串口

```bash
UART 控制器: 多个
主要串口:
- ttyAS0: 115200n8 (调试串口)
- /dev/ttyS0: UART 0
- /dev/ttyS1: UART 1

设备路径:
/sys/devices/platform/soc@3000000/2500000.uart/
/sys/devices/platform/soc@3000000/2501000.uart/
```

### GPIO

```bash
GPIO 控制器: sunxi-pinctrl
GPIO 数量: (待确认)

/sys/class/gpio/  (需要导出)
```

### SPI

```bash
SPI 总线: (待确认)
/sys/bus/spi/devices/
```

---

## 📶 网络与无线

### WiFi 配置

```bash
接口: wlan0
MAC: f4:ab:5c:e1:e8:bc
驱动: aic8800_fdrv (AIC8800D80)
芯片: AICSemi AIC 8800D80
模式: 2.4GHz / 5GHz (WiFi 6)

模块: aic8800_fdrv (479KB)
固件: aic8800-firmware
```

### 蓝牙配置

```bash
蓝牙: AIC 蓝牙 USB (aic_btusb)
驱动: bluetooth + aic_btusb
协议: BLE + Classic

hci0: (待确认)
```

### 有线网络

```bash
以太网: (待确认，可能需要 USB 适配器)
```

---

## 🌡️ 热管理

### 热区

```bash
热区数量: 7 个

1. cpul_thermal_zone  (CPU 大核) - 当前 39°C
2. cpub_thermal_zone  (CPU 小核) - 当前 37.7°C
3. cpul_idle_zone     (大核待机) - 当前 37.7°C
4. cpub_idle_zone     (小核待机) - 当前 39°C
5. gpu_thermal_zone   (GPU)     - 当前 38.1°C
6. npu_thermal_zone   (NPU)     - 当前 38.3°C
7. ddr_thermal_zone   (内存)     - 当前 38.3°C
8. skin_zone          (外壳)     - 当前 31.8°C
```

### 温度触发点

| 热区 | 主动 | 被动 | 临界 |
|------|------|------|------|
| CPU 大核 | 60°C | 90°C | 110°C |
| CPU 小核 | 60°C | 90°C | 110°C |
| GPU | 90°C | 100°C | 110°C |
| NPU | 60°C | 110°C | - |
| DDR | 90°C | 100°C | 110°C |
| 外壳 | 50°C | - | - |

### 风扇控制

```bash
风扇驱动: pwm_fan (16KB)
PWM 设备: /sys/class/hwmon/hwmonX/pwm1

控制方式: 自动 (step_wise governor)
启动温度: 60°C
档位: 0-4 (5 级调速)

当前状态: (根据温度)
```

### 风扇命令

```bash
# 检查风扇状态
cat /sys/class/hwmon/hwmon*/name | grep pwmfan

# 检查 PWM 值
cat /sys/class/hwmon/hwmonX/pwm1

# 检查风扇模式
cat /sys/class/thermal/thermal_zone0/policy
# 输出: step_wise
```

---

## 🔧 内核与驱动

### 内核模块

```bash
总模块数: (30+)

已加载关键模块:
binfmt_misc     - 二进制格式处理
rfcomm          - 蓝牙 RFCOMM
cmac            - MAC 认证
algif_hash      - 哈希算法
aes_generic     - AES 加密
ecb             - ECB 加密模式
algif_skcipher  - SK 加密
af_alg          - 算法框架
bnep            - 蓝牙网络封装
aic8800_fdrv    - AIC8800 WiFi (479KB)
aic_btusb       - AIC 蓝牙 USB
sha256_generic  - SHA256 哈希
bluetooth       - 蓝牙核心 (430KB)
cfg80211        - 无线配置 (389KB)
libaes          - AES 库
vfat            - VFAT 文件系统
fat             - FAT 文件系统
zstd            - ZSTD 压缩
zram            - 压缩内存
zsmalloc        - zsmalloc 分配器
snd_soc_sunxi_* - 音频驱动
pwm_fan         - PWM 风扇 (16KB)
```

### 固件包

```bash
已安装固件:
- aic8800-firmware           (AIC8800 WiFi/蓝牙)
- firmware-amd-graphics      (AMD GPU)
- firmware-brcm80211         (Broadcom WiFi)
- firmware-iwlwifi          (Intel WiFi)
- firmware-linux            (Linux 通用)
- firmware-realtek          (Realtek 网卡)
```

### 平台设备

```bash
兼容字符串:
allwinner,sunxi-phy-switcher    (PHY 切换器)
allwinner,sun60iw2_clock_ddr    (DDR 时钟)
allwinner,iommu-v20             (IOMMU)
allwinner,sun8i-nmi             (NMI)
allwinner,sun60iw2-pck          (PCK)
allwinner,dsufreq               (DSU 频率)
allwinner,sun60iw2-dmc          (DMC)
allwinner,npu-operating-points  (NPU OPP)
arm,psci-1.0                    (PSCI 电源接口)
gpio-leds                       (GPIO LED)
```

---

## 🛠️ 开发环境

### 编译工具

```bash
GCC: 10.2.1 (Debian 10.2.1-6)
Make: GNU Make 4.3
Python: 3.9 (默认)

可用的编译器:
- gcc (C)
- g++ (C++, 需安装)
```

### Python 环境

```bash
Python 3.9.2
pip: 已安装

已安装包:
- Pillow (图像处理)

建议安装:
- numpy (数值计算)
- opencv-python (计算机视觉)
```

### NPU SDK

```bash
路径: ~/npu_test/ai-sdk/

工具:
- vpm_run (NPU 推理工具)
- prepare_input.py (图像预处理)

SDK 组件:
- viplite-tina/        (NPU 驱动库)
- examples/            (示例代码)
  - lenet/            (手写数字)
  - resnet50/         (图像分类)
  - yolov5/           (物体检测)
  - yolact/           (实例分割)
  - vpm_run/          (推理工具)
  - multi_thread/     (多线程)
```

---

## 📍 引脚定义

### 40 针 GPIO 接头

```
（参考官方文档的引脚定义）
https://docs.radxa.com/cubie/a7z/hardware/gpio

主要引脚:
- GPIO: 多个可编程 IO
- UART: 2 组串口
- I2C: 2 组 I2C 总线
- SPI: 1-2 组 SPI
- PWM: PWM 输出
- 电源: 5V, 3.3V, GND
```

---

## 📊 性能基准

### NPU 性能

| 模型 | 参数量 | 推理时间 | 用途 |
|------|--------|----------|------|
| LeNet | ~20KB | 0.126 ms | 手写数字识别 |
| ResNet50 | ~100MB | 7.5 ms | 图像分类 |
| YOLOv5s | ~15MB | 26 ms | 物体检测 |
| YOLACT | ~100MB | 100 ms | 实例分割 |

### CPU 性能

```bash
整数性能: (待基准测试)
浮点性能: (待基准测试)
内存带宽: (待测试)
```

### GPU 性能

```bash
OpenGL ES: (待基准测试)
渲染性能: (待测试)
```

---

## 🔍 调试信息

### 设备树

```bash
获取设备树:
cat /proc/device-tree/model

查看兼容性:
cat /proc/device-tree/compatible

NPU 状态:
cat /proc/device-tree/soc@3000000/npu@3600000/status
# 输出: "okay" (正常)

GPU 状态:
cat /proc/device-tree/soc@3000000/gpu@18000000/status
# 输出: "okay" (正常)
```

### 系统日志

```bash
# 需要sudo权限
sudo dmesg | grep -E "NPU|GPU|Mali|Vivante|vip"
```

### 检查命令

```bash
# 快速健康检查
ls -l /dev/vipcore
lsmod | grep vipcore
cat /sys/class/devfreq/3600000.npu/cur_freq
cat /sys/class/thermal/thermal_zone*/temp | awk '{print $1/1000"°C"}'
```

---

## 📚 参考资源

### 官方文档

- [Radxa Cubie A7Z 主页](https://docs.radxa.com/cubie/a7z)
- [硬件规格书](https://dl.radxa.com/cubie/a7z/docs/radxa_cubie_a7z_product_brief_zh.pdf)
- [GPIO 引脚定义](https://docs.radxa.com/cubie/a7z/hardware/gpio)
- [散热设计](https://docs.radxa.com/cubie/a7z/hardware/heat-sink)
- [NPU 开发](https://docs.radxa.com/cubie/a7z/app-dev/npu-dev)
- [Ollama 开发](https://docs.radxa.com/cubie/a7z/app-dev/ollama-dev)

### SDK 和工具

- [ai-sdk 源码](https://github.com/ZIFENG278/ai-sdk)
- [ACUITY Toolkit](http://dl.allwinnertech.com/pub/NPU/)
- [VIPLite 文档](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-acuity-env)

### 社区资源

- [Radxa 论坛](https://forum.radxa.com/)
- [GitHub Issues](https://github.com/radxa)
- [全志开发者社区](http://www.aw-ol.com/)

---

## ✅ 快速检查清单

### 硬件检查

- [ ] `/dev/vipcore` 存在
- [ ] `/dev/dri/renderD128` 存在
- [ ] WiFi 可用 (wlan0)
- [ ] 蓝牙可用
- [ ] 风扇工作正常

### 软件检查

- [ ] NPU 驱动加载 (vipcore)
- [ ] GPU 驱动加载
- [ ] 内核版本: 5.15.147-7-a733
- [ ] 系统版本: Debian 11 bullseye
- [ ] Python 3 可用

### 开发环境检查

- [ ] gcc/g++ 编译器
- [ ] make 构建工具
- [ ] vpm_run 可执行
- [ ] LD_LIBRARY_PATH 设置
- [ ] NPU SDK 路径正确

---

## 📝 更新日志

- **v1.0** (2025-01-18): 初始版本，完整硬件信息提取

---

*文档生成时间: 2025-01-18*
*硬件版本: Radxa Cubie A7Z*
*内核版本: 5.15.147-7-a733*
*作者: Claude & 用户共创*
