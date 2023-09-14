# Disable fish greeting
set -x fish_greeting

# Colored terminal in tty

if [ "$TERM" = linux ]
    set SEDCMD 's/.*\*color\([0-9]\{1,\}\).*#\([0-9a-fA-F]\{6\}\).*/\1 \2/p'
    for i in (sed -n "$_SEDCMD" $HOME/.Xresources | awk '$1 < 16 {printf "\\e]P%X%s", $1, $2}')
        echo -en "$i"
    end
    clear
end

# OS-specific abbrevations

function __abbr_os_arch -d 'Package manager abbrevations for Arch Linux'

    if command -v paru &>/dev/null
        set pkgmgr paru
    else if command -v yay &>/dev/null
        set pkgmgr yay
    else
        set pkgmgr "$su_cmd"'pacman'
    end

    abbr --add ys "$pkgmgr -S" # Install package
    abbr --add yss "$pkgmgr -Ss" # Search repository
    abbr --add yf "$pkgmgr -F" # Find command provider
    abbr --add yi "$pkgmgr -Si" # Package info
    abbr --add y "$pkgmgr -Syu" # Update and upgrade
    abbr --add ya "$pkgmgr -Sua" # Upgrade AUR packages
    abbr --add yr "$pkgmgr -Rcsn" # Remove package
    abbr --add yc "$pkgmgr -Sc" # Clean cache

end

function __abbr_os_manjaro-arm -d 'Package manager abbrevations for Manjaro ARM'

    __abbr_os_arch

end

function __abbr_os_alpine -d 'Package manager abbrevations for Alpine Linux'

    set pkgmgr "$su_cmd"'apk'

    abbr --add ys "$pkgmgr add" # Install package
    abbr --add yss "$pkgmgr search" # Search repository
    abbr --add yi "$pkgmgr info" # Package info
    abbr --add y "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add yr "$pkgmgr del" # Remove package
    abbr --add yc "$pkgmgr cache clean" # Clean cache

end

function __abbr_os_freebsd -d 'Package manager abbrevations for FreeBSD'

    set pkgmgr "$su_cmd"'pkg'

    abbr --add ys "$pkgmgr install" # Install package
    abbr --add yss "$pkgmgr search" # Search repository
    abbr --add yi "$pkgmgr info" # Package info
    abbr --add y "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add ya "$sucmd"'portsnap auto' # Update ports tree
    abbr --add yr "$pkgmgr remove" # Remove package
    abbr --add yc "$pkgmgr clean" # Clean cache

end

function __abbr_os_debian -d 'Package manager abbrevations for Debian'

    set pkgmgr "$su_cmd"'apt'

    abbr --add ys "$pkgmgr install" # Install package
    abbr --add yss "$pkgmgr search" # Search repository
    abbr --add yi "$pkgmgr info" # Package info
    abbr --add y "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add yr "$pkgmgr purge" # Remove package
    abbr --add yc "$pkgmgr clean && $pkgmgr autoclean" # Clean cache

end

function __abbr_os_fedora -d 'Package manager abbrevations for Fedora'

    set pkgmgr "$su_cmd"'dnf'

    abbr --add ys "$pkgmgr install" # Install package
    abbr --add yss "$pkgmgr search" # Search repository
    abbr --add yi "$pkgmgr info" # Package info
    abbr --add y "$pkgmgr update && $pkgmgr upgrade" # Update and upgrade
    abbr --add yr "$pkgmgr remove" # Remove package
    abbr --add yc "$pkgmgr clean" # Clean cache

end

# Abbrevations

