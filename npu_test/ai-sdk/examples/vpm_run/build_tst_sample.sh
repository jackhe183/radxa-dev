#!/bin/bash

########################################################
# establish build environment and build options value
# Please modify the following items according your build environment

BUILD_BOARD=$1
shift
DEFAULT_BOARD=longan

#save output tensor
export SAVE_OUTPUT_TXT_FILE=1

#use ./build_drv.sh install or clean to build command driver
if [ "$BUILD_BOARD" = "clean" ]; then
    shift $#
    set -- ${BUILD_BOARD}
    BUILD_BOARD=$DEFAULT_BOARD
elif [ "$BUILD_BOARD" = "install" ]; then
    shift $#
    set -- ${BUILD_BOARD}
    BUILD_BOARD=$DEFAULT_BOARD
fi

if [ -z $BUILD_BOARD ]; then
    BUILD_BOARD=$DEFAULT_BOARD
fi


echo "build board target: $BUILD_BOARD"


case "$BUILD_BOARD" in
longan)
    export ARCH_TYPE=arm64
    export CPU_TYPE=cortex-a53
    export CPU_ARCH=armv8-a
    export LONGAN_DIR=/home/xxx/longan
    export KERNEL_DIR=$LONGAN_DIR/kernel/linux-5.15/
    export TOOLCHAIN=$LONGAN_DIR/out/gcc-linaro-5.1-2015.08-x86_64_aarch64-linux-gnu
    export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-gnu-
    export LIB_DIR=$TOOLCHAIN/aarch64-linux-gnu/lib
    export USE_LINUX_PLATFORM_DEVICE=1
    export PLATFORM_CONFIG=allwinner
    export AUTO_CORRECT_CONFLICTS=1
;;
tinav85x)
    export ARCH_TYPE=arm
    export CPU_TYPE=cortex-a7
    export CPU_ARCH=armv7-a
    export FIXED_ARCH_TYPE=arm-linux-gnueabi
    export TOOLCHAIN=/home/xxx/tina-v85x/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/
    export CROSS_COMPILE=/home/xxx/tina-v85x/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin/arm-openwrt-linux-muslgnueabi-
    export LIB_DIR=$TOOLCHAIN/arm-openwrt-linux-muslgnueabi/lib
    export USE_LINUX_PLATFORM_DEVICE=1
    export USE_LINUX_RESERVE_MEM=0
    export PLATFORM_CONFIG=allwinner
;;


*)
   echo "ERROR: Unknown $BUILD_BOARD, or not support so far"
   exit 1
;;

esac;


########################################################
# set special build options valule
# You can modify the build options for different results according your requirement
#
#    option                    value   description                          default value
#    -------------------------------------------------------------------------------------
#    DEBUG                      1      Enable debugging.                               0
#                               0      Disable debugging.
#
#    ABI                        0      Change application binary interface, default    0
#                                      is 0 which means no setting
#                                      aapcs-linux For example, build driver for Aspenite board
#
#    LINUX_OABI                 1      Enable this if build environment is ARM OABI.   0
#                               0      Normally disable it for ARM EABI or other machines.
#
#    FPGA_BUILD                 1      To fix a pecical issue on FPGA board;           0
#                               0      build driver for real chip;
#

BUILD_OPTION_DEBUG=0
BUILD_OPTION_ABI=0
BUILD_OPTION_LINUX_OABI=0
BUILD_OPTION_gcdSTATIC_LINK=0
BUILD_OPTION_FPGA_BUILD=0

BUILD_OPTIONS="$BUILD_OPTIONS ABI=$BUILD_OPTION_ABI"
BUILD_OPTIONS="$BUILD_OPTIONS LINUX_OABI=$BUILD_OPTION_LINUX_OABI"
BUILD_OPTIONS="$BUILD_OPTIONS DEBUG=$BUILD_OPTION_DEBUG"
BUILD_OPTIONS="$BUILD_OPTIONS FPGA_BUILD=$BUILD_OPTION_FPGA_BUILD"

export PATH=$TOOLCHAIN/bin:$PATH

########################################################
# clean/build driver and samples
# build results will save to $SDK_DIR/
#
#cd $VIPLITE_ROOT; make -j1 -f makefile.linux $BUILD_OPTIONS clean
make -f makefile.linux $BUILD_OPTIONS $@ 2>&1
if [ $? -ne 0 ]
then
    echo "fail to build ..."
    exit 1
else
    echo "build successfully..."
fi


