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
			user_input_correct='false'
			while [ "$user_input_correct" != 'true' ]; do
				printf "%s" "${sb}${cc}==> $* ${sn}";
				read;
				user_input="$REPLY"
				if [ -n "$rg" ] && echo "$user_input" | grep -Evq "^$rg$"; then
					print w 'Invalid input, try again!';
					user_input='';
				else
					user_input_correct='true'
				fi;
			done;
			;;
		p|protected)
			shift;
			rg="$1";
			shift;
			user_input=''
			user_input_correct='false'
			while [ "$user_input_correct" != 'true' ]; do
				printf "%s" "${sb}${cc}==> $* ${sn}";
				stty -echo
				read;
				user_input="$REPLY"
				stty echo
				printf '\n'
				if [ -n "$rg" ] && echo "$user_input" | grep -Evq "^$rg$"; then
					print w 'Invalid input, try again!';
					user_input='';
				else
					user_input_correct='true'
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

	print t 'Checking installation environment'

	print s 'Verifying installation environment'
	[ "$(hostname)" = 'archiso' ] || {
		print w 'Not in the default installation environment,'
		print w 'proceed with caution!'
	}

	print s 'Checking root privileges'
	[ "$(whoami)" = 'root' ] || \
	print w 'Warning: insufficient privileges!'

	print s 'Checking internet connection'
	ping -q -W 20 -c 1 1.1.1.1 1>/dev/null 2>/dev/null || \
	print e 'Not connected to the internet!'

	print s 'Checking boot mode'
	[ -n "$(ls -A /sys/firmware/efi/efivars)" ] || \
	print e 'Not booted in UEFI mode!'

}

