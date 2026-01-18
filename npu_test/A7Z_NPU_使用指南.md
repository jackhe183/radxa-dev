# Radxa Cubie A7Z NPU 使用指南

> 📖 **写给开发小白的通俗教程**

---

## 🎯 通俗理解：什么是 NPU？

想象一下：

| 场景 | 比喻 |
|------|------|
| **CPU** | 像一个**大学教授**，什么题都会算，但算得慢 |
| **GPU** | 像一个**小学生军团**，人多力量大，适合简单重复计算 |
| **NPU** | 像一个**数学天才神童**，专门做矩阵乘法和神经网络推理，快得离谱！ |

**A7Z 的 NPU 规格：**
- 算力：3 TOPS（每秒 3 万亿次运算）
- 像一个专门做 AI 识别的"超级大脑"
- 用来跑：人脸识别、物体检测、语音识别等 AI 任务

---

## 📚 整体流程通俗比喻

```
┌─────────────────────────────────────────────────────────────┐
│  NPU 开发完整流程（像做菜一样）                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Windows PC 上做模型转换（像买菜切菜）                        │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ 训练好的 │  →   │ ACUITY   │  →   │ NBG模型  │          │
│  │  模型    │      │ 转换工具  │      │ (NPU可读)│          │
│  │ .onnx    │      │ Docker   │      │          │          │
│  │ .tflite  │      │ 容器     │      │          │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│         ↓                                      ↓            │
│  Python/PyTorch                      二进制食谱(NBG格式)    │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  A7Z 板子上推理（像用电磁炉炒菜）                             │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ NBG模型  │  →   │ vpm_run  │  →   │ 识别结果  │          │
│  │ + 输入   │      │ 运行工具  │      │ (置信度)  │          │
│  │ 数据     │      │          │      │          │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│         ↓                  ↓                   ↓            │
│  准备好的食材         NPU厨师做菜          这是什么菜？      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 第一部分：A7Z 板子上跑 NPU 推理

### 前提条件检查

```bash
# 1️⃣ 检查 NPU 设备是否存在（像检查厨房有没有炉子）
ls -l /dev/vipcore
# 应该看到：crw-rw-rw- 1 root root 199, 0 ... /dev/vipcore

# 2️⃣ 检查 NPU 驱动是否加载（像检查炉子通没通气）
lsmod | grep vipcore
# 应该看到：vipcore 249856 0

# 3️⃣ 检查 NPU 频率（像检查炉子火力）
cat /sys/class/devfreq/3600000.npu/cur_freq
# 应该看到类似：1008000000 (1008MHz，满火力！)
```

### 步骤 1：获取 ai-sdk 源码

```bash
# 进入工作目录
cd ~
mkdir -p npu_test
cd npu_test

# 下载 ai-sdk（如果已经有了就跳过）
# 假设你已经上传了 ai-sdk 文件夹
```

**目录结构：**
```
~/npu_test/ai-sdk/
├── examples/
│   ├── vpm_run/          # 👈 我们要编译的工具
│   ├── resnet50/         # ResNet50 图像分类示例
│   ├── lenet/            # LeNet 手写数字识别示例
│   └── ...
├── viplite-tina/         # NPU 驱动库
├── models/               # 模型文件
└── machinfo/             # 平台配置
```

### 步骤 2：编译 vpm_run 工具

**💡 通俗理解：** 这就像把"菜谱翻译器"从英文翻译成中文，让板子能看懂怎么用 NPU。

```bash
# 进入 vpm_run 源码目录
cd ~/npu_test/ai-sdk/examples/vpm_run

# 清理旧文件（如果有）
make clean

# 编译！（重要：指定 A733 平台和 v2.0 版本）
make AI_SDK_PLATFORM=a733 NPU_SW_VERSION=v2.0

# 检查是否成功
ls -lh vpm_run
# 应该看到约 80KB 的可执行文件
```

**⚠️ 易错点：**
| 错误 | 原因 | 解决方法 |
|------|------|----------|
| `gcc: command not found` | 没装编译工具 | `sudo apt install build-essential` |
| `g++: command not found` | 示例需要 C++ 编译器 | `sudo apt install g++`（但 vpm_run 用 gcc 就行）|
| 找不到 `-lNBGlinker` | 库路径不对 | 必须用 `AI_SDK_PLATFORM=a733` |

### 步骤 3：准备测试文件

```bash
# 进入工作目录
cd ~/npu_test/ai-sdk/examples/vpm_run

# 复制模型文件（像准备食材）
cp ../../examples/lenet/model/v3/lenet.nb .
cp ../../examples/lenet/input_data/lenet.dat .

