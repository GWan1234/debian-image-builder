# DEBIAN IMAGE BUILDER

setenv bootlabel ""
setenv rootfstype ""
setenv kernel ""
setenv initramfs ""
setenv platform ""
setenv fdtfile ""

setenv nvme_boot "false"
setenv nvme_devtype "nvme"
setenv nvme_devnum "0"
setenv nvme_bootpart "1"

# Force nvme boot
if test "${nvme_boot}" = true; then
	if test -e ${nvme_devtype} ${nvme_devnum}:${nvme_bootpart} /boot.scr; then
		setenv devtype $nvme_devtype
		setenv devnum $nvme_devnum
		setenv distro_bootpart $nvme_bootpart
	elif test -e ${nvme_devtype} ${nvme_devnum}:${nvme_bootpart} /boot/boot.scr; then
		setenv devtype $nvme_devtype
		setenv devnum $nvme_devnum
		setenv distro_bootpart $nvme_bootpart
	fi
fi

# Set boot variables
if test -e ${devtype} ${devnum}:${distro_bootpart} boot.scr; then
	setenv envconfig "config.txt"
	setenv fk_kvers ${kernel}
	setenv initrd ${initramfs}
	setenv fdtdir ${platform}
	setenv user_overlay_dir user-overlays
	part uuid ${devtype} ${devnum}:2 uuid
elif test -e ${devtype} ${devnum}:${distro_bootpart} boot/boot.scr; then
	setenv envconfig "boot/config.txt"
	setenv fk_kvers boot/${kernel}
	setenv initrd boot/${initramfs}
	setenv fdtdir boot/${platform}
	setenv user_overlay_dir boot/user-overlays
	part uuid ${devtype} ${devnum}:1 uuid
fi

echo "Loading ${envconfig} from ${devtype} ${devnum}:${distro_bootpart} ..."
load ${devtype} ${devnum}:${distro_bootpart} ${scriptaddr} ${envconfig}
env import -t ${scriptaddr} ${filesize}

setenv bootargs "${console} rw root=PARTUUID=${uuid} ${rootfstype} ${verbose} fsck.repair=yes ${extra} rootwait"

setenv loading ""
${loading} ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} ${fk_kvers} \
&& ${loading} ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} ${fdtdir}/${fdtfile} \
&& ${loading} ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} ${initrd}

if test -e ${devtype} ${devnum}:${distro_bootpart} ${envconfig}; then
	fdt addr ${fdt_addr_r}
	fdt resize 8192
	setexpr fdtovaddr ${fdt_addr_r} + ${fdtoverlay_addr_r}
	if load ${devtype} ${devnum}:${distro_bootpart} ${fdtovaddr} ${envconfig} \
		&& env import -t ${fdtovaddr} ${filesize} && test -n ${overlays}; then
		for dtoverlay in ${overlays}; do
			echo "Applying ${dtoverlay} ..."
			load ${devtype} ${devnum}:${distro_bootpart} ${fdtovaddr} ${fdtdir}/overlays/${dtoverlay}.dtbo && fdt apply ${fdtovaddr}
		done
	fi
	if load ${devtype} ${devnum}:${distro_bootpart} ${fdtovaddr} ${envconfig} \
		&& env import -t ${fdtovaddr} ${filesize} && test -n ${user_overlays}; then
		for dtoverlay in ${user_overlays}; do
			echo "Applying ${dtoverlay} ..."
			load ${devtype} ${devnum}:${distro_bootpart} ${fdtovaddr} ${user_overlay_dir}/${dtoverlay}.dtbo && fdt apply ${fdtovaddr}
		done
	fi
fi

echo "Booting $bootlabel from ${devtype} ${devnum}:${distro_bootpart} ..." \
&& booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}

echo "Trying bootm ..." \
&& bootm ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
