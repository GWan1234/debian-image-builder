.ONESHELL:
.SILENT:
.PHONY: clean list

# header
HEADER=./scripts/.header

# menu
MENU=./lib/dialog/menu
GMENU=./lib/dialog/general
CONF=./lib/dialog/config
DIALOGRC=$(shell cp -f lib/dialog/dialogrc ~/.dialogrc)

# misc
RFS=./scripts/rootfs
RFSX=./scripts/rootfs-extra
ROOTFS=sudo ./scripts/rootfs
CLN=./scripts/clean
CLEAN=sudo ./scripts/clean

# purge
PURGE=$(shell sudo rm -fdr sources; if [ -d .cache ]; then sudo rm -f .cache/git_fast.*; fi)
PURGEALL=$(shell sudo rm -fdr sources output; if [ -d .cache ]; then sudo rm -f .cache/git_fast.*; fi)
PURGELOG=$(shell sudo rm -fdr output/logs)

# logger
RIT=./scripts/runit
LIT=./scripts/loggit

# uboot and linux
XUBOOT=./scripts/uboot
UBOOT=sudo ./scripts/uboot
DTCLIST=./scripts/dtclist
XKERNEL=./scripts/linux
KERNEL=sudo ./scripts/linux

# image
IMG=./scripts/stage1
IMAGE=sudo ./scripts/stage1
STG2=./scripts/stage2
XUSB=./scripts/usbboot
USBBOOT=sudo ./scripts/usbboot

# dependencies
CCOMPILE=./scripts/.ccompile
NCOMPILE=./scripts/.ncompile

# miscellaneous
CHECK=./scripts/check

# BOARDS
BOARDS=$(shell sudo rm -f board.txt; if [ -f lib/boards/${board} ]; then sudo cp lib/boards/${board} board.txt; fi)

ifdef board
include lib/boards/${board}
endif

define create_config
	@chmod +x ${CONF}
	@${CONF}
endef

define build_uboot
	@${BOARDS}
	@chmod +x ${XUBOOT}
	@${UBOOT}
endef

define build_kernel
	@${BOARDS}
	@chmod +x ${DTCLIST}
	@chmod +x ${XKERNEL}
	@${DTCLIST}
	@${KERNEL}
endef

define build_image
	@${BOARDS}
	@chmod +x ${IMG}
	@chmod +x ${STG2}
	@${IMAGE}
endef

define create_rootfs
	@${BOARDS}
	@chmod +x ${RFS}
	@chmod +x ${RFSX}
	@${ROOTFS}
endef 

define build_usbboot
	@${BOARDS}
	@chmod +x ${XUSB}
	@${USBBOOT}
endef

# USAGE
help:
	@echo ""
	@${HEADER}
	@echo ""
	@echo "\e[1;37mCommand List:\e[0m"
	@echo "  make ccompile\t\t\tInstall x86_64 dependencies"
	@echo "  make ncompile\t\t\tInstall aarch64 dependencies"
	@echo "  make config\t\t\tCreate user data file"
	@echo "  make menu\t\t\tMenu interface"
	@echo "  make clean\t\t\tClean up rootfs / image errors"
	@echo "  make purge\t\t\tRemove sources"
	@echo "  make purge-log\t\tRemove all logs"
	@echo "  make purge-all\t\tRemove logs, output and sources"
	@echo "  make check\t\t\tLatest revision of selected branch"
	@echo ""
	@echo "  make list\t\t\tList boards"
	@echo "  make uboot board=xxxx\t\tBuild u-boot package"
	@echo "  make kernel board=xxxx\tBuild linux kernel package"
	@echo "  make rootfs board=xxxx\tCreate rootfs tarball"
	@echo "  make image board=xxxx\t\tMake bootable image"
	@echo "  make usbboot board=xxxx\tMake bootable usb SDCARD image"
	@echo "  make all board=xxxx\t\tFeeling lucky?"
	@echo ""
	@echo "For details consult the \e[1;37mREADME.md\e[0m file"
	@echo

# DEPENDENCIES
ccompile:
	# X86_64 dependencies:
	@chmod +x ${CCOMPILE}
	@${CCOMPILE}

ncompile:
	# Aarch64 dependencies:
	@chmod +x ${NCOMPILE}
	@${NCOMPILE}

# USER DATA
config:
ifdef edit
	@if [ -f ${edit}.txt ]; then nano ${edit}.txt; else echo "${edit}.txt: file not found"; fi
	exit
endif
	$(call create_config)

# MENU
menu:
	@chmod +x ${MENU}
	@chmod +x ${GMENU}
	@chmod +x ${RIT}
	@chmod +x ${LIT}
	@${MENU}

# U-BOOT
uboot:
	@rm -f override.txt
# edit user data file
ifdef build
	@$(shell sed -i "s/^BUILD_VERSION=.*/BUILD_VERSION="'"${build}"'"/" userdata.txt)
