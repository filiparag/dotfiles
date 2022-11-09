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
	DOTFILEDIR="$(realpath "$(dirname "$(dirname "$(readlink -f "$0")")")")" && \
	TMPDIR="$(mktemp -d)"

}

logfile() {

	# Installation log file
	LOGFILE=$(mktemp /tmp/install-dotfiles.XXX.log)

}

build_tools() {

	print t 'Prepare system' && \

	# Install build tools
	print s 'Install build tools' && \
	sudo pacman -Sy --needed --noconfirm curl base-devel git git-lfs ripgrep &>> "$LOGFILE" && \

	# Generate new mirrorlist
	print s 'Generate new mirrorlist' && \
	curl -L 'https://www.archlinux.org/mirrorlist/?country=AT&country=DE&country=HU&country=RO&country=RS&country=SI&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' 2>> "$LOGFILE" | sed 's|#Server|Server|' > "$TMPDIR/mirrorlist" && \
	sudo cp -f "$TMPDIR/mirrorlist" "/etc/pacman.d/mirrorlist" &>> "$LOGFILE" && \

	# Use all cores in makepkg.conf 
	print s 'Use all cores in makepkg.conf' && \
	sudo sed 's/[ \t#]*MAKEFLAGS.*$/MAKEFLAGS="-j$(nproc)"/' -i /etc/makepkg.conf &>> "$LOGFILE"

}

install_packages() {

	# Add additional repositories
	print s 'Add additional repositories' && \
	if ! grep -q dovla /etc/pacman.conf; then
		sudo tee -a /etc/pacman.conf &>> "$LOGFILE" << END

[dovla]
SigLevel = Optional TrustAll
Server = https://pkg.dovla.com/archlinux/
END
	fi && \

	# Update system
	print s 'Update system' && \
	sudo pacman -Syu --noconfirm &>> "$LOGFILE" && \

	# Install AUR helper
	sudo pacman -S --needed --noconfirm paru-bin &>> "$LOGFILE" && \

	# Install all required packages
	print s 'Install all required packages' && \
	paru -S --needed --noconfirm - < "$DOTFILEDIR/pkglist.txt" &>> "$LOGFILE"

}

install_dotfiles() {

	# Prepare dotfiles
	print t 'Prepare dotfiles' && \
	if [ -e "$HOME/.dotfiles" ]; then
		print s 'Remove old dotfiles' && \
		rm -rf "$HOME/.dotfiles"
	fi && \
	print s 'Copy dotfiles to home directory' && \
	cp -rp "$DOTFILEDIR" "$HOME/.dotfiles" &>> "$LOGFILE" && \
	sudo chown -R "$USER:$USER" "$HOME/.dotfiles" &>> "$LOGFILE" && \
	cd "$HOME/.dotfiles" && \
	print s 'Pull updates from upstream' && \
	git lfs install &>> "$LOGFILE" && \
	git reset --hard origin/master &>> "$LOGFILE" && \
	git pull --rebase &>> "$LOGFILE" && \
	git lfs pull &>> "$LOGFILE" && \
	print s 'Initialize git submodules' && \
	git submodule update --init --recursive --depth 1 &>> "$LOGFILE" && \

	# Use current username instead of 'dovla'
	{
		print s 'Replace hard coded username' && \
		if [ "$USER" != 'dovla' ]; then
			rg --hidden -i dovla -g '!src/etc/pacman.conf' \
				-l "$HOME/.dotfiles/src" | xargs sed -i "s|dovla|$USER|g" &>> "$LOGFILE"
		fi
	} && \

	# Replace provided mirrorlist with generated one
	print s 'Replace provided mirrorlist with generated one' && \
	sudo cp -f "$TMPDIR/mirrorlist" "$HOME/.dotfiles/src/etc/pacman.d/mirrorlist" &>> "$LOGFILE" && \

	# Package dotfiles
	print s 'Package dotfiles in fakeroot' && \
	make clean symlink &>> "$LOGFILE"  && \

	# Backup conflicting files
	print s 'Backup conflicting files' && \
	make backup &>> "$LOGFILE"

	# Install dotfiles
	print t 'Install dotfiles' && \
	print s 'Extract dotfiles' && \
	sudo make install &>> "$LOGFILE"

}

