
##### Define scripting #####
SHELL:=/bin/bash

#### Define PREFIX ####
THIS_MAKEFILE_DIR_= $(shell pwd)/$(dir $(lastword $(MAKEFILE_LIST)))
THIS_MAKEFILE_DIR= $(shell readlink -f $(THIS_MAKEFILE_DIR_))
PREFIX:= $(THIS_MAKEFILE_DIR)/_install_dir_toolchains

# $(1)== $(PREFIX)
# $(2)== $(BUILD_DIR)
# $(3)== $(SOURCE_DIR)
# $(4)== $(CONFIGURE_PARAMS)
# $(5)== 'true' to autoreconf; 'false' else
define configure_template
	mkdir -p $(1)
	mkdir -p $(1)/lib
	mkdir -p $(1)/include
	mkdir -p $(2)
	if [ ! -f $(2)/Makefile ] ; then \
		if $(5); then cd $(3); autoreconf; fi; \
		cd $(2); \
		$(3)/configure $(4); \
	fi
endef
define make_all_template
# Configure
	$(call configure_template,$(1),$(2),$(3),$(4),$(5))
# Build
cd $(2); make
# Install
cd $(2); make install
# Remove changes from original source
#git checkout -- $(3)
#clean:
#	@rm -rf $(2)
endef

.PHONY : mingw-w64

all:
	make binutils
	make mingw-w64-headers 
	make gcc-cross-compilers
	make mingw-w64-crt
	make gcc-cross-compilers-finish
	make pthreads

# $(BUILD_DIR) is "build_" + <target-name>
# $(SOURCE_DIR) *MUST* be <target-name> -thus, source folder name should be equal to target-
binutils: flex
	# == Building binutils cross toolchain == [CRSBNT]
	$(eval SRC_DIR:=binutils-2.30)
	$(eval PATH:=$(PREFIX)/bin:$(PATH))
	export PATH=$(PATH)
	$(eval CONFIGURE_PARAMS:=--with-sysroot=${PREFIX} --prefix=${PREFIX} \
	--host=x86_64-w64-mingw32 --target=x86_64-w64-mingw32 --enable-targets=x86_64-w64-mingw32,i686-w64-mingw32)
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)

mingw-w64-headers:
	# == Install the Mingw-w64 header set and create required symlinks == [HDRSYM]
	$(eval CONFIGURE_PARAMS:=--build=x86_64-linux --host=x86_64-w64-mingw32 --prefix=${PREFIX}/x86_64-w64-mingw32)
	$(call configure_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/mingw-w64/$@,$(CONFIGURE_PARAMS), false)
	cd $(THIS_MAKEFILE_DIR)/build_$@; make install
	@if [ ! -L $(PREFIX)/mingw ] ; then \
		ln -s $(PREFIX)/x86_64-w64-mingw32 $(PREFIX)/mingw; \
	fi
	@mkdir -p $(PREFIX)/x86_64-w64-mingw32/lib
	@if [ ! -L $(PREFIX)/x86_64-w64-mingw32/lib64 ] ; then \
		ln -s $(PREFIX)/x86_64-w64-mingw32/lib $(PREFIX)/x86_64-w64-mingw32/lib64; \
	fi

gmp:
	$(eval SRC_DIR:=gmp-6.1.0)
	$(eval CONFIGURE_PARAMS:=--prefix=${PREFIX})
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)

mpfr: gmp
	$(eval SRC_DIR:=mpfr-3.1.4)
	$(eval CONFIGURE_PARAMS:=--prefix=${PREFIX} --with-gmp=$(PREFIX))
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)

mpc: mpfr
	$(eval SRC_DIR:=mpc-1.0.3)
	$(eval CONFIGURE_PARAMS:=--prefix=${PREFIX} --with-gmp=$(PREFIX))
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)

bison:
	tar -xf bison-3.0.5.tar.gz
	$(eval SRC_DIR:=bison-3.0.5)
	$(eval CONFIGURE_PARAMS:=--prefix=${PREFIX})
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)
	rm -rf bison-3.0.5

flex: bison
	$(eval SRC_DIR:=flex-2.6.3)
	$(eval PATH:=$(PREFIX)/bin:$(PATH))
	export PATH=$(PATH)
	$(eval CONFIGURE_PARAMS:=--prefix=${PREFIX})
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)

