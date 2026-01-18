# Android Build

```
mm
```

find in ~/out/target/product/xxx/vendor/bin/resnet50

Burn firmare，then will be found in device /vendor/bin/resnet50.



#  Run Demo


1. push resnet into device  /data or sdcard dir

2. push resnet50.nb, dog_224_224.jpg info device

3. run command `resnet resnet50.nb dog_224_224.jpg`, print result as,

```
========== top5 ==========
class id: 231, prob: 15.432617, label: collie
class id: 230, prob: 13.103271, label: Shetland sheepdog, Shetland sheep dog, Shetland
class id: 169, prob: 12.617920, label: borzoi, Russian wolfhound
class id: 224, prob: 12.423828, label: groenendael
class id: 160, prob: 10.191406, label: Afghan hound, Afghan
```

