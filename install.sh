#!/bin/sh

# System installation script for Arch Linux

ct="$(tput setaf 2; tput bold)=== "
ce="$(tput setaf 1; tput bold)!!! "
cw="$(tput setaf 3; tput bold)=== "
cp="$(tput setaf 6; tput bold)==> "
cs="$(tput setaf 2; tput bold)==> "
cl="$(tput sgr0)    - "
ch="$(tput setaf 5)"
cn="$(tput sgr0)"
ci="    "

# Initialization
printf "${ct}Initialization\n${cn}"

# Check internet
printf "${cl}Check internet connection\n${cn}"
ping -q -W 5 -c 1 1.1.1.1 1>/dev/null 2>/dev/null || {
	printf "${ce}Not connected to the internet!\n${cn}"
	exit 1
}

# Check EFI vars
printf "${cl}Check boot mode\n${cn}"
[ -z "$(ls -A /sys/firmware/efi/efivars)" ] && {
	printf "${ce}Not booted in UEFI mode!\n${cn}"
	exit 1
}

# User configuration
printf "${ct}User information\n${cn}"
printf "${cp}Username: ${cn}"
read config_user

stty -echo
printf "${cp}Password: ${cn}"
read config_pass
stty echo
printf '\n'

[ -z "$config_pass" ] && {
	printf "${ce}Empty password!\n${cn}"
	exit 1
}

stty -echo
printf "${cp}Repeat password: ${cn}"
read confirm_pass
stty echo
printf '\n'

[ "$config_pass" != "$confirm_pass" ] && {
	printf "${ce}Passwords don't match!\n${cn}"
	exit 1
}

# System configuration
printf "${ct}Full disk encryption\n${cn}"

stty -echo
printf "${cp}Password: ${cn}"
read config_disk_pass
stty echo
printf '\n'

[ -z "$config_disk_pass" ] && {
	printf "${ce}Empty password!\n${cn}"
	exit 1
}

stty -echo
printf "${cp}Repeat password: ${cn}"
read confirm_disk_pass
stty echo
printf '\n'

[ "$config_disk_pass" != "$confirm_disk_pass" ] && {
	printf "${ce}Passwords don't match!\n${cn}"
	exit 1
}

# Host configuration
printf "${ct}Host configuration\n${cn}"
printf "${cp}Hostname: ${cn}"
read config_host
printf "${cp}Timezone (Region/City): ${cn}"
read config_timezone

# Choose installation disk
printf "${ct}Select installation disk\n${cn}"
lsblk -no NAME,SIZE,TYPE,FSTYPE
printf "${cp}Install to /dev/${cn}"
read config_disk

test -b "/dev/${config_disk}" || {
	printf "${ce}Disk /dev/${config_disk} does not exist!\n${cn}"
	exit 1
}

# Display summary
printf "${ct}Installation summary\n${cn}"

printf "${cl}Format disk /dev/${ch}${config_disk}${cn} using GPT
${cl}Create /dev/${ch}${config_disk}1${cn} EFI boot partition
${cl}Create encrypted LVM on /dev/${ch}${config_disk}2${cn}
${cl}Create ${ch}${config_host}${cn}/root ext4 volume
${cl}Install Arch Linux base system
${cl}Set timezone to ${ch}${config_timezone}${cn}
${cl}Create user ${ch}${config_user}${cn} with passwordless sudo privilege\n"

printf "${cw}Performing installation is irreversible\n${ci}Type 'YES' to continue.\n${cn}"
printf "${cp}Continue: ${cn}"
read confirm_continue

[ "$confirm_continue" = 'YES' ] || {
	printf "${ce}Aborting\n${cn}"
	exit 255
}

printf "${ct}Installing system\n${cn}"

# Update the system clock
printf "${cs}Update the system clock${cn}\n"
timedatectl set-ntp true

# Update repository mirrors
printf "${cs}Update repository mirrorlist${cn}\n"
curl -L 'https://www.archlinux.org/mirrorlist/?country=DE&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' | sed 's/^#//' > /etc/pacman.d/mirrorlist

# Prepare required packages
printf "${cs}Install required packages${cn}\n"
pacman -Sy --noconfirm --needed lvm2

# Format disk
printf "${cs}Format disk${cn}\n"
sgdisk /dev/vda -o -n 1:0:512M -t 1:ef00 -N 2 -t 2:8309

# Format boot partition
printf "${cs}Format boot partition${cn}\n"
mkfs.fat -F32 /dev/vda1

# Format LUKS
printf "${cs}Create LUKS blockdevice${cn}\n"
echo "${config_disk_pass}" | cryptsetup -q luksFormat /dev/vda2

# Mount LUKS volume
echo "${config_disk_pass}" | cryptsetup open /dev/vda2 cryptlvm