gcc-cross-compilers: flex mpc
	# == Building the GCC core cross-compiler(s) == [BDGCOR]
	$(eval SRC_DIR:=gcc-8.1.0)
	$(eval PATH:=$(PREFIX)/bin:$(PATH))
	$(eval LDFLAGS:=-L$(PREFIX)/lib)
	$(eval CPPFLAGS:=-I$(PREFIX)/include)
	$(eval LD_LIBRARY_PATH:=$(PREFIX)/lib)
	export PATH=$(PATH)
	export LDFLAGS=$(LDFLAGS)
	export CPPFLAGS=$(CPPFLAGS)
	#export LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) #pass directly
	#@echo LD_LIBRARY_PATH is: '$(LD_LIBRARY_PATH)'
	$(eval CONFIGURE_PARAMS:=--with-sysroot=${PREFIX} --prefix=${PREFIX} --target=x86_64-w64-mingw32 --enable-targets=all \
	--with-gmp=$(PREFIX) --with-mpfr=$(PREFIX) --with-mpc=$(PREFIX) --enable-languages=c,c++)
	$(call configure_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/$(SRC_DIR),$(CONFIGURE_PARAMS), false)
	cd $(THIS_MAKEFILE_DIR)/build_$@; make all-gcc LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)
	cd $(THIS_MAKEFILE_DIR)/build_$@; make install-gcc

mingw-w64-crt:
	# == Building the crt (Mingw-w64 itself) == [BLDCRT]
	$(eval CONFIGURE_PARAMS:=--with-sysroot=${PREFIX} --prefix=${PREFIX}/x86_64-w64-mingw32 \
	--host=x86_64-w64-mingw32 --enable-lib32)
	$(call make_all_template,$(PREFIX),$(THIS_MAKEFILE_DIR)/build_$@,$(THIS_MAKEFILE_DIR)/mingw-w64/$@,$(CONFIGURE_PARAMS), false)

gcc-cross-compilers-finish:
	# == Finishing GCC (the libraries built using GCC core and Mingw-w64) == [FNSHGC]
	$(eval PATH:=$(PREFIX)/bin:$(PATH))
	$(eval LDFLAGS:=-L$(PREFIX)/lib)
	$(eval CPPFLAGS:=-I$(PREFIX)/include)
	$(eval LD_LIBRARY_PATH:=$(PREFIX)/lib)
	export PATH=$(PATH)
	export LDFLAGS=$(LDFLAGS)
	export CPPFLAGS=$(CPPFLAGS)
	cd $(THIS_MAKEFILE_DIR)/build_gcc-cross-compilers; make LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)
	cd $(THIS_MAKEFILE_DIR)/build_gcc-cross-compilers; make install

pthreads:
	# === pthreads-win32 === [PTHRW32]
	cd $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release; make clean GC CROSS=x86_64-w64-mingw32-
	cd $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release; cp -a pthreadGC2.dll $(PREFIX)/x86_64-w64-mingw32/lib/libpthread.a
	cd $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release; cp -a pthread.h sched.h semaphore.h $(PREFIX)/x86_64-w64-mingw32/include/
	#while read a ; do echo ${a//#if\ defined(HAVE_PTW32_CONFIG_H)/\/*\ #if HAVE_CONFIG_H\ *\/} ; done < $(PREFIX)/x86_64-w64-mingw32/include/pthread.h > $(PREFIX)/x86_64-w64-mingw32/include/pthread.h.t ; mv $(PREFIX)/x86_64-w64-mingw32/include/pthread.h{.t,}
	sed -i -e 's/#if\ defined(HAVE_PTW32_CONFIG_H)/\/\/#if\ defined(HAVE_PTW32_CONFIG_H)\ \/\/RAL/g' $(PREFIX)/x86_64-w64-mingw32/include/pthread.h
	sed -i -e 's/#endif\ \/\*\ HAVE_PTW32_CONFIG_H\ \*\//\/\/#endif\ \/\*\ HAVE_PTW32_CONFIG_H\ \*\/\ \/\/RAL/g' $(PREFIX)/x86_64-w64-mingw32/include/pthread.h
	sed -i -e 's/#include\ "config.h"/#include\ "pconfig.h"\ \/\/RAL/g' $(PREFIX)/x86_64-w64-mingw32/include/pthread.h
	cp -a $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release/config.h $(PREFIX)/x86_64-w64-mingw32/include/pconfig.h

clean:
	@rm -rf build_*
	@rm -rf _install_dir_*
	@rm -f hello_world_test-w64.exe
	@rm -rf flex-2.6.3/autom4te.cache mpfr-3.1.4/autom4te.cache
	@git checkout -- binutils-2.30 flex-2.6.3 gcc-8.1.0 gmp-6.1.0 mingw-w64 mpfr-3.1.4 mpc-1.0.3 pthreads-w32-2-9-1-release
	make -C $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release clean
	@rm -rf $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release/*.a $(THIS_MAKEFILE_DIR)/pthreads-w32-2-9-1-release/*.dll

