#!/bin/sh

# Installation script for Arch Linux

# Working and scratch directory
DIR="$(dirname "$0")"
TMPDIR="$(mktemp -d)"

# Install curl
sudo pacman -Sy --needed curl

# Generate new mirrorlist
curl -L 'https://www.archlinux.org/mirrorlist/?country=AT&country=DE&country=HU&country=RO&country=RS&country=SI&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' | sed 's|#Server|Server|' > "$TMPDIR/mirrorlist"
sudo cp -f "$TMPDIR/mirrorlist" "/etc/pacman.d/mirrorlist"

# Update system
sudo pacman -Syu

# Install yay
mkdir -p "$TMPDIR/yay"
cd "$TMPDIR/yay"
curl -L 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay' > "$TMPDIR/yay/PKGBUILD"
makepkg -si

# Install all required packages
yay -S --needed - < "$DIR/pkglist"

# Use current username instead of 'filiparag'
mv "$DIR/home/filiparag" "$DIR/home/$USER"
rg --hidden -i filiparag -g '!.git' -g '!archlinux.sh' -l | xargs sed -i "s|filiparag|$USER|g"

# Prepare dotfiles
cp -rp "$DIR" "$HOME/.sydf"
chown -R "$USER:$USER" "$HOME/.sydf"
cd "$HOME/.sydf"
git submodule update --init --recursive
mkdir -p "$HOME/.config"
echo "$HOME/.sydf" > "$HOME/.config/sydf.conf"

# Download wallpaper
mkdir -p "$HOME/.sydf/home/$USER/Pictures"
curl -L 'http://ftp.parag.rs/wallpaper-day.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-day.png"
curl -L 'http://ftp.parag.rs/wallpaper-night.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png"
cp -p "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" "$HOME/.sydf/home/$USER/Pictures/lockscreen.png"

# Replace provided mirrorlist with generated one
cp -f "$TMPDIR/mirrorlist" "$DIR/etc/pacman.d/mirrorlist"

# Hook dotfiles using sydf
sydf hook

# Install missing wmrc dependencies
wmrc -m | yay -S --needed -

# Enable services
sudo systemctl enable "sshd"
sudo systemctl enable "cronie"
sudo systemctl enable "NetworkManager"
sudo systemctl enable "suspend@$USER"
sudo systemctl enable "syncthing@$USER"
sudo systemctl enable "syncthing-resume"
sudo systemctl enable "systemd-resolved"

# Remove temporary files
rm -rf "$TMPDIR"
