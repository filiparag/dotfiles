# Start SSH agent
ssh_agent



function __graphical_environments
    set -l envs bspwm gnome-shell
    set -l ens tty
    for e in $envs
        if command -v $e &>/dev/null
            set ens (string join "\n" $ens $e)
        end
    end
    eval __graphical_environment_(
        printf $ens | fzf --layout reverse-list --no-sort
    )
end

function __graphical_environment_tty
    clear
end

function __graphical_environment_bspwm
    exec startx -- -keeptty
end

function __graphical_environment_gnome-shell
    MOZ_ENABLE_WAYLAND=1 QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland exec gnome-shell --wayland
end

# Start X at login
if status --is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" -eq 1
        # exec startx -- -keeptty
        __graphical_environments
    end
end
