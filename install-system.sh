#!/bin/sh

# System installation script for Arch Linux

cb="$(tput setaf 0)"
cr="$(tput setaf 1)"
cg="$(tput setaf 2)"
cy="$(tput setaf 3)"
cb="$(tput setaf 4)"
cm="$(tput setaf 5)"
cc="$(tput setaf 6)"
cw="$(tput setaf 7)"
sb="$(tput bold)"
sn="$(tput sgr0)"
sr="$(tput smso)"
su="$(tput smul)"

print() {
	case "$1" in
		t|title)
			shift;
			printf "%s\n" "${sb}${cg}### $*${sn}"
			;;
		s|step)
			shift;
			printf "%s\n" "${sb}${cm}=== $*${sn}"
			;;
		l|list)
			shift;
			printf "%s\n" "${sb}${cb}  - $*${sn}"
			;;
		w|warning)
			shift;
			printf "%s\n" "${sb}${cy}::: $*${sn}"
			;;
		e|error)
			shift;
			printf "%s\n" "${sb}${cr}!!! $*${sn}"
			exit 1
			;;
		i|input)
			shift;
			rg="$1";
			shift;
			user_input=''
			while [ -z "$user_input" ]; do
				printf "%s" "${sb}${cc}==> $* ${sn}";
				read;
				user_input="$REPLY"
				if [ -n "$rg" ] && echo "$user_input" | grep -Evq "^$rg$"; then
					print w 'Invalid input, try again!';
					user_input='';
				fi;
			done;
			;;
		p|protected)
			shift;
			rg="$1";
			shift;
			user_input=''
			while [ -z "$user_input" ]; do
				printf "%s" "${sb}${cc}==> $* ${sn}";
				stty -echo
				read;
				user_input="$REPLY"
				stty echo
				printf '\n'
				if [ -n "$rg" ] && echo "$user_input" | grep -Evq "^$rg$"; then
					print w 'Invalid input, try again!';
					user_input='';
				fi;
			done;
			;;
		c|confirm)
			shift;
			def="$1";
			shift;
			user_input=''
			while [ -z "$user_input" ]; do
				case "$def" in
					y|Y)
						printf "%s" "${sb}${cc}==> $* [Y/n] ${sn}";
						def='y';;
					n|N)
						printf "%s" "${sb}${cc}==> $* [y/N] ${sn}";
						def='n';;
					*)
						printf "%s" "${sb}${cc}==> $* [y/n] ${sn}";
						def='';;
				esac
				read user_input
				case "$user_input" in
					y|Y)
						[ "$def" != 'n' ];
						return $?;;
					n|N)
						[ "$def" = 'n' ];
						return $?;;
					*)
						[ "$def" != '' ] && return 0;
						user_input='';
						print w 'Invalid input, try again!';;
				esac
			done;
			;;
		*)
			printf '%s\n' "$*"
			;;
	esac
}

check_environment() {

	# Initialization
	print t 'Checking installation environment'

	# Check hostname
	print s 'Verifying installation environment'
	[ "$(hostname)" = 'archiso' ] || \
	print w 'Not in the default installation environment, proceed with caution!'

	# Check internet
	print s 'Checking internet connection'
	ping -q -W 20 -c 1 1.1.1.1 1>/dev/null 2>/dev/null || \
	print e 'Not connected to the internet!'

	# Check EFI vars
	print s 'Checking boot mode'
	[ -n "$(ls -A /sys/firmware/efi/efivars)" ] || \
	print e 'Not booted in UEFI mode!'

}

configure_host() {

	print t 'Host configuration'

	print i '[a-zA-Z0-9-]+' 'Hostname:'
	conf_hostname="$user_input"

	while [ -z "$conf_timezone" ]; do
		print i '.+' 'Timezone:'
		if [ -f "/usr/share/zoneinfo/$user_input" ]; then
			conf_timezone="$user_input"
		else
			print w 'Invalid timezone!'
		fi
	done

	print s 'Select installation disk'
	lsblk -no NAME,SIZE,TYPE,FSTYPE
	avail_disks="$(lsblk -rno NAME,TYPE | awk '$2 == "disk" {d=sprintf("%s%s%s",d,(NR==1)?"":"|","("$1")")} END {print "("d")"}')"
	print i "$avail_disks" 'Install to:'
	conf_disk="$user_input"

	if print c 'Y' 'Enable full disk encryption'; then
		conf_disk_encryption='yes'
		print p '.+' 'Enter disk password:'
		conf_disk_pass="$user_input"
		print p '.+' 'Repeat disk password:'
		repeat_disk_pass="$user_input"
		[ "$conf_disk_pass" = "$repeat_disk_pass" ] || \
		print e 'Disk password mismatch!'
	else
		conf_disk_encryption='no'
	fi

}

