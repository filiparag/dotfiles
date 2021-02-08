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

logfile() {

	# Installation log file
	LOGFILE=$(mktemp /tmp/install-dotfiles.XXX.log)

}

build_tools() {

	print t 'Prepare system' && \

	# Install build tools
	print s 'Install build tools' && \
	sudo pacman -Sy --needed --noconfirm curl base-devel git git-lfs &>> "$LOGFILE" && \

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
	sudo tee -a /etc/pacman.conf &>> "$LOGFILE" << END

[filiparag]
SigLevel = Optional TrustAll
Server = https://pkg.filiparag.com/archlinux/
END

	# Update system
	print s 'Update system' && \
	sudo pacman -Syu --noconfirm &>> "$LOGFILE" && \

	# Install AUR helper
	{
		if ! command -v paru 1>/dev/null 2>/dev/null; then
			print s 'Install paru package manager' && \
			mkdir -p "$TMPDIR/paru-bin" &>> "$LOGFILE" && \
			cd "$TMPDIR/paru-bin" && \
			curl -L 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=paru-bin' 2>> "$LOGFILE" > "$TMPDIR/paru-bin/PKGBUILD" && \
			makepkg -si --noconfirm &>> "$LOGFILE"
		fi
	} && \

	# Install all required packages
	print s 'Install all required packages' && \
	paru -S --needed --noconfirm - < "$DOTFILEDIR/pkglist" &>> "$LOGFILE"

}

install_dotfiles() {

	# Prepare dotfiles
	print t 'Prepare dotfiles' && \
	if [ -e "$HOME/.sydf" ]; then
		yes | sydf unhook && \
		print s 'Remove old dotfiles' && \
		rm -rf "$HOME/.sydf"
	fi && \
	print s 'Copy dotfiles to home directory' && \
	cp -rp "$DOTFILEDIR" "$HOME/.sydf" &>> "$LOGFILE" && \
	sudo chown -R "$USER:$USER" "$HOME/.sydf" &>> "$LOGFILE" && \
	cd "$HOME/.sydf" && \
	print s 'Pull updates from upstream' && \
	git reset --hard origin/master &>> "$LOGFILE" && \
	git pull --rebase &>> "$LOGFILE" && \
	git lfs pull &>> "$LOGFILE" && \
	print s 'Initialize git submodules' && \
	git submodule update --init --recursive --depth 1 &>> "$LOGFILE" && \
	print s 'Configure sydf' && \
	mkdir -p "$HOME/.config" &>> "$LOGFILE" && \
	echo "$HOME/.sydf" > "$HOME/.config/sydf.conf" && \

	# Use current username instead of 'filiparag'
	{
		print s 'Replace hard coded username' && \
		if [ "$USER" != 'filiparag' ]; then
			mv "$HOME/.sydf/home/filiparag" "$HOME/.sydf/home/$USER" &>> "$LOGFILE" && \
			rg --hidden -i filiparag \
				-g '!.git' -g '!install-dotfiles.sh' -g '!install-system.sh' \
				-g '!README.md' -g '!LICENSE' -g '!pkglist' -g '!etc/pacman.d/mirrorlist' \
				-l "$HOME/.sydf" | xargs sed -i "s|filiparag|$USER|g" &>> "$LOGFILE"
		fi
	} && \

	# Replace provided mirrorlist with generated one
	print s 'Replace provided mirrorlist with generated one' && \
	sudo cp -f "$TMPDIR/mirrorlist" "$HOME/.sydf/etc/pacman.d/mirrorlist" &>> "$LOGFILE" && \

	# Hook dotfiles using sydf
	print t 'Install dotfiles' && \
	yes | sydf hook &>> "$LOGFILE"

}

wmrc_deps_and_services() {

	print t 'Post installation' && \

	# Install missing wmrc dependencies
	print s 'Install missing wmrc dependencies' && \
	wmrc -m | paru -S --needed --noconfirm --asdeps - &>> "$LOGFILE" && \

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

	# Reboot required
	print w 'Reboot your system to apply new settings.'

}

shortcuts_manual() {

	print s 'Regenerate shortcuts manual' && \
	cat "$DOTFILEDIR/home/filiparag/.config/sxhkd/sxhkdrc" | awk \
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
	}' > "$HOME/.sydf/SHORTCUTS.md"

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