#!/bin/sh

# Installation script for Arch Linux

check_sudo() {

	# Check if user can sudo
	sudo -v

}

workdir() {

	# Working and scratch directory
	DIR="$(realpath "$(dirname "$0")")" &&\
	TMPDIR="$(mktemp -d)"

}

build_tools() {

	# Install build tools
	sudo pacman -Sy --needed curl base-devel &&\

	# Generate new mirrorlist
	curl -L 'https://www.archlinux.org/mirrorlist/?country=AT&country=DE&country=HU&country=RO&country=RS&country=SI&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' | sed 's|#Server|Server|' > "$TMPDIR/mirrorlist" &&\
	sudo cp -f "$TMPDIR/mirrorlist" "/etc/pacman.d/mirrorlist" &&\

	# Use all cores in makepkg.conf 
	sudo sed 's/[ \t#]*MAKEFLAGS.*$/MAKEFLAGS="-j$(nproc)"/' -i /etc/makepkg.conf
}

install_packages() {

	# Update system
	sudo pacman -Syu &&\

	# Install yay
	{
		if ! command -v yay 1>/dev/null 2>/dev/null; then
			mkdir -p "$TMPDIR/yay" &&\
			cd "$TMPDIR/yay" &&\
			curl -L 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay' > "$TMPDIR/yay/PKGBUILD" &&\
			makepkg -si
		fi
	} &&\

	# Install all required packages
	yay -S --needed - < "$DIR/pkglist"

}

install_dotfiles() {

	# Prepare dotfiles
	cp -rp "$DIR" "$HOME/.sydf" &&\
	sudo chown -R "$USER:$USER" "$HOME/.sydf" &&\
	cd "$HOME/.sydf" &&\
	git submodule update --init --recursive &&\
	mkdir -p "$HOME/.config" &&\
	echo "$HOME/.sydf" > "$HOME/.config/sydf.conf" &&\

	# Use current username instead of 'filiparag'
	{
		if [ "$USER" != 'filiparag' ]; then
			mv "$HOME/.sydf/home/filiparag" "$HOME/.sydf/home/$USER" &&\
			rg --hidden -i filiparag -g '!.git' -g '!archlinux.sh' -l "$HOME/.sydf" | xargs sed -i "s|filiparag|$USER|g"
		fi
	} &&\

	# Download wallpaper
	mkdir -p "$HOME/.sydf/home/$USER/Pictures" &&\
	curl -L 'http://ftp.parag.rs/wallpaper-day.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-day.png" &&\
	curl -L 'http://ftp.parag.rs/wallpaper-night.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" &&\
	cp -p "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" "$HOME/.sydf/home/$USER/Pictures/lockscreen.png" &&\

	# Replace provided mirrorlist with generated one
	sudo cp -f "$TMPDIR/mirrorlist" "/etc/pacman.d/mirrorlist" &&\

	# Hook dotfiles using sydf
	sydf hook

}

wmrc_deps_and_services() {

	# Install missing wmrc dependencies
	wmrc -m | yay -S --needed - &&\

	# Enable services
	sudo systemctl enable "sshd" &&\
	sudo systemctl enable "cronie" &&\
	sudo systemctl enable "NetworkManager" &&\
	sudo systemctl enable "suspend@$USER" &&\
	sudo systemctl enable "syncthing@$USER" &&\
	sudo systemctl enable "syncthing-resume" &&\
	sudo systemctl enable "systemd-resolved" &&\
	sudo systemctl enable "ufw" &&\

	# Firewall
	sudo ufw default deny incoming &&\
	sudo ufw default allow outgoing &&\
	sudo ufw allow ssh &&\
	sudo ufw enable

}

finish_cleanup() {

	# use fish as default shell
	chsh -s /usr/bin/fish &&\

	# clear fish greeting
	fish -c 'set fish_greeting ""' &&\

	# Remove temporary files
	rm -rf "$TMPDIR"

}

shortcuts_manual() {

	cat "$DIR/home/filiparag/.config/sxhkd/sxhkdrc" | awk 'NR > 1 {
		if ($0 ~ /^## /) {
			gsub(/^## */,"",$0); printf("\n### %s\n\n",$0)
		} else if ($0 ~ /^# /) {
			gsub(/^# */,"",$0); printf("%s ",$0); c=1
		} else if (c==1) {
			printf("`%s`\n\n", $0); c=0
		}
	}' > "$HOME/.sydf/SHORTCUTS.md"

}

check_sudo && workdir && build_tools && install_packages && install_dotfiles && wmrc_deps_and_services && finish_cleanup && shortcuts_manual
