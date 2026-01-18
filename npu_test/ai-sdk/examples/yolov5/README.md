# Android Build

```
mm
```

find in ~/out/target/product/xxx/vendor/bin/yolov5

Burn firmare，then will be found in device /vendor/bin/yolov5.

# Linux Build

After compiling the entire SDK, it can be compiled separately.

For MR527、AI985、MR536：

```shell
#compile the entire SDK
make menuconfig
Allwinner ‑‑‑>
Vision ‑‑‑>
<*> ai‑sdk‑viplite........................... allwinner npu viplite framework ‑‑‑>

make -j32

#compile this demo
mm -B
```

find in ~/out/xxx/xxx/openwrt/build_dir/target/ai-sdk/ipkg-xxx/ai-sdk-viplite/etc/npu/yolov5

Burn firmare，then will be found in device /etc/npu/yolov5.

For V85x、R853：

```shell
#compile the entire SDK
make menuconfig
Allwinner ‑‑‑>
ai‑sdk selection ‑‑‑>
<*> yolov5....................................................... yolov5 demo

make -j32

#compile this demo
mm -B
```

find in ~/sdk_dir/out/xxx/compile_dir/target/ai‑sdk/yolov5



# Run Demo


1. push yolov5 into device /data or sdcard dir

2. push yolov5.nb, dog_640_640.jpg into device

3. run command `yolov5 yolov5.nb dog_640_640.jpg`, print result as,

```
detection num: 3
16:  83%, [ 113,  249,  254,  594], dog
 7:  81%, [ 390,   86,  575,  194], truck
 1:  50%, [  88,  146,  462,  468], bicycle
```

4. view result.png in device path