configure_user() {

	print t 'User configuration'

	while [ -z "$conf_user" ]; do
		print i '[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30})' 'Username:'
		if id -u "$user_input" >/dev/null 2>/dev/null; then
			print w 'User already exists!'
		else
			conf_user="$user_input"
		fi
	done

	print p '.+' 'Enter password:'
	conf_pass="$user_input"
	print p '.+' 'Repeat password:'
	repeat_pass="$user_input"
	[ "$conf_pass" = "$repeat_pass" ] || \
	print e 'Password mismatch!'

	conf_passwordless='no'
	print c 'Y' 'Passwordless sudo?' && \
	conf_passwordless='yes'

	conf_shell='bash'
	print c 'Y' 'Set default shell to fish?' && \
	conf_shell='fish'

}

installation_summary() {

	print t 'Configuration summary'

	print s 'Host settings'
	print l 'Hostname:' "${sn}${sb}$conf_hostname"
	print l 'Timezone:' "${sn}${sb}$conf_timezone"
	print l 'Installation disk:' "${sn}${sb}$conf_disk"
	print l 'Encryption:' "${sn}${sb}$conf_disk_encryption"

	print s 'User settings'
	print l 'Username:' "${sn}${sb}$conf_user"
	print l 'Passwordless sudo:' "${sn}${sb}$conf_passwordless"
	print l 'Shell:' "${sn}${sb}$conf_shell"

	print w 'Caution: proceeding with the installation'
	print w 'will wipe all data from the installation disk!'
	print w 'Type YES to continue.'

	print i '.*' 'Continue?'
	[ "$user_input" = 'YES' ] || \
	print e 'Aborting installation!'

}

pre_installation() {

	print t 'Preparing installation' && \

	print s 'Update the system clock' && \
	timedatectl set-ntp true && \

	print s 'Update repository mirrors' && \
	curl -L 'https://www.archlinux.org/mirrorlist/?country=DE&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' | sed 's/^#//' > /etc/pacman.d/mirrorlist && \

	print s 'Prepare required packages' && \
	pacman -Sy --noconfirm --needed lvm2 && \

	print s 'Format disk' && \
	sgdisk "/dev/$conf_disk" -o -n 1:0:512M -t 1:ef00 -N 2 -t 2:8309 && \

	print s 'Format boot partition' && \
	mkfs.fat -F32 "/dev/${conf_disk}1" && \

	if [ "$conf_disk_encryption" = 'yes' ]; then

		print s 'Setup LUKS blockdevice on system partition' && \
		echo "$conf_disk_pass" | cryptsetup -q luksFormat "/dev/${conf_disk}2" && \

		print s 'Mount the LUKS container' && \
		echo "$conf_disk_pass" | cryptsetup open "/dev/${conf_disk}2" cryptlvm && \

		print s 'Create a physical volume on top of the opened LUKS container' && \
		pvcreate /dev/mapper/cryptlvm && \

		print s 'Create ArchLinux volume group' && \
		vgcreate ArchLinux /dev/mapper/cryptlvm && \

		print s 'Create root filesystem volume' && \
		lvcreate -l 100%FREE ArchLinux -n root && \
		mkfs.ext4 /dev/ArchLinux/root

	else

		print s 'Format root partition' && \
		mkfs.ext4 -F "/dev/${conf_disk}2"

	fi && \

	print s 'Mount partitions' && \
	if [ "$conf_disk_encryption" = 'yes' ]; then
		mount /dev/ArchLinux/root /mnt
	else
		mount "/dev/${conf_disk}2" /mnt
	fi && \
	mkdir -p /mnt/boot && \
	mount "/dev/${conf_disk}1" /mnt/boot

}