if status --is-interactive

    set -g fish_user_abbreviations

    alias dmenu 'rofi -dmenu'

    if [ (whoami) != root ]
        if command -v doas &>/dev/null
            set su_cmd 'doas '
        else if command -v sudo &>/dev/null
            set su_cmd 'sudo '
        end
    end

    alias __abbr_os_manjaro-arm __abbr_os_arch
    alias __abbr_os_manjaro __abbr_os_arch
    alias __abbr_os_ubuntu __abbr_os_debian

    set os (grep '^ID=' /etc/os-release | cut -d'=' -f2)
    eval "__abbr_os_$os"

    if test -f ~/.gitconfig && grep -q signingkey ~/.gitconfig
        set sign_upper ' -S'
        set sign_lower ' -s'
    else
        set sign_upper ''
        set sign_lower ''
    end

    abbr --add gs 'git status'
    abbr --add gsh 'git show'
    abbr --add ga 'git add'
    abbr --add gc "git commit$sign_upper -m"
    abbr --add gca "git commit$sign_upper --amend"
    abbr --add gl 'git log'
    abbr --add gp 'git push'
    abbr --add gpt 'git push --tags'
    abbr --add gpf 'git push --force'
    abbr --add gps 'git push --set-upstream origin' #(git rev-parse --abbrev-ref HEAD)
    abbr --add gcl 'git clone'
    abbr --add gcls 'git clone git@github.com:'
    abbr --add gclh 'git clone https://github.com/'
    abbr --add gt "git tag$sign_lower"
    abbr --add gw 'git whatchanged'
    abbr --add gm "git merge$sign_upper"
    abbr --add gpl 'git pull'
    abbr --add gplr 'git pull --rebase'
    abbr --add gco 'git checkout'
    abbr --add gb 'git branch'
    abbr --add gsw 'git switch'
    abbr --add gr 'git restore'
    abbr --add grb "git rebase --interactive --committer-date-is-author-date$sign_upper"

    abbr --add dce 'docker compose exec'
    abbr --add dcu 'docker compose up'
    abbr --add dcd 'docker compose down'
    abbr --add dcs 'docker compose stop'
    abbr --add dck 'docker compose kill'
    abbr --add dcr 'docker compose restart'
    abbr --add dcp 'docker compose pull'

end

# Wikiman widget

for widget in (
    find '/usr/share/wikiman/widgets/widget.fish' \
         '/usr/local/share/wikiman/widgets/widget.fish' -type f 2>/dev/null
)
    source "$widget" 2>/dev/null
    break
end

# List files

function l -d 'Simple pretty file list'
    lsd --classify --icon-theme unicode --oneline \
        --icon always --color always --group-dirs first $argv
end

function la -d 'Simple pretty file list (with hidden)'
    lsd --classify --almost-all --icon-theme unicode --oneline \
        --icon always --color always --group-dirs first $argv
end

function ll -d 'Detailed pretty file list'
    lsd --classify --long --almost-all --icon-theme unicode \
        --icon always --blocks name,size,permission,user,group,date \
        --color always --group-dirs first $argv
end

# History sync bind

function _history_sync -d 'Synchronise fish history'
    history merge
    # commandline -f repaint
end

bind \ch _history_sync
if bind -M insert >/dev/null 2>&1
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
if bind -M insert >/dev/null 2>&1
    bind -M insert \cr _history_widget
end

# Copy to clipboard bind

function _clipboard_widget -d 'Copy prompt content to clipboard'
    commandline -b | xclip -i -selection clipboard
end

bind \cb _clipboard_widget
if bind -M insert >/dev/null 2>&1
    bind -M insert \cr _clipboard_widget
end

# Execute as root bind

function _sudo_widget -d 'Append sudo to last or current command'
    set prompt (commandline -b)
    set last (history --max 1)
    if [ -z $prompt ]
        if [ -n $last ] && ! echo $last | grep -q '^sudo '
            commandline -r "sudo $last"
        else
            commandline -r "$last"
        end
    else
        if ! echo $prompt | grep -q '^sudo '
            commandline -r "sudo $prompt"
        end
    end
end

bind \ce _sudo_widget
if bind -M insert >/dev/null 2>&1
    bind -M insert \cr _sudo_widget
end