# Create a physical volume on top of the opened LUKS container
pvcreate /dev/mapper/cryptlvm

# Create the volume group
printf "${cs}Create encrypted volume group${cn}\n"
vgcreate ArchLinux /dev/mapper/cryptlvm

# Create logical volumes
printf "${cs}Create root volume${cn}\n"
lvcreate -l 100%FREE ArchLinux -n root
mkfs.ext4 /dev/ArchLinux/root

# Mount partitions
printf "${cs}Mount filesystem${cn}\n"
mount /dev/ArchLinux/root /mnt
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot

# Install base system
printf "${cs}Install Arch Linux base system${cn}\n"
pacstrap /mnt base linux linux-firmware lvm2 networkmanager sudo fish

# Enable NetworkManager
printf "${cs}Enable NetworkManager service${cn}\n"
arch-chroot /mnt systemctl enable NetworkManager

# Generate fstab
printf "${cs}Generate fstab entries${cn}\n"
genfstab -U /mnt >> /mnt/etc/fstab

# Set timezone
printf "${cs}Set timezone info${cn}\n"
ln -sf "/usr/share/zoneinfo/${config_timezone}" /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

# Localization
printf "${cs}Configure localization${cn}\n"
echo 'en_US.UTF-8 UTF-8' >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf

# Console font
tee -a /mnt/etc/vconsole.conf << END
KEYMAP=us
FONT=default8x16
END

# Hosts
printf "${cs}Set hostname and populate hosts file${cn}\n"
echo "${config_host}" > /mnt/etc/hostname
tee -a /mnt/etc/hosts << END
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${config_host}.localdomain ${config_host}
END

# Add LVM and LUKS to mkinitcpio
printf "${cs}Create initial ramdisk with LUKS and LVM support${cn}\n"
sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

# Setup user
printf "${cs}Create user account${cn}\n"
arch-chroot /mnt useradd -m -u 1000 -U -s /usr/bin/fish "${config_user}"
arch-chroot /mnt su -c "echo '${config_user}:${config_pass}' | chpasswd"
echo "${config_user} ALL=(ALL) NOPASSWD: ALL" > "/mnt/etc/sudoers.d/${config_user}"

# Microcode
printf "${cs}Detect CPU vendor and install microcode${cn}\n"
cat /proc/cpuinfo | grep -qi 'vendor.*intel' && cpu_vendor='intel'
cat /proc/cpuinfo | grep -qi 'vendor.*amd' && cpu_vendor='amd'
[ -n "$cpu_vendor" ] && arch-chroot /mnt pacman -Sy --noconfirm --needed "${cpu_vendor}-ucode"

# Setup bootloader
printf "${cs}Setup bootloader${cn}\n"
arch-chroot /mnt bootctl install
tee /mnt/boot/loader/loader.conf << END
timeout 1
default arch
END
tee /mnt/boot/loader/entries/arch.conf << END
title    Arch Linux
linux    /vmlinuz-linux
$([ -n "$cpu_vendor" ] && echo "initrd   /${cpu_vendor}-ucode.img")
initrd   /initramfs-linux.img
options  cryptdevice=UUID=$(lsblk /dev/vda2 -r -n -o UUID | head -n 1):cryptlvm root=/dev/ArchLinux/root rw add_efi_memmap
END

printf "${cs}Installation successful${cn}\n"

# Dotfiles
printf "${ct}Post installation configuration${cn}\n"
printf "${cp}Download dotfiles installer [Y/n]: ${cn}"
read config_dotfiles

case "$config_dotfiles" in
	n|N)
		break
		;;
	*)
		confirm_dotfiles='true'
		;;
esac

if [ "$confirm_dotfiles" = 'true' ]; then

printf "${cs}Downloading dotfiles snapshot${cn}\n"
arch-chroot /mnt pacman -Sy --needed --noconfirm git
arch-chroot /mnt git clone https://github.com/filiparag/dotfiles /opt/dotfiles

printf "${cs}Linking installer script${cn}\n"
arch-chroot /mnt ln -s /opt/dotfiles/archlinux.sh /usr/bin/dotfiles-install

# printf "${cs}Installing dotfiles${cn}\n"
# arch-chroot /mnt su "${config_user}" -c /opt/dotfiles/archlinux.sh

# printf "${cs}Cleaning up dotfiles${cn}\n"
# arch-chroot /mnt rm -rf /opt/dotfiles

# printf "${cs}Dotfiles installation complete${cn}\n"

printf "${cw}To install dotfiles, run dotfiles-install when you log in${cn}\n"

fi

# Unmount
printf "${cs}Unmount filesystem${cn}\n"
umount -R /mnt
lvchange -an /dev/ArchLinux
cryptsetup close cryptlvm

printf "${ct}Exiting installer${cn}\n"

printf "${cw}Run reboot command and eject your installation media${cn}\n"