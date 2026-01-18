# Radxa Cubie A7Z NPU 完整使用手册

> 📘 **从入门到精通 - 包含所有示例和实战技巧**

---

## 📑 目录

1. [快速开始](#快速开始)
2. [NPU 工具详解](#npu-工具详解)
3. [模型示例大全](#模型示例大全)
4. [实战技巧](#实战技巧)
5. [常见问题](#常见问题)
6. [从零开发模型](#从零开发模型)

---

## 🚀 快速开始

### 环境检查（5 秒）

```bash
# 检查 NPU 设备
ls -l /dev/vipcore
# ✅ 输出: crw-rw-rw- 1 root root 199, 0 ... /dev/vipcore

# 检查驱动
lsmod | grep vipcore
# ✅ 输出: vipcore 249856 0

# 检查频率
cat /sys/class/devfreq/3600000.npu/cur_freq
# ✅ 输出: 1008000000 (1008 MHz)
```

**如果以上都通过，你的 NPU 已经就绪！** ✅

---

## 🛠️ NPU 工具详解

### 工具对照表

| 工具 | 用途 | 运行位置 | 通俗比喻 |
|------|------|----------|----------|
| **vpm_run** | 运行 NBG 模型推理 | A7Z 板子 | NPU 厨师炒菜 |
| **prepare_input.py** | 图片→.dat 数据转换 | A7Z 板子 | 食材预处理 |
| **NBinfo** | 查看 NBG 模型信息 | Windows PC | 模型身份证查看器 |
| **ACUITY** | ONNX→NBG 模型转换 | Windows PC (Docker) | 翻译官（英文→机器码） |

---

### 工具 1: vpm_run（NPU 推理工具）

#### 基本语法

```bash
vpm_run -s <配置文件.txt> -l <循环次数> [选项]
```

#### 参数详解

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `-s sample.txt` | 配置文件（必需） | - | `-s sample.txt` |
| `-l 10` | 循环次数（性能测试） | 1 | `-l 100` |
| `-d 0` | 设备索引 | 0 | `-d 0` |
| `-b 0/1` | 是否跳过后处理 | 1（跳过） | `-b 0`（显示结果） |
| `--show_top5 1` | 显示 Top5 分类结果 | 0 | `--show_top5 1` |
| `-t 5000` | 超时时间（毫秒） | 0（无限制） | `-t 5000` |
| `--save_txt 1` | 保存输出为文本 | 0 | `--save_txt 1` |

#### 配置文件格式

```ini
[network]
./模型文件.nb
[input]
./输入数据.dat
[golden]
./期望输出.dat  # 可选：用于验证
[output]
./实际输出.dat  # 可选：保存结果
```

#### 快速命令模板

```bash
# 设置库路径（永久设置：加入 ~/.bashrc）
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# 进入工作目录
cd ~/npu_test/ai-sdk/examples/vpm_run

# 快速测试（不显示结果）
./vpm_run -s sample.txt -l 1 -b 1

# 完整测试（显示 Top5）
./vpm_run -s sample.txt -l 1 -b 0 --show_top5 1

# 性能测试（循环 100 次）
./vpm_run -s sample.txt -l 100 -b 1
```

---

### 工具 2: prepare_input.py（图像预处理）

#### 作用

将 JPG/PNG 图片转换为 NPU 可读的 `.dat` 二进制格式

#### 安装依赖

```bash
pip3 install Pillow --user
```

#### 使用方法

```bash
# 基本语法
python3 prepare_input.py <输入图片> <输出文件> <宽度> <高度>

# 示例：ResNet50 (224x224)
python3 prepare_input.py dog.jpg resnet50_dog.dat 224 224

# 示例：YOLOv5 (640x640)
python3 prepare_input.py image.jpg yolov5_input.dat 640 640

# 示例：YOLACT (550x550)
python3 prepare_input.py image.jpg yolact_input.dat 550 550
```

#### 输出格式

- **格式**: CHW（通道优先）
- **数据类型**: float32
- **数值范围**: [0, 1]（归一化）
- **文件大小**: 宽 × 高 × 3 通道 × 4 字节

---

### 工具 3: NBinfo（模型信息查看器 - Windows 用）

#### 作用

查看 NBG 模型的详细信息（输入输出尺寸、量化参数等）

#### 位置

```
ai-sdk/tools/nbinfo  # x86-64 可执行文件（PC 用）
```

#### 使用方法（Windows PowerShell）

```powershell
# 查看 NBG 模型信息
.\nbinfo model.nb

# 输出示例：
# ============================================================
# Network Binary Graph Information
# ============================================================
# Network Name: resnet50
# Input  0: name=input, dim=1 3 224 224, format=INT8
# Output 0: name=output, dim=1 1000 1 1, format=INT8
# ...
```

---

## 🎯 模型示例大全

### 示例 1: LeNet 手写数字识别

**用途**: 识别 0-9 手写数字

**模型信息**:
- 输入: 28×28 灰度图
- 输出: 10 个类别概率
- 模型大小: 434 KB
- 推理速度: **126 μs** (0.126 ms) ⚡

#### 运行命令

```bash
cd ~/npu_test/ai-sdk/examples/vpm_run
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

./vpm_run -s sample_lenet.txt -l 1 --show_top5 1 -b 0
```

#### 配置文件 (`sample_lenet.txt`)

```ini
[network]
./lenet.nb
[input]
./lenet.dat
```

#### 输出示例

```
******* nb TOP5 ********
 --- Top5 ---
  0: 1.000000  ← 识别为数字 "0"，100% 置信度
  1: 0.000000
  2: 0.000000
  3: 0.000000
  4: 0.000000
```

---

### 示例 2: ResNet50 图像分类

**用途**: ImageNet 1000 类图像分类（识别猫、狗、车等）

**模型信息**:
- 输入: 224×224×3 RGB 图像
- 输出: 1000 个类别概率
- 模型大小: 17 MB
- 推理速度: **7.5 ms**

#### 运行命令

```bash
cd ~/npu_test/ai-sdk/examples/vpm_run
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

./vpm_run -s sample_resnet50.txt -l 1 --show_top5 1 -b 0
```

#### 配置文件 (`sample_resnet50.txt`)

```ini
[network]
./resnet50.nb
[input]
./resnet50_dog.dat
```

#### 预处理图片

```bash
python3 prepare_input.py dog.jpg resnet50_dog.dat 224 224
```

#### 输出示例

```
******* nb TOP5 ********
 --- Top5 ---
904: 9.205137  ← 类别 904（可能是某种狗）
556: 6.315933
 78: 5.644026
301: 5.039309
307: 4.837736
```

#### ResNet50 类别对照

常见 ImageNet 类别：
- 类别 0-999: 不同种类的动物、车辆、物品等
- 可以用 [ImageNet 类别查询工具](https://gist.github.com/yrevar/942d3a0ac0959a57c8840361ad77f3b) 查看具体名称

---

### 示例 3: YOLOv5 物体检测

**用途**: 检测图片中的多个物体（位置+类别）

**模型信息**:
- 输入: 640×640×3 RGB 图像
- 输出: 3 个检测头（不同尺度）
- 模型大小: 4.9 MB
- 推理速度: **26 ms**

#### 运行命令

```bash
cd ~/npu_test/ai-sdk/examples/vpm_run
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

./vpm_run -s sample_yolov5.txt -l 1 -b 1
```

#### 配置文件 (`sample_yolov5.txt`)

```ini
[network]
./yolov5.nb
[input]
./yolov5_dog.dat
```

#### 预处理图片

```bash
python3 prepare_input.py image.jpg yolov5_dog.dat 640 640
```

#### 输出说明

YOLOv5 输出需要后处理（非可视化）：
- 输出 1: 85×40×40（小目标检测）
- 输出 2: 85×20×20（中目标检测）
- 输出 3: 85×10×10（大目标检测）
- 每个网格 85 维 = [x, y, w, h, conf, 80 类别概率]

---

### 示例 4: YOLACT 实例分割

**用途**: 检测物体并精确分割轮廓

**模型信息**:
- 输入: 550×550×3 RGB 图像
- 输出: 检测框 + 分割掩码
- 模型大小: 25 MB
- 推理速度: **100 ms**

#### 运行命令

```bash
cd ~/npu_test/ai-sdk/examples/vpm_run
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

./vpm_run -s sample_yolact.txt -l 1 -b 1
```

#### 配置文件 (`sample_yolact.txt`)

```ini
[network]
./yolact.nb
[input]
./yolact_dog.dat
```

#### 预处理图片

```bash
python3 prepare_input.py image.jpg yolact_dog.dat 550 550
```

#### 输出说明

YOLACT 输出：
- 输出 1: 检测框信息（4×19248）
- 输出 2: 分割掩码（32×138×138）

---

## 📊 模型性能对比

| 模型 | 用途 | 输入尺寸 | 模型大小 | 推理时间 | 用途场景 |
|------|------|----------|----------|----------|----------|
| **LeNet** | 手写数字 | 28×28 | 434 KB | **0.13 ms** | 数字识别、OCR |
| **ResNet50** | 图像分类 | 224×224 | 17 MB | **7.5 ms** | 通用分类 |
| **YOLOv5** | 物体检测 | 640×640 | 4.9 MB | **26 ms** | 实时检测 |
| **YOLACT** | 实例分割 | 550×550 | 25 MB | **100 ms** | 精确分割 |

**性能测试命令**:
```bash
# 循环 100 次测试平均速度
./vpm_run -s sample.txt -l 100 -b 1
```

---

## 💡 实战技巧

### 技巧 1: 一键测试脚本

创建 `test_all.sh`：

```bash
#!/bin/bash

export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
cd ~/npu_test/ai-sdk/examples/vpm_run

echo "========================================="
echo "NPU 模型性能测试"
echo "========================================="
echo ""

echo "1️⃣ LeNet 手写数字识别"
./vpm_run -s sample_lenet.txt -l 10 -b 1 | grep "profile inference time"
echo ""

echo "2️⃣ ResNet50 图像分类"
./vpm_run -s sample_resnet50.txt -l 10 -b 1 | grep "profile inference time"
echo ""

echo "3️⃣ YOLOv5 物体检测"
./vpm_run -s sample_yolov5.txt -l 10 -b 1 | grep "profile inference time"
echo ""

echo "4️⃣ YOLACT 实例分割"
./vpm_run -s sample_yolact.txt -l 10 -b 1 | grep "profile inference time"
echo ""

echo "========================================="
echo "测试完成！"
echo "========================================="
```

使用：
```bash
chmod +x test_all.sh
./test_all.sh
```

---

### 技巧 2: 批量预处理图片

```bash
#!/bin/bash
# batch_prepare.sh

for img in *.jpg; do
    name="${img%.jpg}"
    echo "处理: $img"
    python3 prepare_input.py "$img" "${name}.dat" 224 224
done
```

---

### 技巧 3: 永久设置环境变量

```bash
# 编辑 ~/.bashrc
nano ~/.bashrc

# 添加以下行
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
alias vpm_run='/home/radxa/npu_test/ai-sdk/examples/vpm_run/vpm_run'

# 重新加载
source ~/.bashrc

# 以后可以直接用
vpm_run -s sample.txt -l 1
```

---

### 技巧 4: 查看模型信息（调试用）

```bash
# 查看模型输入输出维度
./vpm_run -s sample.txt -l 1 -b 1 2>&1 | grep -E "input|ouput"

# 输出示例：
# input 0 dim 224 224 3 1, data_format=2, quant_format=2
# ouput 0 dim 1000 1 0 0, data_format=2
```

---

## ❓ 常见问题

### Q1: 找不到库文件

**症状**:
```
error while loading shared libraries: libNBGlinker.so
```

**解决**:
```bash
# 方法 1：临时设置
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/

# 方法 2：永久设置（推荐）
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/' >> ~/.bashrc
source ~/.bashrc
```

---

### Q2: 模型文件找不到

**症状**:
```
Checking file ./model.nb failed.
```

**解决**:
```bash
# 检查模型是否存在
ls -la *.nb

# 检查配置文件路径
cat sample.txt

# 确保路径正确（相对路径或绝对路径）
```

---

### Q3: 输入数据格式错误

**症状**:
```
read input failed
```

**解决**:
```bash
# 重新生成输入数据
python3 prepare_input.py input.jpg input.dat 224 224

# 检查文件大小
ls -lh input.dat
# 应该是: 224 × 224 × 3 × 4 = 602112 字节
```

---

### Q4: 推理结果全是负数或异常

**原因**: 数据预处理方式与模型训练时不一致

**解决**:
- 检查归一化方式（是否除以 255）
- 检查通道顺序（RGB vs BGR）
- 检查图像尺寸是否正确

---

### Q5: 能不能用 PyTorch/TensorFlow 模型？

**答**: 不能直接用，需要转换！

**流程**:
```
PyTorch (.pth) → ONNX (.onnx) → NBG (.nb) → vpm_run
     训练          导出           ACUITY转换     板上推理
```

详见下一章 "从零开发模型"

---

## 🔨 从零开发模型

### 完整开发流程

```
┌────────────────────────────────────────────────────────────────┐
│  NPU 模型开发完整流程                                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Windows PC 开发                                               │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐             │
│  │ 1. 训练   │ →  │ 2. 导出   │ →  │ 3. 转换   │             │
│  │   模型    │    │   ONNX    │    │   NBG     │             │
│  │ PyTorch   │    │ torch.onnx│    │ ACUITY    │             │
│  └───────────┘    └───────────┘    └───────────┘             │
│         ↓                ↓                ↓                   │
│    .pth/.h5         .onnx            .nb (传到板子)           │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  A7Z 板子推理                                                  │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐             │
│  │ 4. 预处理 │ →  │ 5. 推理   │ →  │ 6. 后处理 │             │
│  │  图片→DAT │    │  vpm_run  │    │  解析结果 │             │
│  └───────────┘    └───────────┘    └───────────┘             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

### 步骤 1: 训练/导出模型（PC）

#### PyTorch → ONNX

```python
import torch
import torch.onnx

# 加载你的模型
model = YourModel()
model.load_state_dict(torch.load('model.pth'))
model.eval()

# 创建示例输入
dummy_input = torch.randn(1, 3, 224, 224)

# 导出为 ONNX
torch.onnx.export(
    model,
    dummy_input,
    'model.onnx',
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch_size'},
                  'output': {0: 'batch_size'}}
)

print("✅ ONNX 模型已导出！")
```

#### TensorFlow → ONNX

```python
import tensorflow as tf
import tf2onnx

# 加载模型
model = tf.keras.models.load_model('model.h5')

# 转换为 ONNX
spec = (tf.TensorSpec((None, 224, 224, 3), tf.float32, name="input"),)
output_path = 'model.onnx'

model_proto, _ = tf2onnx.convert.from_keras(
    model,
    input_signature=spec,
    output_path=output_path
)

print("✅ ONNX 模型已导出！")
```

---

### 步骤 2: 转换 ONNX → NBG（PC + Docker）

#### 安装 Docker Desktop

1. 下载：https://www.docker.com/products/docker-desktop/
2. 安装并启动 Docker Desktop

#### 获取 ACUITY 镜像

1. 访问全志网盘：http://dl.allwinnertech.com/pub/NPU/
2. 下载 `docker_images_v2.0.x.zip`
3. 解压并加载

```powershell
# PowerShell
cd C:\Downloads\docker_images_v2.0.x
tar -xf ubuntu-npu_v2.0.10.tar.zip
docker load -i ubuntu-npu_v2.0.10.tar

# 验证
docker images
# 应该看到 ubuntu-npu v2.0.10
```

#### 创建容器

```powershell
# 创建工作目录
mkdir C:\acuity_work
cd C:\acuity_work

# 创建容器
docker run --ipc=host -itd -v C:\acuity_work:/workspace --name allwinner_acuity ubuntu-npu:v2.0.10 /bin/bash

# 进入容器
docker exec -it allwinner_acuity /bin/bash
```

#### 转换模型

```bash
# 在容器内

# 1. 放置 ONNX 模型
cp /mnt/c/Users/YourName/model.onnx /workspace/

# 2. 转换（示例命令，具体参数根据模型调整）
cd /workspace/acuity_toolkit

python3 convert.py \
  --model model.onnx \
  --output model.nb \
  --input_shape "1,3,224,224" \
  --output_name "output" \
  --quantize \
  --platform a733

# 3. 复制出来
docker cp allwinner_acuity:/workspace/model.nb C:\acuity_work\
```

#### 传到板子

```powershell
# 方法 1: SCP
scp C:\acuity_work\model.nb radxa@192.168.1.xxx:/home/radxa/npu_test/

# 方法 2: U 盘
# 直接复制到 U 盘，插到板子上

# 方法 3: 网盘
# 上传到百度网盘/阿里云盘，板子上下载
```

---

### 步骤 3: 板子上运行推理

#### 预处理图片

```bash
cd ~/npu_test/ai-sdk/examples/vpm_run
python3 prepare_input.py your_image.jpg input.dat 224 224
```

#### 创建配置

```bash
cat > sample_custom.txt << 'EOF'
[network]
./model.nb
[input]
./input.dat
EOF
```

#### 运行推理

```bash
export LD_LIBRARY_PATH=/home/radxa/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
./vpm_run -s sample_custom.txt -l 1 -b 0 --show_top5 1
```

---

## 📚 附录

### A. 快速参考表

#### NPU 版本对照

| SoC | NPU 版本 | 编译参数 |
|-----|----------|----------|
| A733 | v2.0 | `AI_SDK_PLATFORM=a733 NPU_SW_VERSION=v2.0` |
| T527 | v1.13 | `AI_SDK_PLATFORM=t527 NPU_SW_VERSION=v1.13` |

#### 常用尺寸

| 模型 | 输入尺寸 | .dat 文件大小 |
|------|----------|---------------|
| LeNet | 28×28×1 | 784 bytes |
| ResNet50 | 224×224×3 | 602,112 bytes |
| YOLOv5 | 640×640×3 | 4,915,200 bytes |
| YOLACT | 550×550×3 | 3,630,000 bytes |

---

### B. 文件格式对照

| 扩展名 | 格式 | 用途 |
|--------|------|------|
| `.pth` | PyTorch 模型 | 训练导出 |
| `.h5` | Keras 模型 | 训练导出 |
| `.onnx` | ONNX 格式 | 中间格式 |
| `.nb` / `.nbg` | NBG 格式 | NPU 可执行 |
| `.dat` | 二进制数据 | 输入数据 |
| `.tensor` | Tensor 文件 | 输入数据（ACUITY 格式） |

---

### C. 有用的链接

**官方文档**:
- [ACUITY 环境配置](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-acuity-env)
- [vpm_run 使用说明](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-vpm-run)
- [YOLOv5 示例](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie_yolov5)
- [ResNet50 示例](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie_resnet50)

**资源下载**:
- 全志 NPU SDK: http://dl.allwinnertech.com/pub/NPU/
- ai-sdk 源码: https://github.com/ZIFENG278/ai-sdk

---

## ✅ 检查清单

### 板子上准备

- [ ] `/dev/vipcore` 存在
- [ ] `vipcore` 模块已加载
- [ ] 编译了 `vpm_run`
- [ ] 设置了 `LD_LIBRARY_PATH`
- [ ] 安装了 Pillow (`pip3 install Pillow --user`)

### 模型准备

- [ ] 有 `.nb` 模型文件
- [ ] 有预处理后的 `.dat` 输入文件
- [ ] 创建了 `.txt` 配置文件

### 运行推理

- [ ] 导出库路径
- [ ] 检查配置文件格式
- [ ] 运行 `vpm_run`
- [ ] 查看输出结果

---

**最后提醒**:
- **A7Z = Allwinner A733 = VIPLite = .nb** ✅
- **Rock 5B = RK3588 = RKNN = .rknn** ❌
- **千万别搞混！**

---

*文档版本: v2.0*
*最后更新: 2025-01-18*
*作者: Claude & 用户共创*
