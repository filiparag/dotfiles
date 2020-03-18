# Abbrevations
if status --is-interactive

    set -g fish_user_abbreviations

    alias l             "ls -lhoG --color=always --time-style='+' | sed -re 's/^[^ ]* //'"
    alias ll            "lsd --icon never -al"
    alias subl          "subl3"

    abbr --add ys       'yay -S'
    abbr --add yss      'yay -Ss'    abbr --add yr       'yay -Rcs'

    # abbr --add badger   'ssh -J serveo.net badger'
    # abbr --add lapwing  'ssh -J serveo.net lapwing'
    # abbr --add tapir    'ssh -J serveo.net tapir'
    # abbr --add akita    'ssh -J serveo.net akita'

    abbr --add led      'sudo bash -c "echo \'0 off\' > /proc/acpi/ibm/led"'

end

if [ "$TERM" = "linux" ]
    set SEDCMD 's/.*\*color\([0-9]\{1,\}\).*#\([0-9a-fA-F]\{6\}\).*/\1 \2/p'
    for i in (sed -n "$_SEDCMD" $HOME/.Xresources | awk '$1 < 16 {printf "\\e]P%X%s", $1, $2}')
        echo -en "$i"
    end
    clear
end

set -x QT_QPA_PLATFORMTHEME "qt5ct"
set -x QT_AUTO_SCREEN_SCALE_FACTOR 0

set -x FZF_LEGACY_KEYBINDINGS 0

set -x NAME     "Filip Parag"
set -x EMAIL    "filiparag@protonmail.com"
set -x EDITOR   "vim"
set -x BROWSER  "firefox"

set -x HOSTNAME (hostname)

#set -x tmate-api-key        "tmk-ctvk0CVzza02ZvF7w6pGHvrOac"

#  Go path
set -x GOPATH   $HOME/Projects/go
set -x PATH     "$PATH:$GOPATH/bin"
# set -x GOROOT   $HOME/Projects/golang

set -x PATH     "$PATH:$HOME/.local/bin"

# sydf
set -x SYDF "$HOME/.sydf_devel"

# IntelliJ
set -x _JAVA_AWT_WM_NONREPARENTING 1
set -x _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'

setenv SSH_ENV $HOME/.ssh_environment

function start_agent                                                                                                                                                                    
    ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
    chmod 600 $SSH_ENV 
    . $SSH_ENV > /dev/null
    ssh-add
    ssh-add "$HOME/.ssh/$HOSTNAME/$HOSTNAME.private"
    ssh-add "$HOME/.ssh/mulberry/mulberry.private"
end

function test_identities                                                                                                                                                                
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $status -eq 0 ]
        ssh-add
        ssh-add "$HOME/.ssh/$HOSTNAME/$HOSTNAME.private"
	    ssh-add "$HOME/.ssh/mulberry/mulberry.private"
        if [ $status -eq 2 ]
            start_agent
        end
    end
end

function prompt_agent
    if [ -n "$SSH_AGENT_PID" ] 
        ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
        if [ $status -eq 0 ]
            test_identities
        end  
    else
        if [ -f $SSH_ENV ]
            . $SSH_ENV > /dev/null
        end  
        ps -ef | grep $SSH_AGENT_PID | grep -v grep | grep ssh-agent > /dev/null
        if [ $status -eq 0 ]
            test_identities
        else 
            start_agent
        end  
    end
end

# Start X at login
if status --is-login
  if test -z "$DISPLAY" -a "$XDG_VTNR" -eq 1
    exec startx -- -keeptty
  end
else
    prompt_agent
end

# Remote
# autossh -M 10000 serveo.net -R $HOSTNAME.filiparag.com:80:localhost:80 -C -f
# autossh -M 20000 serveo.net -R $HOSTNAME:22:localhost:22 -C -f