endif
ifdef compiler
	@$(shell sed -i "s/^COMPILER=.*/COMPILER="'"${compiler}"'"/" userdata.txt)
endif
ifdef menuconfig
	@$(shell sed -i "s/^MENUCONFIG=.*/MENUCONFIG="'"${menuconfig}"'"/" userdata.txt)
endif
ifdef version
	@$(shell sed -i "s/^UBOOT_VERSION=.*/UBOOT_VERSION="'"${version}"'"/" userdata.txt)
endif
ifdef verbose
	@$(shell sed -i "s/^VERBOSE=.*/VERBOSE="'"${verbose}"'"/" userdata.txt)
endif
# edit board file
ifdef precompiled
	@echo 'PRECOMPILED_UBOOT="$(precompiled)"' >> override.txt
endif
ifdef force_version
	@echo 'FORCE_VERSION="$(force_version)"' >> override.txt
endif
	$(call build_uboot)

# KERNEL
kernel:
	@rm -f override.txt
# edit user data file
ifdef build
	@$(shell sed -i "s/^BUILD_VERSION=.*/BUILD_VERSION="'"${build}"'"/" userdata.txt)
endif
ifdef compiler
	@$(shell sed -i "s/^COMPILER=.*/COMPILER="'"${compiler}"'"/" userdata.txt)
endif
ifdef menuconfig
	@$(shell sed -i "s/^MENUCONFIG=.*/MENUCONFIG="'"${menuconfig}"'"/" userdata.txt)
endif
ifdef myconfig
	@$(shell sed -i "s/^CUSTOM_DEFCONFIG=.*/CUSTOM_DEFCONFIG="'"1"'"/" userdata.txt)
	@$(shell sed -i "s/^MYCONFIG=.*/MYCONFIG="'"${myconfig}_defconfig"'"/" userdata.txt)
endif
ifdef verbose
	@$(shell sed -i "s/^VERBOSE=.*/VERBOSE="'"${verbose}"'"/" userdata.txt)
endif
ifdef version
	@$(shell sed -i "s/^VERSION=.*/VERSION="'"${version}"'"/" userdata.txt)
endif
# edit board file
ifdef force_git
	@echo 'FORCE_GIT="$(force_git)"' > override.txt
endif
ifdef force_version
	@echo 'FORCE_VERSION="$(force_version)"' >> override.txt
endif
ifdef patching
	@echo 'LINUX_PATCHING="$(patching)"' >> override.txt
endif
	$(call build_kernel)

# ROOTFS
rootfs:
	@rm -f override.txt
# edit board file
ifdef distro
	@$(shell sed -i "s/^DISTRO=.*/DISTRO="'"${distro}"'"/" userdata.txt)
endif
ifdef release
	@$(shell sed -i "s/^DISTRO_VERSION=.*/DISTRO_VERSION="'"${release}"'"/" userdata.txt)
endif
ifdef verbose
	@$(shell sed -i "s/^VERBOSE=.*/VERBOSE="'"${verbose}"'"/" userdata.txt)
endif
	$(call create_rootfs)

# IMAGE
image:
	@rm -f override.txt
# edit user data file
ifdef distro
	@$(shell sed -i "s/^DISTRO=.*/DISTRO="'"${distro}"'"/" userdata.txt)
endif
ifdef release
	@$(shell sed -i "s/^DISTRO_VERSION=.*/DISTRO_VERSION="'"${release}"'"/" userdata.txt)
endif
ifdef verbose
	@$(shell sed -i "s/^VERBOSE=.*/VERBOSE="'"${verbose}"'"/" userdata.txt)
endif
	$(call build_image)

# ALL
all:
	$(call build_uboot)
	$(call build_kernel)
	$(call create_rootfs)
	$(call build_image)

usbboot:
	$(call build_usbboot)

# MISCELLANEOUS
check:
	@chmod +x ${CHECK}
	@${CHECK}

reset:
	@$(shell sed -i "s/^BUILD_VERSION=.*/BUILD_VERSION="'"1"'"/" userdata.txt)
	@$(shell sed -i "s/^MENUCONFIG=.*/MENUCONFIG="'"0"'"/" userdata.txt)
	@$(shell sed -i "s/^CUSTOM_DEFCONFIG=.*/CUSTOM_DEFCONFIG="'"0"'"/" userdata.txt)
	@$(shell sed -i "s/^MYCONFIG=.*/MYCONFIG="'"_defconfig"'"/" userdata.txt)

list:
	# Boards
	@ls lib/boards/

dialogrc:
	@${DIALOGRC}

clean:
	@chmod +x ${CLN}
	@${CLEAN}

purge:
	# Removing sources
	@${PURGE}

purge-all:
	# Removing logs, output and sources
	@${PURGEALL}

purge-log:
	# Removing logs
	@${PURGELOG}
