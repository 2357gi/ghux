#!/usr/bin/env zsh
#
# if you want to going dotfiles dir with ghux, add this option
# GHUX_DOTFILES_OPTION=1
: ${GHUX_DOTFILES_OPTION:=0}

# set ghux aliases path
: ${GHUX_ALIASES_PATH:="$HOME/.ghux_aliases"}


function print_usage() {
    cat << EOL
You dont have ghq or fzf.
$ go get github.com/motemen/ghq
$ brew install fzf
EOL
}

function ghux() {
    if ! (type fzf &> /dev/null); then
        print_usage
        exit 1
    fi

    # touchはファイルが存在しなかったときだけ作ってくれるので
    touch $GHUX_ALIASES_PATH
    local file
    file="$GHUX_ALIASES_PATH"
    local project_alias 
    local project_name  
    local project_dir
    if [[ -n $1 ]] && [[ `cat $file |grep -E "$1"` ]];then
        local tmp=$(cat $file |grep "$1")
        line=( `echo $tmp | tr -s ',' ' '` )
        project_alias=${line[1]}
        project_name=${line[2]}
        project_dir=${line[3]}
    else
        if ( type ghq &> /dev/null ); then
            ghq_list=$(ghq list)
            project_list="$(cat $file | awk -F , '{print "[alias]", $1}')
$ghq_list"
        fi
        local list


        project_dir=$(echo $project_list|fzf)

        if [[ -z $project_dir ]]; then
            [[ -n $CURSOR ]] && zle redisplay
            return 1
        fi

        if ! ( echo $project_dir | grep -E "^\[alias\]" &>/dev/null);then
            project_dir=$(ghq root)/$project_dir
            project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
        else
            local als=$(echo $project_dir| awk '{print $2}')
            line=( `cat $file|grep -E '^'$als | tr -s ',' ' '` )
            project_alias=${line[1]}
            project_name=${line[2]}
            project_dir=${line[3]}
        fi
    fi

    # if you in tmux sesion
    local in_tmux
    [[ -n $TMUX ]] && in_tmux=0 || in_tmux=1

    local tmux_list=$(tmux list-session )

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    if  ! (echo $tmux_list | grep -E "^$project_name"); then
        (cd $(eval echo ${project_dir}) && TMUX=; tmux new-session -ds $project_name) > /dev/null # cdした後lsしちゃうので
    fi


    if [[ $in_tmux == 0 ]] ; then
        if [[ -n $CONTEXT ]];then
            BUFFER="tmux switch-client -t $project_name"&& zle accept-line
        else;
            tmux switch-client -t $project_name
        fi
    else;
        
        if [[ -n $CONTEXT ]];then
            BUFFER="tmux attach-session -t $project_name"&& zle accept-line && zle redisplay
        else;
            tmux attach-session -t $project_name
        fi
    fi
}

zle -N ghux
