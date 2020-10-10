## Prerequisites

To install these dotfiles using [`archlinux.sh`](./archlinux.sh), you should have:

- [base Arch Linux](https://wiki.archlinux.org/index.php/Installation_guide) installed
- at least 8 GiB of free space on root partition
- user account with [`sudo`](https://wiki.archlinux.org/index.php/Sudo#Example_entries) privileges
- access to the internet

### System install script

Opinionated automatic [install script](./install.sh) for base Arch Linux is also provided.
To use it, boot into [live installation system](https://www.archlinux.org/download/) and run following commands:
```bash
curl -LO 'https://raw.githubusercontent.com/filiparag/dotfiles/master/install.sh'
sh install.sh
```
Follow colored instructions from the script and skip to [Hardware-specific modifications](#hardware-specific-modifications).

## Installation

```bash
# Clone dotfiles repository
git clone https://github.com/filiparag/dotfiles.git /tmp/dotfiles

# Run semi-automatic installer
/tmp/dotfiles/archlinux.sh

# Hardware-specific commands go here

# Reboot your system to apply all updates
sudo systemctl reboot
```

Username `filiparag` will be replaced with your username.


### Hardware-specific modifications

If you are not using a newer AMD GPU:

- install appropriate [`xf86-video-`](https://wiki.archlinux.org/index.php?title=Xorg#Driver_installation) driver
- make sure files in [`/etc/X11/xorg.conf.d/`](./etc/X11/xorg.conf.d/) are compatible with your hardware


## Customization

User-specific environment variables: [`~/.config/fish/conf.d/user.fish`](./home/filiparag/.config/fish/conf.d/user.fish)

Git configuration: [`~/.gitconfig`](./home/filiparag/.gitconfig)

Window manager configuration ([wmrc](https://github.com/filiparag/wmrc/)): [`~/.config/wmrc/rc.conf`](./home/filiparag/.config/wmrc/rc.conf)

Shortcut configuration is in [`~/.config/sxhkd/sxhkdrc`](./home/filiparag/.config/sxhkd/sxhkdrc)

Shortcuts manual: [`~/.sydf/SHORTCUTS.md`](./SHORTCUTS.md)

Startup applications are listed in `APPS` variable in [`~/.config/wmrc/modules/services/apps`](./home/filiparag/.config/wmrc/modules/services/apps)

Wallpaper and lockscreen images are located in `~/Pictures` directory

To change default monitor setup, create desired layout using `arandr` and save it as `~/.screenlayout/Default.sh`

To enable VNC server, run:

``` bash
# Set VNC password
vncpasswd

# Allow incoming VNC connections
sudo ufw allow in 5900/tcp

# Restart wmrc VNC module
wmrc -r 'services/vnc(start)'
```