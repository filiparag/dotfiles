# Start SSH agent
ssh_agent

# Start X at login
if status --is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" -eq 1
        exec startx -- -keeptty
    end
end