parse_options() {
	WARN_PARAMS='false'
	CONF_PASS_PROMPT='p'
	while getopts H:T:D:E:S:K:R:AUu:p:xs:Yih o; do
		case $o in
			# Hostname
			(H) CONF_HOSTNAME="$OPTARG";
				WARN_PARAMS='true';;
			# Timezone
			(T) CONF_TIMEZONE="$OPTARG";
				WARN_PARAMS='true';;
			# Installation disk
			(D) CONF_DISK="$OPTARG";
				WARN_PARAMS='true';;
			# Disk encryption password
			(E) if [ "$OPTARG" = '' ]; then
					CONF_DISK_ENCRYPTION='no'
				else
					CONF_DISK_ENCRYPTION='yes'
					CONF_DISK_PASS="$OPTARG"
				fi;
				WARN_PARAMS='true';;
			# Swap file size
			(S) if [ "$OPTARG" = '0' ]; then
					CONF_SWAPFILE='no'
					CONF_SWAPFILE_SIZE='no'
				else
					CONF_SWAPFILE='yes'
					CONF_SWAPFILE_SIZE="$OPTARG"
				fi;
				WARN_PARAMS='true';;
			# Enable LTS kernel
			(K) if [ "$OPTARG" = 'yes' ]; then
					CONF_LTS_KERNEL="$OPTARG";
					CONF_LTS='linux-lts';
				else
					CONF_LTS_KERNEL='no';
					CONF_LTS='';
				fi;
				WARN_PARAMS='true';;
			# Repository mirror countries
			(R) CONF_MIRRORS="$OPTARG";
				WARN_PARAMS='true';;
			# Disable Arch User Repository
			(A) CONF_AUR='no';
				WARN_PARAMS='true';;
			# Disable primary user
			(U) CONF_ADD_USER='no';
				WARN_PARAMS='true';;
			# Username
			(u) CONF_USER="$OPTARG";
				WARN_PARAMS='true';;
			# Password
			(p) CONF_PASS="$OPTARG";
				CONF_PASS_ROOT="$OPTARG";
				CONF_PASS_PROVIDED='true'
				WARN_PARAMS='true';;
			# Disable passwordless sudo
			(x) CONF_PASSWORDLESS='no';
				WARN_PARAMS='true';;
			# Default user shell
			(s) CONF_SHELL="$OPTARG";
				WARN_PARAMS='true';;
			# Skip configuration confirmation
			(Y) CONF_SKIP_CONFIRMATION='true';
				print w 'Configuration confirmation will be skipped!';;
			# Insecure - show passwords in summary
			(i) CONF_INSECURE='true';
				CONF_PASS_PROMPT='i';
				print w 'Insecure mode: passwords will be visible!';;
			# Show usage help and exit
			(h) print t 'Usage help – arguments';
				print s 'Host configuration';
				print l 'H' "${sn}${sb}${cc}HOSTNAME     " "${sn}Hostname";
				print l 'T' "${sn}${sb}${cc}TIMEZONE     " "${sn}Timezone";
				print l 'D' "${sn}${sb}${cc}DISK         " "${sn}Installation disk";
				print l 'E' "${sn}${sb}${cc}DISK_PASS    " "${sn}Disk encryption password (${sb}empty${sn} to disable)";
				print l 'S' "${sn}${sb}${cc}SWAPFILE_SIZE" "${sn}Swap file size (${sb}0${sn} to disable)";
				print l 'K' "${sn}${sb}${cc}yes/no       " "${sn}Enable LTS kernel";
				print l 'R' "${sn}${sb}${cc}MIRRORS      " "${sn}Repository mirror countries";
				print l 'A' "${sn}${sb}${cc}             " "${sn}Disable Arch User Repository";
				print l 'U' "${sn}${sb}${cc}             " "${sn}Disable primary user";
				print s 'User configuration';
				print l 'u' "${sn}${sb}${cc}USER         " "${sn}Username";
				print l 'p' "${sn}${sb}${cc}PASS         " "${sn}Password (for root if user is disabled)";
				print l 'x' "${sn}${sb}${cc}             " "${sn}Disable passwordless sudo";
				print l 's' "${sn}${sb}${cc}SHELL        " "${sn}Default user shell";
				print s 'Other';
				print l 'Y' "${sn}${sb}${cc}             " "${sn}Skip configuration confirmation ${sb}${cr}(dangerous)";
				print l 'i' "${sn}${sb}${cc}             " "${sn}Insecure mode – show passwords ${sb}${cy}(not recommended)";
				print l 'h' "${sn}${sb}${cc}             " "${sn}Show usage help and exit";
				exit;;
			(*) print e 'Invalid argument';;
		esac
	done
	shift "$((OPTIND - 1))"
	if [ "$WARN_PARAMS" = 'true' ]; then
		print s 'Using passed arguments'
		print w 'Warning: passed arguments are not validated!'
		print w 'If they are invalid, installation will fail.'
	fi
}

