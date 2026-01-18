#!/bin/sh

multi_thread \
    /vendor/etc/models/yolov5.nb /vendor/etc/input_data/dog_640_640.jpg \
    /vendor/etc/models/yolact.nb /vendor/etc/input_data/dog_550_550.jpg
