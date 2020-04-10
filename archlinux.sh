#! /usr/bin/env bash
DIR="$(pwd)"
sudo pacman -S git
cd '/tmp'
git clone 'https://aur.archlinux.org/yay.git'
cd yay
makepkg -si
yay -S --needed - < "$DIR/pkglist"
cp -rp "$DIR" "$HOME/.sydf"
echo  chown -R "$USER:$USER" "$HOME/.sydf"
cd "$HOME/.sydf"
git submodule update --init --recursive
mkdir -p "$HOME/.config"
echo "$HOME/.sydf" > "$HOME/.config/sydf.conf"
sydf hook
sudo systemctl enable sshd
sudo systemctl enable NetworkManager
sudo systemctl enable "suspend@$USER"
sudo systemctl enable "syncthing@$USER"
sudo systemctl enable syncthing-resume