configure_host() {

	print t 'Host configuration'

	if [ -z "$CONF_HOSTNAME" ]; then
		print i '[a-zA-Z0-9-]+' 'Hostname:'
		conf_hostname="$user_input"
	else
		conf_hostname="$CONF_HOSTNAME"
	fi

	if [ -z "$CONF_TIMEZONE" ]; then
		while [ -z "$conf_timezone" ]; do
			print i '.+' 'Timezone:'
			if [ -f "/usr/share/zoneinfo/$user_input" ]; then
				conf_timezone="$user_input"
			else
				print w 'Invalid timezone!'
			fi
		done
	else
		conf_timezone="$CONF_TIMEZONE"
	fi

	if [ -z "$CONF_DISK" ]; then
		print s 'Select installation disk'
		lsblk -no NAME,SIZE,TYPE,FSTYPE
		avail_disks="$(lsblk -rno NAME,TYPE | awk '$2 == "disk" {d=sprintf("%s%s%s",d,(NR==1)?"":"|","("$1")")} END {print "("d")"}')"
		print i "$avail_disks" 'Install to:'
		conf_disk="$user_input"
	else
		conf_disk="$CONF_DISK"
	fi

	if [ -z "$CONF_DISK" ]; then
		if print c 'Y' 'Enable full disk encryption'; then
			conf_disk_encryption='yes'
			print "$CONF_PASS_PROMPT" '.+' 'Enter disk password:'
			conf_disk_pass="$user_input"
			print "$CONF_PASS_PROMPT" '.+' 'Repeat disk password:'
			repeat_disk_pass="$user_input"
			[ "$conf_disk_pass" = "$repeat_disk_pass" ] || \
			print e 'Disk password mismatch!'
		else
			conf_disk_encryption='no'
		fi
	else
		conf_disk_encryption="$CONF_DISK_ENCRYPTION"
		conf_disk_pass="$CONF_DISK_PASS"
	fi

	if [ -z "$CONF_SWAPFILE" ]; then
		if print c 'Y' 'Enable swap file'; then
			conf_swapfile='yes'
			swapfile_default="$(free --mega | awk '$1 == "Mem:" {print 2**int(log(int($2)/2)/log(2))}')"
			print i '$|^([1-9][0-9]*)' "Swap file size in megabytes [$swapfile_default]:"
			if [ -z "$user_input" ]; then
				conf_swapfile_size="$swapfile_default"
			else
				conf_swapfile_size="$user_input"
			fi
		else
			conf_swapfile='no'
			conf_swapfile_size='no'
		fi
	else
		conf_swapfile="$CONF_SWAPFILE"
		conf_swapfile_size="$CONF_SWAPFILE_SIZE"
	fi

	if [ -z "$CONF_LTS_KERNEL" ]; then
		if print c 'N' 'Include supplementary LTS kernel'; then
			conf_lts_kernel='no'
		else
			conf_lts_kernel='yes'
			conf_lts='linux-lts'
		fi
	else
		conf_lts_kernel="$CONF_LTS_KERNEL"
		conf_lts="$CONF_LTS"
	fi

	if [ -z "$CONF_MIRRORS" ]; then
		repo_countries='AU|AT|BD|BY|BE|BA|BR|BG|CA|CL|CN|CO|HR|CZ|DK|EC|FI|FR|GE|DE|GR|HK|HU|IS|IN|ID|IR|IE|IL|IT|JP|KZ|KE|LV|LT|LU|MD|NL|NC|NZ|MK|NO|PK|PY|PH|PL|PT|RO|RU|RS|SG|SK|SI|ZA|KR|ES|SE|CH|TW|TH|TR|UA|GB|US|VN'
		repo_countries_default='DE GB'
		print i "$|( *(($repo_countries) +)*(($repo_countries) *))" "Repository mirror countries [$repo_countries_default]:"
		if [ -z "$user_input" ]; then
			conf_mirrors="$repo_countries_default"
		else
			conf_mirrors="$(echo "$user_input" | sed 's/^ *//g; s/ \+/ /g; s/ *$//g')"
		fi
	else
		conf_mirrors="$CONF_MIRRORS"
	fi

	if [ -z "$CONF_AUR" ]; then
		if print c 'Y' 'Enable Arch User Repository'; then
			conf_aur='yes'
		else
			conf_aur='no'
		fi
	else
		conf_aur="$CONF_AUR"
	fi

	if [ -z "$CONF_ADD_USER" ] && [ -z "$CONF_USER" ]; then
		if print c 'Y' 'Add primary user'; then
			conf_add_user='yes'
		else
			conf_add_user='no'
		fi
	else
		conf_add_user="$CONF_ADD_USER"
	fi

	if [ "$conf_add_user" = 'no' ]; then
		if [ "$CONF_PASS_PROVIDED" != 'true' ]; then
			print "$CONF_PASS_PROMPT" '.*' 'Enter root password:'
			conf_pass_root="$user_input"
			print "$CONF_PASS_PROMPT" '.*' 'Repeat root password:'
			repeat_pass_root="$user_input"
			[ "$conf_pass_root" = "$repeat_pass_root" ] || \
			print e 'Password mismatch!'
			CONF_PASS_PROVIDED='true'
		else
			conf_pass_root="$CONF_PASS_ROOT"
		fi
	fi

}

