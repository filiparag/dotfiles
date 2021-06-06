# Disable fish greeting
set -x fish_greeting

# Colored terminal in tty

if [ "$TERM" = "linux" ]
    set SEDCMD 's/.*\*color\([0-9]\{1,\}\).*#\([0-9a-fA-F]\{6\}\).*/\1 \2/p'
    for i in (sed -n "$_SEDCMD" $HOME/.Xresources | awk '$1 < 16 {printf "\\e]P%X%s", $1, $2}')
        echo -en "$i"
    end
    clear
end

# OS-specific abbrevations

function __abbr_os_arch -d 'Package manager abbrevations for Arch Linux'

    if command -v 'paru' &>/dev/null;
        set pkgmgr 'paru'
    else if command -v 'yay' &>/dev/null;
        set pkgmgr 'yay'
    else
        set pkgmgr "$su_cmd"'pacman'
    end

    abbr --add ys   "$pkgmgr -S"    # Install package
    abbr --add yss  "$pkgmgr -Ss"   # Search repository
    abbr --add yqs  "$pkgmgr -Ss"   # Search local
    abbr --add yi   "$pkgmgr -Syu"  # Package info
    abbr --add y    "$pkgmgr -Syu"  # Update and upgrade
    abbr --add ya   "$pkgmgr -Sua"  # Upgrade AUR packages
    abbr --add yr   "$pkgmgr -Rcsn" # Remove package
    abbr --add yc   "$pkgmgr -Sc"   # Clean cache

end

function __abbr_os_alpine -d 'Package manager abbrevations for Alpine Linux'

    set pkgmgr "$su_cmd"'apk'

    abbr --add ys   "$pkgmgr add"                       # Install package
    abbr --add yss  "$pkgmgr search"                    # Search repository
    abbr --add yi   "$pkgmgr info"                      # Package info
    abbr --add y    "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add yr   "$pkgmgr del"                       # Remove package
    abbr --add yc   "$pkgmgr cache clean"               # Clean cache

end

function __abbr_os_freebsd -d 'Package manager abbrevations for FreeBSD'

    set pkgmgr "$su_cmd"'pkg'

    abbr --add ys   "$pkgmgr install"                   # Install package
    abbr --add yss  "$pkgmgr search"                    # Search repository
    abbr --add yi   "$pkgmgr info"                      # Package info
    abbr --add y    "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add ya   "$sucmd"'portsnap auto'             # Update ports tree
    abbr --add yr   "$pkgmgr remove"                    # Remove package
    abbr --add yc   "$pkgmgr clean"                     # Clean cache

end

function __abbr_os_debian -d 'Package manager abbrevations for Debian'

    set pkgmgr "$su_cmd"'apt'

    abbr --add ys   "$pkgmgr install"                       # Install package
    abbr --add yss  "$pkgmgr search"                        # Search repository
    abbr --add yi   "$pkgmgr info"                          # Package info
    abbr --add y    "$pkgmgr update && $pkgmgr upgrade"     # Update and upgrade
    abbr --add yr   "$pkgmgr purge"                         # Remove package
    abbr --add yc   "$pkgmgr clean && $pkgmgr autoclean"    # Clean cache

end

# Abbrevations

if status --is-interactive

    set -g fish_user_abbreviations
    
    alias dmenu         'rofi -dmenu'

    if [ (whoami) != 'root' ];
        if command -v 'doas' &>/dev/null;
            set su_cmd 'doas '
        else if command -v 'sudo' &>/dev/null;
            set su_cmd 'sudo '
        end
    end

    alias __abbr_os_manjaro __abbr_os_arch
    alias __abbr_os_ubuntu  __abbr_os_arch
    set os (grep '^ID=' /etc/os-release | cut -d'=' -f2)
    eval "__abbr_os_$os"

    abbr --add gs       'git status'
    abbr --add gsh      'git show'
    abbr --add ga       'git add'
    abbr --add gc       'git commit -S -m'
    abbr --add gca      'git commit -S --amend'
    abbr --add gl       'git log'
    abbr --add gp       'git push'
    abbr --add gpt      'git push --tags'
    abbr --add gpf      'git push --force'
    abbr --add gcl      'git clone'
    abbr --add gcls     'git clone git@github.com:'
    abbr --add gclh     'git clone https://github.com/'
    abbr --add gt       'git tag'
    abbr --add gw       'git whatchanged'

    abbr --add r        'cd /'
    abbr --add h        'cd ~'

    abbr --add v        'vim'
    abbr --add b        'bat'
    abbr --add ht       'htop'
    abbr --add s        'ssh'
    abbr --add sr       'ssh root@'

end

# Wikiman widget

for widget in (
    find '/usr/share/wikiman/widgets/widget.fish' \
         '/usr/local/share/wikiman/widgets/widget.fish' -type f 2>/dev/null
);
    source "$widget" 2>/dev/null
    break
end

# List files

function l -d 'Simple pretty file list'
    lsd --classify --icon-theme unicode --oneline \
        --icon always --color always --date --group-dirs first $argv
end

function la -d 'Simple pretty file list (with hidden)'
    lsd --classify --almost-all --icon-theme unicode --oneline \
        --icon always --color always --date --group-dirs first $argv
end

function ll -d 'Detailed pretty file list'
    lsd --classify --long --almost-all --icon-theme unicode \
        --icon always --blocks name,size,permission,user,group,date \
        --color always --date --group-dirs first $argv
end

# NNN File manager bind

bind \cn nnn
if bind -M insert > /dev/null 2>&1
  bind -M insert \cn nnn
end

# History sync bind

function _history_sync -d 'Synchronise fish history'
    history merge
    # commandline -f repaint
end

bind \ch _history_sync
if bind -M insert > /dev/null 2>&1
  bind -M insert \ch _history_sync
end

# History search widget bind

function _history_widget -d 'Show interactive fish history'
    history merge
    set selected (history | fzf --query (commandline -b) --cycle --height (math -s0 (tput lines) / 3))
    if [ $status -eq 0 ]
        commandline -i $selected
    end
    commandline -f repaint
end

bind \cr _history_widget
if bind -M insert > /dev/null 2>&1
  bind -M insert \cr _history_widget
end
