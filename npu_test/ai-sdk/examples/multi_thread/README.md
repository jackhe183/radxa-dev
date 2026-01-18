# Android Build

```
mm
```

find in ~/out/target/product/xxx/vendor/bin/muti_thread

Burn firmare，then will be found in device /vendor/bin/muti_thread .



#  Run Demo


1. push muti_thread into device /data or sdcard dir

2. push yolov5s.nb, dog_640_640.jpg, yolact.nb, dog_550_550.jpg info device

3. run command `multi_thread yolov5.nb dog_640_640.jpg yolact.nb dog_550_550.jpg`, print result as :

```
1
1
2
1
2
1
2
1
2
1
2
1
2
......
2
1
2
2
```

