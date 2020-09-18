#!/bin/sh

# Installation script for Arch Linux

# Working and scratch directory
DIR="$(dirname "$0")"
TMPDIR="$(mktemp -d)"

# Update system
sudo pacman -Syu

# Install yay
mkdir -p "$TMPDIR/yay"
cd "$TMPDIR/yay"
GET 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay' > PKGBUILD
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
GET 'http://ftp.parag.rs/wallpaper-day.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-day.png"
GET 'http://ftp.parag.rs/wallpaper-night.png' > "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png"
cp -p "$HOME/.sydf/home/$USER/Pictures/wallpaper-night.png" "$HOME/.sydf/home/$USER/Pictures/lockscreen.png"

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