installation() {

	print t 'Installing system' && \

	print s 'Install Arch Linux base system' && \
	pacstrap /mnt base linux linux-firmware lvm2 networkmanager sudo "$conf_shell" && \

	print s 'Enable NetworkManager service' && \
	arch-chroot /mnt systemctl enable NetworkManager && \

	print s 'Generate fstab entries' && \
	genfstab -U /mnt >> /mnt/etc/fstab && \

	print s 'Set timezone' && \
	ln -sf "/usr/share/zoneinfo/$conf_timezone" /mnt/etc/localtime && \
	arch-chroot /mnt hwclock --systohc && \

	print s 'Configure localization' && \
	echo 'en_US.UTF-8 UTF-8' >> /mnt/etc/locale.gen && \
	arch-chroot /mnt locale-gen && \
	echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf && \

	print s 'Set default console font' && {
	tee -a /mnt/etc/vconsole.conf << END
KEYMAP=us
FONT=default8x16
END
	} && \

	print s 'Set hostname and populate hosts file' && \
	echo "$conf_hostname" > /mnt/etc/hostname && {
	tee -a /mnt/etc/hosts << END
127.0.0.1   localhost
::1         localhost
127.0.1.1   $conf_hostname.localdomain $conf_hostname
END
	} && \

	if [ "$conf_disk_encryption" = 'yes' ]; then
		print s 'Create initial ramdisk with LUKS and LVM support' && \
		sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /mnt/etc/mkinitcpio.conf && \
		arch-chroot /mnt mkinitcpio -P
	fi && \

	print s 'Detect CPU vendor and install microcode' && {
	grep -qi 'vendor.*intel' /proc/cpuinfo && cpu_vendor='intel'
	grep -qi 'vendor.*amd' /proc/cpuinfo && cpu_vendor='amd'
	[ -n "$cpu_vendor" ] && arch-chroot /mnt pacman -Sy --noconfirm --needed "${cpu_vendor}-ucode"
	true
	} && \
	print s 'Setup bootloader' && \
	arch-chroot /mnt bootctl install && {
	tee /mnt/boot/loader/loader.conf << END
timeout 1
default arch
END
	} && 
	if [ "$conf_disk_encryption" = 'yes' ]; then
		root_volume="cryptdevice=UUID=$(lsblk "/dev/${conf_disk}2" -r -n -o UUID | head -n 1):cryptlvm root=/dev/ArchLinux/root"
	else
		root_volume="root=UUID=$(lsblk "/dev/${conf_disk}2" -r -n -o UUID | head -n 1)"
	fi && {
	tee /mnt/boot/loader/entries/arch.conf << END
title    Arch Linux
linux    /vmlinuz-linux
$([ -n "$cpu_vendor" ] && echo "initrd   /${cpu_vendor}-ucode.img")
initrd   /initramfs-linux.img
options  $root_volume rw add_efi_memmap
END
	} && \

	print s 'Create user account' && \
	arch-chroot /mnt useradd -m -u 1000 -U -s "/usr/bin/$conf_shell" "$conf_user" && \
	arch-chroot /mnt su -c "echo '$conf_user:$conf_pass' | chpasswd" && \
	if [ "$conf_passwordless" = 'yes' ]; then
		echo "$conf_user ALL=(ALL) NOPASSWD: ALL" > "/mnt/etc/sudoers.d/$conf_user"
	else
		echo "$conf_user ALL=(ALL) ALL" > "/mnt/etc/sudoers.d/$conf_user"
	fi

}

post_installation() {

	print t 'Post installation'

	print c 'Y' 'Download dotfile installer?'
	dotfiles_installer

	print c 'N' 'Chroot into system for manual modifications?' ||
	arch-chroot /mnt "/usr/bin/$conf_shell"

	print s 'Unmount filesystem'
	umount -R /mnt && \
	if [ "$conf_disk_encryption" = 'yes' ]; then
		lvchange -an /dev/ArchLinux && \
		cryptsetup close cryptlvm
	fi && \

	print s 'Installation complete' && \
	print w 'Run reboot command and eject your installation media'

}

dotfiles_installer() {

	print s 'Downloading latest dotfiles snapshot' && \
	arch-chroot /mnt pacman -Sy --needed --noconfirm git && \
	arch-chroot /mnt git clone https://github.com/filiparag/dotfiles /opt/dotfiles && \

	print s 'Linking installer script' && \
	arch-chroot /mnt ln -s /opt/dotfiles/install-dotfiles.sh /usr/bin/dotfiles-install && \

	print w 'To install dotfiles, run dotfiles-install when you log in'

}

check_environment && configure_host && configure_user && installation_summary && \
pre_installation && installation && post_installation || print e 'Fatal error, halting installation!'

exit