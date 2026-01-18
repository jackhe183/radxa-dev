

import numpy as np
import cv2

file_path = "./lenet.dat"
# 读取原始数据
data = np.fromfile(file_path, dtype=np.uint8)
print(len(data))
# data = (data * 255).astype(np.uint8)
print(data)
# print("数据前10个值:", data[:10])
# print("数据长度:", len(data))

# # 如果数据是归一化的 (0~1)，先还原到 0~255
# if data.max() <= 1.0:
#     data = (data * 255).astype(np.uint8)
# else:
#     data = data.astype(np.uint8)

# # 假设 28x28
img = data.reshape(28,28)

cv2.imwrite("a.jpg", img)
