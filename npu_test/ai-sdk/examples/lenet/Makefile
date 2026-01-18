TARGET = lenet

ifdef AI_SDK_PLATFORM
include ../../machinfo/$(AI_SDK_PLATFORM)/config.mk
endif

INCLUDE += -I$(INSTALL_PREFIX)/usr/include -I../libawnn_viplite -I../libawutils -I../../
LIBS    += -L $(INSTALL_PREFIX)/usr/lib -Wl,-rpath-link,$(INSTALL_PREFIX)/usr/lib 
SRCS    += main.c ../libawnn_viplite/awnn_lib.c ../libawnn_viplite/awnn_quantize.c

CFLAGS += -g -O0 -DDEBUG -D_DEBUG

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
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/lenet
	@cp $(TARGET) $(INSTALL_PREFIX)/etc/npu/lenet
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/lenet/model
	@cp model/$(NPU_VERSION)/* $(INSTALL_PREFIX)/etc/npu/lenet/model
	-@mkdir -p $(INSTALL_PREFIX)/etc/npu/lenet/input_data
	@cp input_data/* $(INSTALL_PREFIX)/etc/npu/lenet/input_data

clean:
	rm -rf $(TARGET) *.o *~