# 检查文件
ls -lh lenet.*
# 应该看到：
# lenet.nb  - 模型文件（约 434KB）
# lenet.dat - 输入数据（784 字节）
```

### 步骤 4：创建配置文件

**💡 配置文件就像"点菜单"：** 告诉 NPU 厨师用什么食材，做哪道菜。

```bash
# 创建配置文件
cat > sample_lenet.txt << 'EOF'
[network]
./lenet.nb
[input]
./lenet.dat
EOF
```

**配置文件格式解释：**
```
[network]     ← 菜名（用哪个模型）
./lenet.nb

[input]       ← 食材（输入数据）
./lenet.dat
```

### 步骤 5：运行推理！🚀

```bash
# 设置库路径（像告诉厨师工具在哪儿）
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# 运行推理！
./vpm_run -s sample_lenet.txt -l 1 --show_top5 1 -b 0
```

**参数解释（通俗易懂）：**
| 参数 | 比喻 | 说明 |
|------|------|------|
| `-s sample_lenet.txt` | 点菜单 | 指定配置文件 |
| `-l 1` | 做 1 份 | 推理 1 次 |
| `--show_top5 1` | 要排行榜 | 显示前 5 个可能的结果 |
| `-b 0` | 不要省略步骤 | 完整输出，不跳过后处理 |

**成功输出示例：**
```
init vip lite, driver version=0x00020003...     ← 炉子启动成功！
VIPLite driver software version 2.0.3.2-AW-2024-08-30
vip lite init OK.

create network 0: 1245 us.                       ← 准备工作完成
input 0 dim 28 28 1 1, data_format=2             ← 输入是 28×28 的图片

run time for this network 0: 415 us.             ← 炒菜只要 0.4 毫秒！
profile inference time=126us, cycle=64152        ← 真正推理只要 126 微秒！

******* nb TOP5 ********                        ← 排行榜来了
 --- Top5 ---
  0: 1.000000                                   ← 识别为数字 "0"，100% 确定！
  1: 0.000000
  2: 0.000000
  ...
```

---

## 🐛 常见踩坑点与解决

### 坑 1：找不到模型文件

**症状：**
```
Checking file ./lenet.nb failed.
Network binary file ./lenet.nb can't be found.
```

**原因：** 配置文件里的路径不对（像菜谱写错了菜名）

**解决：**
```bash
# 检查文件是否在当前目录
ls -la lenet.nb

# 如果不在，复制过来
cp ../../examples/lenet/model/v3/lenet.nb .
```

---

### 坑 2：库文件找不到

**症状：**
```
error while loading shared libraries: libNBGlinker.so: cannot open shared object file
```

**原因：** 忘记设置 `LD_LIBRARY_PATH`（像厨师找不到锅铲）

**解决：**
```bash
# 临时设置（每次重启终端都要重新设）
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# 永久设置（写入 ~/.bashrc）
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/' >> ~/.bashrc
source ~/.bashrc
```

---

### 坑 3：版本不匹配（A733 vs T527）

**症状：**
```
create network failed.
NPU version mismatch
```

**原因：** 用错了库版本（像给 iPhone 充电用了 Android 的数据线）

**平台对照表：**
| 板型 | SoC | NPU 版本 | 编译命令 |
|------|-----|----------|----------|
| Cubie A7Z | A733 | v2.0 | `make AI_SDK_PLATFORM=a733 NPU_SW_VERSION=v2.0` |
| 其他 T527 板子 | T527 | v1.13 | `make AI_SDK_PLATFORM=t527 NPU_SW_VERSION=v1.13` |

---

### 坑 4：RKNN vs VIPLite 混淆（新手最容易犯！）

**❌ 错误认知：** "看到 Radxa 就装 RKNN"
**✅ 正确理解：**

| 项目 | Rockchip (RK3588) | Allwinner (A733) |
|------|-------------------|------------------|
| 芯片厂商 | 瑞芯微 Rockchip | 全志 Allwinner |
| 代表板子 | Rock 5B | Cubie A7Z |
| NPU 厂商 | Rockchip 自研 | VeriSilicon (Vivante) |
| 模型格式 | `.rknn` | `.nb` / `.nbg` |
| 运行工具 | `rknn_server` | `vpm_run` |
| SDK | RKNN-Toolkit2 | VIPLite / ACUITY |

**⚠️ 千万别在 A7Z 上装 RKNN！** 就像给柴油车加了汽油，会坏掉的！

---

## 🪟 第二部分：Windows PC 上模型转换（ACUITY Toolkit）

### 通俗理解流程

```
你的模型                    转换工具                    NPU能用的模型
┌──────────┐              ┌──────────┐              ┌──────────┐
│ PyTorch  │              │  ACUITY  │              │   .nb    │
│   模型    │    →         │ Docker   │     →        │  NBG格式  │
│ .pth     │              │ 容器里   │              │          │
│          │              │ 转换     │              │          │
└──────────┘              └──────────┘              └──────────┘
   ↓                                                           ↓
