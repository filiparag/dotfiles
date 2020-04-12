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

    alias l            	'lsd --classify --almost-all --icon-theme unicode \
                            --icon always --color never --date --group-dirs first'
    alias ll            'lsd --classify --long --almost-all --icon-theme unicode \
                            --icon always --blocks name,size,permission,date,user,group \
                            --color always --date --group-dirs first'
    
    alias subl          'subl3'
    alias dmenu         'rofi -dmenu'

    abbr --add y        'yay'
    abbr --add ys       'yay -S'
    abbr --add yss      'yay -Ss'
    abbr --add yr       'yay -Rcsn'

    abbr --add gs       'git status'
    abbr --add ga       'git add'
    abbr --add gc       'git commit -m'
    abbr --add gp       'git push'
    abbr --add gcl      'git clone'

    abbr --add r        'cd /'
    abbr --add h        'cd ~'

    abbr --add v        'vim'
    abbr --add c        'bat'
    abbr --add s        'ssh'

end