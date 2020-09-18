## Prerequisites

To install these dotfiles using `archlinux.sh`, you should have:

- base Arch Linux installed
- at least 8 GiB of free space on root partition
- user account with `sudo` privileges
- access to the internet


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

### Hardware-specific modifications

If you are not using a newer AMD GPU:

- install appropriate `xf86-video-` driver
- make sure files in `/etc/X11/xorg.conf.d/` are compatible with you hardware


## Customization

User-specific environment variables: `~/.config/fish/conf.d/user.fish`

Window manager configuration: `~/.config/wmrc/rc.conf`

Shortcut configuration is in `~/.config/sxhkd/sxhkdrc`

Shortcuts manual: [`~/.sydf/SHORTCUTS.md`](./SHORTCUTS.md)

Startup applications are listed in `APPS` variable in `~/.config/wmrc/modules/services/apps`

Wallpaper and lockscreen are located in `~/Pictures` directory

To enable VNC server, run:

``` bash
# Set VNC password
vncpasswd

# Allow incoming VNC connections
sudo ufw allow in 5900/tcp

# Restart wmrc VNC module
wmrc -r 'services/vnc(restart)'
```