configure_user() {

	[ "$conf_add_user" = 'no' ] && \
	return

	print t 'User configuration'

	if [ -z "$CONF_USER" ]; then
		while [ -z "$conf_user" ]; do
			print i '[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30})' 'Username:'
			if id -u "$user_input" >/dev/null 2>/dev/null; then
				print w 'User already exists!'
			else
				conf_user="$user_input"
			fi
		done
	else
		conf_add_user='yes'
		conf_user="$CONF_USER"
	fi

	if [ -z "$CONF_PASS" ] && [ "$CONF_PASS_PROVIDED" != 'true' ]; then
		print "$CONF_PASS_PROMPT" '.*' 'Enter password:'
		conf_pass="$user_input"
		print "$CONF_PASS_PROMPT" '.*' 'Repeat password:'
		repeat_pass="$user_input"
		[ "$conf_pass" = "$repeat_pass" ] || \
		print e 'Password mismatch!'
		CONF_PASS_PROVIDED='true'
	else
		conf_pass="$CONF_PASS"
	fi

	if [ -z "$CONF_PASSWORDLESS" ]; then
		conf_passwordless='no'
		print c 'Y' 'Passwordless sudo?' && \
		conf_passwordless='yes'
	else
		conf_passwordless="$CONF_PASSWORDLESS"
	fi

	if [ -z "$CONF_SHELL" ]; then
		shell_default='fish'
		print i '$|(bash)|(fish)|(zsh)|(ksh)|(tcsh)|(xonsh)' "Default shell [$shell_default]:"
		if [ -z "$user_input" ]; then
			conf_shell="$shell_default"
		else
			conf_shell="$user_input"
		fi
	else
		conf_shell="$CONF_SHELL"
	fi

}

configuration_summary() {

	print t 'Configuration summary'

	print s 'Host settings'
	print l 'Hostname:' "${sn}${sb}$conf_hostname"
	print l 'Timezone:' "${sn}${sb}$conf_timezone"
	print l 'Installation disk:' "${sn}${sb}$conf_disk"
	print l 'Encryption:' "${sn}${sb}$conf_disk_encryption"
	[ "$CONF_INSECURE" = 'true' ] && [ "$conf_disk_encryption" = 'yes' ] && \
	print l 'Disk password:' "${sn}${sb}$conf_disk_pass"
	print l 'Swap file:' "${sn}${sb}$conf_swapfile_size"
	print l 'Include LTS kernel:' "${sn}${sb}$conf_lts_kernel"
	print l 'Pacman mirror countries:' "${sn}${sb}$conf_mirrors"
	print l 'Arch User Repository:' "${sn}${sb}$conf_aur"
	[ "$CONF_INSECURE" = 'true' ] && [ "$conf_add_user" = 'no' ] && \
	print l 'Root password:' "${sn}${sb}${conf_pass_root:-${cy}empty}"

	if [ "$conf_add_user" = 'yes' ]; then
		print s 'User settings'
		print l 'Username:' "${sn}${sb}$conf_user"
		[ "$CONF_INSECURE" = 'true' ] && \
		print l 'Password:' "${sn}${sb}${conf_pass:-${cy}empty}"
		print l 'Passwordless sudo:' "${sn}${sb}$conf_passwordless"
		print l 'Shell:' "${sn}${sb}$conf_shell"
	else
		print l 'Add primary user:' "${sn}${sb}$conf_add_user"
	fi

	if [ "$CONF_SKIP_CONFIRMATION" = 'true' ]; then
		print w 'Warning: proceeding with the installation'
		print w 'will wipe all data from the installation disk!'
		print w 'Type YES to continue.'
		print i '.*' 'Continue?'
		[ "$user_input" = 'YES' ] || \
		print e 'Aborting installation!'
	fi

}