像一本         像一个翻译官                像一本二进制菜谱
英文菜谱       把英文翻译成机器码              只有厨师能看懂
```

---

### 步骤 1：安装 Docker（在 Windows 上）

**💡 Docker 是什么？** 像一个"虚拟厨房"，在里面装各种工具不会弄乱你的 Windows。

1. **下载 Docker Desktop**
   - 访问：https://www.docker.com/products/docker-desktop/
   - 下载 Windows 版本
   - 安装（一路 Next 即可）

2. **启动 Docker**
   - 桌面会出现 Docker 图标
   - 右键 → 启动 Docker Desktop
   - 等待左下角显示 "Docker Desktop is running"

---

### 步骤 2：获取 ACUITY Docker 镜像

**💡 镜像是什么？** 像一个打包好的"厨房集装箱"，里面什么工具都有。

**下载 ACUITY：**
1. 访问全志网盘（需要注册账号）
   - 网址：http://dl.allwinnertech.com/pub/NPU/
   - 找到：`docker_images_v2.0.x.zip`
   - 下载（约 4GB，需要时间）

2. 解压并加载镜像
```powershell
# 在 PowerShell 或 CMD 中运行

# 进入解压后的目录
cd C:\Users\你的用户名\Downloads\docker_images_v2.0.x

# 解压镜像文件
tar -xf ubuntu-npu_v2.0.10.tar.zip

# 加载到 Docker
docker load -i ubuntu-npu_v2.0.10.tar

# 验证加载成功
docker images
# 应该看到：ubuntu-npu  v2.0.10
```

---

### 步骤 3：创建 Docker 容器

```powershell
# 创建工作目录
mkdir C:\acuity_work
cd C:\acuity_work

# 创建并启动容器
docker run --ipc=host -itd -v C:\acuity_work:/workspace --name allwinner_v2.0.10 ubuntu-npu:v2.0.10 /bin/bash

# 查看容器是否运行
docker ps -a
```

**参数解释：**
| 参数 | 比喻 | 说明 |
|------|------|------|
| `-v C:\acuity_work:/workspace` | 开个窗户 | 让 Windows 文件夹和 Docker 容器能互相传递东西 |
| `--name allwinner_v2.0.10` | 给厨房起名 | 方便以后找到这个容器 |
| `-itd` | 后台运行 | 厨台一直开着，随时能用 |

---

### 步骤 4：进入容器并转换模型

```powershell
# 进入容器（像走进厨房）
docker exec -it allwinner_v2.0.10 /bin/bash

# 现在你在 Linux 环境里了！
root@xxxx:/workspace#
```

**容器里的目录结构：**
```
/workspace/                    ← 你的工作目录（对应 Windows 的 C:\acuity_work）
  ├─ models/                   ← 放你的原始模型
  ├─ converted/                ← 转换后的 .nb 模型
  └─ acuity_toolkit/           ← ACUITY 工具链
```

---

### 步骤 5：转换模型（示例：PyTorch → NBG）

```bash
# 在容器里运行

# 1. 准备你的模型（假设有一个 PyTorch 模型）
cd /workspace/models
# 把你的 model.pth 放在这里（从 Windows 复制到 C:\acuity_work\models）

# 2. 导出为 ONNX（先用 Python 转换）
python3 << 'EOF'
import torch
import torch.onnx

# 加载你的模型
model = YourModelClass()
model.load_state_dict(torch.load('model.pth'))
model.eval()

# 导出为 ONNX
dummy_input = torch.randn(1, 3, 224, 224)  # 根据你的模型调整
torch.onnx.export(model,
                  dummy_input,
                  'model.onnx',
                  input_names=['input'],
                  output_names=['output'],
                  dynamic_axes={'input': {0: 'batch_size'},
                               'output': {0: 'batch_size'}})
print("ONNX 模型已生成！")
EOF

# 3. 使用 ACUITY 转换为 NBG
cd /workspace/acuity_toolkit
python3 convert.py \
  --model ../models/model.onnx \
  --output ../converted/model.nb \
  --input_shape "1,3,224,224" \
  --output_name "output" \
  --quantize \
  --platform a733

