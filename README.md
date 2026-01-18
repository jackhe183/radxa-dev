# 🚀 Radxa Cubie A7Z (A733) NPU 开发实战指南

> **"拒绝 RKNN，拥抱 VIPLite！"**
> 本项目记录了在 Radxa Cubie A7Z (全志 A733) 开发板上启用 NPU、编译工具链及运行 AI 推理的完整流程。

![Platform](https://img.shields.io/badge/Platform-Radxa_Cubie_A7Z-green)
![SoC](https://img.shields.io/badge/SoC-Allwinner_A733-blue)
![NPU](https://img.shields.io/badge/NPU-VeriSilicon_VIPLite-orange)
![Status](https://img.shields.io/badge/Status-Verified-success)

## 📖 项目简介

很多开发者容易将 Radxa 的板子误认为都使用瑞芯微 (Rockchip) 方案，从而错误地尝试安装 RKNN。
**Cubie A7Z 不同！** 它基于全志 A733 芯片，使用芯原 (VeriSilicon) 的 NPU IP。

本项目提供了从 **环境配置** -> **工具编译** -> **模型转换** -> **上板推理** 的保姆级路径。

## ⚡ 硬件规格

- **开发板**: Radxa Cubie A7Z
- **核心 (SoC)**: Allwinner A733 (双核 A76 + 六核 A55)
- **NPU**: VeriSilicon VIPLite (算力 3 TOPS)
- **驱动节点**: `/dev/vipcore` (注意：不是 `/dev/galcore` 或 `/dev/rknpu`)

---

## 🛠️ 快速开始 (板端环境)

### 1. 确认 NPU 存活
在板子终端执行以下命令，确保驱动已加载：
```bash
ls -l /dev/vipcore
# 输出应为：crw-rw-rw- 1 root root ...
```

### 2. 获取 SDK 并编译运行工具 (`vpm_run`)
官方提供的下载链接常失效，推荐**板端本地编译**，最为稳妥。

```bash
# 1. 拉取官方 AI SDK
git clone https://github.com/ZIFENG278/ai-sdk.git
# 或 git clone https://github.com/radxa-edge/ai-sdk.git

# 2. 进入源码目录
cd ai-sdk/examples/vpm_run

# 3. 编译 (关键步骤！指定 A733 平台)
make AI_SDK_PLATFORM=a733 NPU_SW_VERSION=v2.0

# 4. 验证编译结果
ls -l vpm_run
# 应看到绿色的可执行文件
```

### 3. 配置环境变量
为了让工具能找到 NPU 驱动库，**必须**执行：
```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/npu_test/ai-sdk/viplite-tina/lib/aarch64-none-linux-gnu/v2.0/
# 建议将此行加入 ~/.bashrc 实现永久生效
```

---

## 🏃‍♂️ 运行 Hello World (LeNet)

验证 NPU 是否工作的最快方法是运行自带的手写数字识别 Demo。

### 1. 准备文件
```bash
# 假设你在 ai-sdk/examples/vpm_run 目录下
cp ../../lenet/model/v3/lenet.nb .       # 复制模型
cp ../../lenet/input_data/lenet.dat .    # 复制输入数据
```

### 2. 创建配置文件 (`sample.txt`)
`vpm_run` 需要通过配置文件指定模型和输入：
```bash
cat > sample_lenet.txt <<EOF
[network]
./lenet.nb
[input]
./lenet.dat
EOF
```

### 3. 执行推理
```bash
./vpm_run -s sample_lenet.txt -l 1 --show_top5 1 -b 0
```

### 4. 预期输出
```text
init vip lite, driver version=...
vip lite init OK.
...
run time for this network 0: 222 us.   <-- 超快！
profile inference time=77us
******* nb TOP5 ********
 --- Top5 ---
  0: 1.000000    <-- 识别成功！
```

---

## 💻 模型转换 (PC 端)

要在板子上跑自己的模型 (YOLO, ResNet 等)，需要在 Windows/Linux PC 上使用 **Acuity Toolkit** 将 `.onnx` 转换为 `.nb` 文件。

### 推荐工作流 (Windows + Docker)

1.  **准备环境**：安装 Docker Desktop。
2.  **获取镜像**：下载全志 NPU 开发镜像 (通常约 7GB)。
    *   *注：由于镜像较大且私有，通常需要从 Radxa 官网下载离线 `.tar` 包并使用 `docker load` 导入。*
3.  **启动容器**：
    ```powershell
    docker run -it -v D:\MyModels:/workspace radxa/acuity-toolkit /bin/bash
    ```
4.  **转换模型**：在容器内使用 `pegasus` 或 `convert_tool` 进行转换 (参考官方文档)。

---

## ⚠️ 常见坑点 (Troubleshooting)

| 问题现象 | 原因分析 | 解决方案 |
| :--- | :--- | :--- |
| **`vpm_run: Is a directory`** | 你把源码文件夹当成程序运行了 | 进入该目录，执行 `make ...` 编译出可执行文件。 |
| **`wget 404 Not Found`** | 官方预编译包链接失效 | 使用源码编译（参考本文“快速开始”部分）。 |
| **`error while loading shared libraries`** | 找不到 `libNBGlinker.so` | 检查 `LD_LIBRARY_PATH` 是否配置正确。 |
| **想装 `python3-rknnlite2`** | **方向错了！** | 这是全志芯片，不是瑞芯微。千万别装 RKNN。 |
| **Docker 拉取镜像失败** | 镜像库私有或需登录 | 下载离线 SDK 包，使用 `docker load -i` 导入。 |

## 🔗 参考资料

*   [Radxa Cubie A7Z 官方文档](https://docs.radxa.com/cubie/a7z)
*   [AI-SDK 仓库](https://github.com/radxa-edge/ai-sdk)