pre_installation() {

	print t 'Preparing installation' && \

	print s 'Update the system clock' && \
	timedatectl set-ntp true && \

	print s 'Update installer repository mirrors' && \
	mirror_country_url="$(echo "$conf_mirrors" | awk '{for (i=1;i<NF;i++) {query=query "&country=" $i}} END {print query}')" && \
	curl -L "https://www.archlinux.org/mirrorlist/?protocol=https&ip_version=4&ip_version=6&use_mirror_status=on$mirror_country_url" | sed 's/^#//' > /etc/pacman.d/mirrorlist && \

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
	pacstrap /mnt base linux linux-firmware lvm2 networkmanager sudo $conf_shell $conf_lts && \

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

	print s 'Configure pacman and makepkg' && \
	curl -L "https://www.archlinux.org/mirrorlist/?protocol=https&ip_version=4&ip_version=6&use_mirror_status=on$mirror_country_url" | sed 's/^#//' > /mnt/etc/pacman.d/mirrorlist && \
	sed 's/[ \t#]*MAKEFLAGS.*$/MAKEFLAGS="-j$(nproc)"/' -i /mnt/etc/makepkg.conf && \
	sed 's/^#Color$/Color/; s/^#TotalDownload$/TotalDownload/; s/^#VerbosePkgLists$/VerbosePkgLists/;' -i /mnt/etc/pacman.conf && \

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
	if [ "$conf_lts_kernel" = 'yes' ]; then
		tee /mnt/boot/loader/entries/arch-lts.conf << END
title    Arch Linux (LTS)
linux    /vmlinuz-linux-lts
$([ -n "$cpu_vendor" ] && echo "initrd   /${cpu_vendor}-ucode.img")
initrd   /initramfs-linux-lts.img
options  $root_volume rw add_efi_memmap
END
	fi && \

	if [ "$conf_add_user" = 'yes' ]; then
		print s 'Create user account' && \
		arch-chroot /mnt useradd -m -u 1000 -U -s "/usr/bin/$conf_shell" "$conf_user" && \
		arch-chroot /mnt su -c "echo '$conf_user:$conf_pass' | chpasswd" && \
		if [ "$conf_passwordless" = 'yes' ]; then
			echo "$conf_user ALL=(ALL) NOPASSWD: ALL" > "/mnt/etc/sudoers.d/$conf_user"
		else
			echo "$conf_user ALL=(ALL) ALL" > "/mnt/etc/sudoers.d/$conf_user"
		fi
	else
		print s 'Set root password' && \
		arch-chroot /mnt su -c "echo 'root:$conf_pass_root' | chpasswd"
	fi && \

	if [ "$conf_swapfile" = 'yes' ]; then
		print s 'Enable swap file' && \
		dd if=/dev/zero of=/mnt/swapfile bs=1M count="$conf_swapfile_size" status=progress && \
		chmod 600 /mnt/swapfile && \
		mkswap /mnt/swapfile && \
		echo '/swapfile none swap defaults 0 0' >> /mnt/etc/fstab
	fi && \

	if [ "$conf_aur" = 'yes' ]; then
		print s 'Enable Arch User Repository' && \
		pacman -Sy --noconfirm --needed fakeroot binutils git && \
		useradd -m builder && \
		su builder -c '
			cd ~ &&
			git clone https://aur.archlinux.org/yay-bin.git &&
			cd yay-bin &&
			makepkg
		' && \
		yay_package="$(find /home/builder/yay-bin -name '*.zst' -printf '%P')" && \
		mkdir -p /mnt/var/cache/pacman/pkg && \
		mv "/home/builder/yay-bin/$yay_package" "/mnt/var/cache/pacman/pkg/$yay_package" && \
		arch-chroot /mnt pacman -U "/var/cache/pacman/pkg/$yay_package" --noconfirm && \
		rm -f "/mnt/var/cache/pacman/pkg/$yay_package" && \
		print w 'Use yay to install packages from Arch User Repository'
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
	print w 'Reboot and eject your installation media'

}

dotfiles_installer() {

	print s 'Downloading latest dotfiles snapshot' && \
	arch-chroot /mnt pacman -Sy --needed --noconfirm git && \
	arch-chroot /mnt git clone https://github.com/filiparag/dotfiles /usr/share/dotfiles && \

	print s 'Linking installer script' && \
	arch-chroot /mnt ln -s /usr/share/dotfiles/install-dotfiles.sh /usr/bin/dotfiles-install && \

	print w 'To install dotfiles, run dotfiles-install when you log in'

}

# check_environment && configure_host && configure_user && configuration_summary && \
# pre_installation && installation && post_installation || print e 'Fatal error, halting installation!'

check_environment && parse_options "$@" && configure_host && configure_user && configuration_summary 

exit