# 等待转换完成...
# 成功后会生成：/workspace/converted/model.nb
```

---

### 步骤 6：把模型传到 A7Z 板子

```bash
# 在 Windows 上
# 打开 PowerShell 或 CMD

# 从 Docker 容器复制出来
docker cp allwinner_v2.0.10:/workspace/converted/model.nb C:\acuity_work\model.nb

# 传到 A7Z 板子（用 SCP）
scp C:\acuity_work\model.nb radxa@192.168.1.xxx:/home/radxa/npu_test/

# 或者用 U 盘、网盘等方式
```

---

## 📋 完整工作流总结

### 场景 1：只想快速验证 NPU 能不能用

```bash
# 在 A7Z 板子上
cd ~/npu_test/ai-sdk/examples/vpm_run
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
./vpm_run -s sample_lenet.txt -l 1 --show_top5 1 -b 0

# 看到输出结果 → NPU 正常！✅
```

---

### 场景 2：用自己的模型跑推理

```
Windows PC                      A7Z 板子
──────────                      ──────────
1. 训练/下载 PyTorch 模型
   ↓
2. 导出为 ONNX 格式
   ↓
3. ACUITY 转换 → .nb 文件
   ↓
4. 传到板子 (SCP/U盘)
                                  ↓
5. 编写配置文件 sample.txt
                                  ↓
6. 运行 vpm_run 推理
                                  ↓
7. 得到结果！🎉
```

---

## 🎓 实用技巧汇总

### 技巧 1：创建快捷命令（别名）

```bash
# 编辑 ~/.bashrc
nano ~/.bashrc

# 添加以下内容
alias vpm='export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/ && ~/npu_test/ai-sdk/examples/vpm_run/vpm_run'

# 保存后重新加载
source ~/.bashrc

# 以后直接用
vpm -s sample.txt -l 1 --show_top5 1 -b 0
```

---

### 技巧 2：批量测试

```bash
# 创建测试脚本
cat > test_all_models.sh << 'EOF'
#!/bin/bash

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
VPM_RUN=~/npu_test/ai-sdk/examples/vpm_run/vpm_run

echo "测试所有模型..."
echo "===================="

# LeNet
echo "1. LeNet 手写数字识别"
$VPM_RUN -s sample_lenet.txt -l 10 -b 1
echo ""

# 其他模型...
EOF

chmod +x test_all_models.sh
./test_all_models.sh
```

---

### 技巧 3：性能对比（NPU vs CPU）

```bash
# NPU 推理
time ./vpm_run -s sample.txt -l 100 -b 1
# 记录时间

# CPU 推理（用 Python）
time python3 cpu_inference.py
# 对比时间差
```

---

## 📚 常用文件格式对照

| 扩展名 | 格式 | 用途 | 谁生成 |
|--------|------|------|--------|
| `.pth` | PyTorch 模型 | 训练好的模型 | PyTorch |
| `.onnx` | ONNX 格式 | 中间格式 | torch.onnx.export() |
| `.tflite` | TensorFlow Lite | Google 格式 | TensorFlow |
| `.nb` / `.nbg` | NBG 格式 | NPU 可执行 | ACUITY 转换 |
| `.dat` | 二进制数据 | 输入数据 | ACUITY inference |
| `.tensor` | Tensor 文件 | 输入数据 | ACUITY IDE |

---

## 🔗 参考资源

### 官方文档
- [ACUITY Toolkit 环境配置](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-acuity-env)
- [vpm_run 使用说明](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-vpm-run)
- [NPU 开发指南](https://docs.radxa.com/cubie/a7z/app-dev/npu-dev)

### 下载链接
- 全志 NPU SDK：http://dl.allwinnertech.com/pub/NPU/
- ai-sdk 源码：https://github.com/ZIFENG278/ai-sdk

---

## ✅ 检查清单

使用 NPU 前检查：
- [ ] `/dev/vipcore` 存在？
- [ ] `vipcore` 模块已加载？
- [ ] 编译了 `vpm_run`？
- [ ] 设置了 `LD_LIBRARY_PATH`？
- [ ] 准备了 `.nb` 模型文件？
- [ ] 准备了输入数据（`.dat` 或 `.tensor`）？
- [ ] 创建了配置文件（`.txt`）？

全部打勾 → 开始推理！🚀

---

**最后提醒：**
- **A7Z = Allwinner A733 = VeriSilicon NPU = VIPLite = .nb 模型**
- **Rock 5B = RK3588 = Rockchip NPU = RKNN = .rknn 模型**
- **千万别搞混！** 就像柴油车和汽油车，加错油会出问题！

---

*作者：Claude & 用户共创*
*日期：2025-01-18*
*版本：v1.0*
