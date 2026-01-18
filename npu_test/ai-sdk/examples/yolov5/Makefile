TARGET = yolov5

ifdef AI_SDK_PLATFORM
include ../../machinfo/$(AI_SDK_PLATFORM)/config.mk
endif

INCLUDE += -I$(INSTALL_PREFIX)/usr/include -I$(STAGING_DIR)/usr/include/opencv4 -I../libawnn_viplite -I../libawutils -I../../
LIBS    += -L $(INSTALL_PREFIX)/usr/lib -Wl,-rpath-link,$(INSTALL_PREFIX)/usr/lib -lopencv_core -lopencv_imgcodecs -lopencv_imgproc -ljpeg
SRCS    += main.c yolov5_post_process.cpp yolov5_pre_process.cpp ../libawnn_viplite/awnn_lib.c ../libawnn_viplite/awnn_quantize.c ../libawutils/image_utils.c

CFLAGS += -g -O0 -DDEBUG -D_DEBUG

ifeq ($(SAVE_OUTPUT_TXT_FILE),1)
  CFLAGS += -DSAVE_OUTPUT_TXT_FILE
endif

ifeq ("$(NPU_SW_VERSION)", "v2.0")
  INCLUDE += -I../../viplite-tina/lib/aarch64-none-linux-gnu/v2.0/inc
  LIBS_VIP += -L../../viplite-tina/lib/aarch64-none-linux-gnu/v2.0/ -lNBGlinker -lVIPhal
  MYCFLAGS += -DNPU_SW_VERSION=2
else
  INCLUDE += -I../../viplite-tina/lib/aarch64-none-linux-gnu/v1.13/inc
  LIBS_VIP += -L../../viplite-tina/lib/aarch64-none-linux-gnu/v1.13/ -lVIPlite -lVIPuser
  MYCFLAGS += -DNPU_SW_VERSION=1
endif


$(TARGET): $(SRCS)
	$(CXX) $(CFLAGS) -g -o $@ $^ $(INCLUDE) $(LIBS) $(LIBS_VIP) -lm

all:$(TARGET) install

install: $(TARGET)
	-@mkdir -p $(INSTALL_PREFIX)/usr/bin
	@cp $(TARGET) $(INSTALL_PREFIX)/usr/bin
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/yolov5
	@cp $(TARGET) $(INSTALL_PREFIX)/etc/npu/yolov5
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/yolov5/model
	@cp model/$(NPU_VERSION)/* $(INSTALL_PREFIX)/etc/npu/yolov5/model
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/yolov5/input_data
	@cp input_data/* $(INSTALL_PREFIX)/etc/npu/yolov5/input_data

clean:
	rm -rf $(TARGET) *.o *~