wmrc_deps_and_services() {

	print t 'Post installation' && \

	# Install missing wmrc dependencies
	if [ "$(wmrc -m)" != '' ]; then
		print s 'Install missing wmrc dependencies' && \
		wmrc -m | paru -S --needed --noconfirm --asdeps - &>> "$LOGFILE"
	fi && \

	# Enable services
	print s 'Enable systemd services' && \
	sudo systemctl enable "sshd" &>> "$LOGFILE" && \
	sudo systemctl enable "cronie" &>> "$LOGFILE" && \
	sudo systemctl enable "NetworkManager" &>> "$LOGFILE" && \
	sudo systemctl enable "suspend@$USER" &>> "$LOGFILE" && \
	sudo systemctl enable "syncthing@$USER" &>> "$LOGFILE" && \
	sudo systemctl enable "syncthing-resume" &>> "$LOGFILE" && \
	sudo systemctl enable "systemd-resolved" &>> "$LOGFILE" && \
	sudo systemctl enable "ufw" &>> "$LOGFILE" && \

	# Firewall
	print s 'Enable firewall' && \
	sudo ufw default deny incoming &>> "$LOGFILE" && \
	sudo ufw default allow outgoing &>> "$LOGFILE" && \
	sudo ufw allow ssh &>> "$LOGFILE" && \
	sudo ufw allow syncthing &>> "$LOGFILE" && \
	sudo ufw enable &>> "$LOGFILE" && \

	# Use fish as default shell
	print s 'Configure fish shell' && \
	sudo chsh -s /usr/bin/fish "$USER" &>> "$LOGFILE" && \

	# Clear fish greeting
	fish -c 'set fish_greeting ""' &>> "$LOGFILE"

}

cleanup_finish() {

	print t 'Cleanup' && \

	print s 'Clean up dotfiles working directory' && \
	cd "$HOME/.dotfiles" && \
	make clean &>> "$LOGFILE" && \

	# Remove unwanted hardware-specific configuration
	print s 'Remove unwanted hardware-specific configuration' && \
	if ! lspci | grep -qi 'vga.*amd'; then
		sudo rm -f /etc/X11/xorg.conf.d/20-amdgpu.conf &>> "$LOGFILE"
	fi && \
	if ! lspci | grep -qi 'vga.*intel'; then
		sudo rm -f /etc/X11/xorg.conf.d/20-intel.conf &>> "$LOGFILE"
	fi && \

	# Remove temporary files
	print s 'Remove temporary files' && \
	rm -rf "$TMPDIR" &>> "$LOGFILE" && \

	print t 'Installation complete' && \

	# Configure user identity
	cd "$HOME/.dotfiles" && \
	print w 'Enter your credentials in the these files:'
	rg --hidden -i filip -g '!src/etc/pacman.conf' -l "$HOME/.dotfiles/src" | \
		sed "s:$HOME/.dotfiles/src::; s:/HOME/:~/:"

	# Reboot required
	print w 'Reboot your system to apply new settings.'

}

shortcuts_manual() {

	print s 'Regenerate shortcuts manual' && \
	cat "$DOTFILEDIR/src/HOME/.config/sxhkd/sxhkdrc" | awk \
	'BEGIN {
		print "# Keyboard shortcuts\n"
	}
	NR > 1 {
		if ($0 ~ /^## /) {
			gsub(/^## */,"",$0); printf("\n## %s\n\n",$0)
		} else if ($0 ~ /^# /) {
			gsub(/^# */,"",$0); printf("%s ",$0); c=1
		} else if (c==1) {
			printf("`%s`\n\n", $0); c=0
		}
	}' > "$HOME/.dotfiles/SHORTCUTS.md"

}

if [ "$#" -gt 0 ]; then
	args=""
	for arg in $@; do
		args="${args:+$args && } $arg"
	done
	check_sudo && workdir && logfile && eval "$args" && cleanup_finish || {
		print w "Log file: ${sn}${sb}$LOGFILE"
		print e 'Fatal error, halting installation!'
	}
	exit
fi

check_sudo && workdir && logfile && build_tools && install_packages && \
install_dotfiles && wmrc_deps_and_services && \
shortcuts_manual && cleanup_finish || {
	print w "Log file: ${sn}${sb}$LOGFILE"
	print e 'Fatal error, halting installation!'
}

exit