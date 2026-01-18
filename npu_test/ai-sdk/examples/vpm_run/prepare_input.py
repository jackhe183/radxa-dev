#!/usr/bin/env python3
"""
图像预处理脚本 - 将 JPG 转换为 NPU 可用的 .dat 格式
无依赖版本（不需要 numpy）
"""

import sys
import struct
from PIL import Image

def preprocess_image(image_path, output_path, target_size=(224, 224),
                     normalize=True):
    """
    预处理图像并保存为 .dat 格式
    """
    # 1. 读取图片
    img = Image.open(image_path)
    img = img.convert('RGB')

    # 2. 调整大小
    img = img.resize(target_size, Image.BILINEAR)

    # 3. 转换为 numpy 数组 (HWC -> CHW)
    pixels = img.load()
    width, height = img.size

    # 创建 CHW 格式的数据
    data = []
    for c in range(3):  # 通道
        for h in range(height):  # 高度
            for w in range(width):  # 宽度
                r, g, b = pixels[w, h]
                if c == 0:
                    val = r
                elif c == 1:
                    val = g
                else:
                    val = b

                if normalize:
                    data.append(struct.pack('f', val / 255.0))
                else:
                    data.append(struct.pack('B', val))

    # 4. 保存为二进制文件
    with open(output_path, 'wb') as f:
        for d in data:
            f.write(d)

    print(f"✅ 预处理完成!")
    print(f"   输入: {image_path}")
    print(f"   输出: {output_path}")
    print(f"   尺寸: {width}x{height}")
    print(f"   格式: CHW, {'float32 [0,1]' if normalize else 'uint8 [0,255]'}")
    print(f"   文件大小: {len(data) * (4 if normalize else 1)} bytes")

def main():
    if len(sys.argv) < 3:
        print("使用方法:")
        print("  python3 prepare_input.py <input.jpg> <output.dat> [width] [height]")
        print("")
        print("示例:")
        print("  python3 prepare_input.py dog.jpg dog.dat 224 224")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 224
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 224

    preprocess_image(input_path, output_path, (width, height), normalize=True)

if __name__ == '__main__':
    main()
