# Colored terminal in tty
if [ "$TERM" = "linux" ]
    set SEDCMD 's/.*\*color\([0-9]\{1,\}\).*#\([0-9a-fA-F]\{6\}\).*/\1 \2/p'
    for i in (sed -n "$_SEDCMD" $HOME/.Xresources | awk '$1 < 16 {printf "\\e]P%X%s", $1, $2}')
        echo -en "$i"
    end
    clear
end

# Abbrevations
if status --is-interactive

    set -g fish_user_abbreviations
    
    alias subl          'subl3'
    alias dmenu         'rofi -dmenu'

    abbr --add y        'yay'
    abbr --add ys       'yay -S'
    abbr --add yss      'yay -Ss'
    abbr --add yr       'yay -Rcsn'

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

    source '/usr/share/wikiman/widgets/widget.fish' 2>/dev/null

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

# History bind

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