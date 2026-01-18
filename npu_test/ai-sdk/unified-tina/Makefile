
all:$(TARGET) install

install: $(TARGET)
	-@mkdir -p $(INSTALL_PREFIX)/usr/lib
	-@mkdir -p $(INSTALL_PREFIX)/usr/include
	@cp -rf inc/* $(INSTALL_PREFIX)/usr/include
	@cp lib/$(C_LIB_TYPE)/*.so* $(INSTALL_PREFIX)/usr/lib

clean:
	rm -rf *.o *~
