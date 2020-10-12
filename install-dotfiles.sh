#!/bin/sh

# Dotfiles installation script for Arch Linux

cr="$(tput setaf 1)"
cg="$(tput setaf 2)"
cy="$(tput setaf 3)"
cm="$(tput setaf 5)"
sb="$(tput bold)"
sn="$(tput sgr0)"

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
		e|error)
			shift;
			printf "%s\n" "${sb}${cr}!!! $*${sn}"
			exit 1
			;;
		w|warning)
			shift;
			printf "%s\n" "${sb}${cy}::: $*${sn}"
			;;
		*)
			printf '%s\n' "$*"
			;;
	esac
}

check_sudo() {

	# Check if user can sudo
	sudo -v || \
	print e 'Insufficient privileges'

}

workdir() {

	# Working and scratch directory
	DOTFILEDIR="$(realpath "$(dirname "$(readlink -f "$0")")")" && \
	TMPDIR="$(mktemp -d)"

}

build_tools() {

	print t 'Prepare system' && \

	# Install build tools
	print s 'Install build tools' && \
	sudo pacman -Sy --needed --noconfirm curl base-devel && \

	# Generate new mirrorlist
	print s 'Generate new mirrorlist' && \
	curl -L 'https://www.archlinux.org/mirrorlist/?country=AT&country=DE&country=HU&country=RO&country=RS&country=SI&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' | sed 's|#Server|Server|' > "$TMPDIR/mirrorlist" && \
	sudo cp -f "$TMPDIR/mirrorlist" "/etc/pacman.d/mirrorlist" && \

	# Use all cores in makepkg.conf 
	print s 'Use all cores in makepkg.conf' && \
	sudo sed 's/[ \t#]*MAKEFLAGS.*$/MAKEFLAGS="-j$(nproc)"/' -i /etc/makepkg.conf
}

install_packages() {

	# Update system
	print s 'Update system' && \
	sudo pacman -Syu --noconfirm && \

	# Install yay
	{
		if ! command -v yay 1>/dev/null 2>/dev/null; then
			print s 'Install yay package manager' && \
			mkdir -p "$TMPDIR/yay" && \
			cd "$TMPDIR/yay" && \
			curl -L 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay' > "$TMPDIR/yay/PKGBUILD" && \
			makepkg -si
		fi
	} && \

	# Install all required packages
	print s 'Install all required packages' && \
	yay -S --needed --noconfirm - < "$DOTFILEDIR/pkglist"

}

install_dotfiles() {

	# Prepare dotfiles
	print t 'Prepare dotfiles' && \
	print s 'Copy dotfiles to home directory' && \
	cp -rp "$DOTFILEDIR" "$HOME/.sydf" && \
	sudo chown -R "$USER:$USER" "$HOME/.sydf" && \
	cd "$HOME/.sydf" && \
	print s 'Pull updates from upstream' && \
	git fetch --all && \
	git reset --hard origin/master && \
	print s 'Initialize git submodules' && \
	git submodule update --init --recursive && \
	print s 'Configure sydf' && \
	mkdir -p "$HOME/.config" && \
	echo "$HOME/.sydf" > "$HOME/.config/sydf.conf" && \

	# Use current username instead of 'filiparag'
	{
		print s 'Replace hard coded username' && \
		if [ "$USER" != 'filiparag' ]; then
			mv "$HOME/.sydf/home/filiparag" "$HOME/.sydf/home/$USER" && \
			rg --hidden -i filiparag \
				-g '!.git' -g '!install-dotfiles.sh' -g '!install-system.sh' \
				-g '!README.md' -g '!LICENSE' -g '!pkglist' \
				-l "$HOME/.sydf" | xargs sed -i "s|filiparag|$USER|g"
		fi
	} && \

	# Download wallpaper
	print s 'Download wallpaper and lockscreen' && \
	mkdir -p "$HOME/.sydf/home/$USER/Pictures" && \
	curl -L 'http://ftp.parag.rs/wallpaper-day.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-day.png" && \
	curl -L 'http://ftp.parag.rs/wallpaper-night.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" && \
	cp -p "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" "$HOME/.sydf/home/$USER/Pictures/lockscreen.png" && \

	# Replace provided mirrorlist with generated one
	print s 'Replace provided mirrorlist with generated one' && \
	sudo cp -f "$TMPDIR/mirrorlist" "$HOME/.sydf/etc/pacman.d/mirrorlist" && \

	# Hook dotfiles using sydf
	print t 'Install dotfiles' && \
	yes | sydf hook

}

wmrc_deps_and_services() {

	print t 'Post installation' && \

	# Install missing wmrc dependencies
	print s 'Install missing wmrc dependencies' && \
	wmrc -m | yay -S --needed --noconfirm - && \

	# Enable services
	print s 'Enable systemd services' && \
	sudo systemctl enable "sshd" && \
	sudo systemctl enable "cronie" && \
	sudo systemctl enable "NetworkManager" && \
	sudo systemctl enable "suspend@$USER" && \
	sudo systemctl enable "syncthing@$USER" && \
	sudo systemctl enable "syncthing-resume" && \
	sudo systemctl enable "systemd-resolved" && \
	sudo systemctl enable "ufw" && \

	# Firewall
	print s 'Enable firewall' && \
	sudo ufw default deny incoming && \
	sudo ufw default allow outgoing && \
	sudo ufw allow ssh && \
	sudo ufw allow syncthing && \
	sudo ufw enable && \

	# Use fish as default shell
	print s 'Configure fish shell' && \
	chsh -s /usr/bin/fish && \

	# Clear fish greeting
	fish -c 'set fish_greeting ""'

}

cleanup_finish() {

	print t 'Cleanup' && \

	# Remove temporary files
	print s 'Remove temporary files' && \
	rm -rf "$TMPDIR" && \

	print t 'Installation complete' && \

	# Hardware-specific modifications
	if ! lspci | grep -qi 'vga.*amd'; then
		print w 'Make sure files in /etc/X11/xorg.conf.d/ are compatible with your hardware!'
	fi && \

	# Reboot required
	print w 'Reboot your system to apply new settings.'

}

shortcuts_manual() {

	print s 'Regenerate shortcuts manual' && \
	cat "$DOTFILEDIR/home/filiparag/.config/sxhkd/sxhkdrc" | awk 'NR > 1 {
		if ($0 ~ /^## /) {
			gsub(/^## */,"",$0); printf("\n### %s\n\n",$0)
		} else if ($0 ~ /^# /) {
			gsub(/^# */,"",$0); printf("%s ",$0); c=1
		} else if (c==1) {
			printf("`%s`\n\n", $0); c=0
		}
	}' > "$HOME/.sydf/SHORTCUTS.md"

}

check_sudo && workdir && build_tools && install_packages && \
install_dotfiles && wmrc_deps_and_services && \
shortcuts_manual && cleanup_finish || print e 'Fatal error, halting installation!'

exit