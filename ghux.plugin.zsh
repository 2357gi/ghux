#!/usr/bin/env zsh

#
# if you dont need user id in tmux session name, set this.
# GHUX_WITHOUT_USER_NAME=1
: ${GHUX_WITH_USER_NAME:=0}

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
    if ! (type ghq &> /dev/null && type fzf &> /dev/null); then
        print_usage
        exit 1
    fi

    # touchはファイルが存在しなかったときだけ作ってくれるので
    touch $GHUX_ALIASES_PATH
    local file
    file="$GHUX_ALIASES_PATH"

    if [[ -n $1 ]] && [[ `cat $file |grep "$1"` ]];then
        local tmp=$(cat $file |grep "$1")
        line=( `echo $tmp | tr -s ',' ' '`)
        project_alias=${line[1]}
        project_name=${line[2]}
        project_dir=${line[3]}
    else
        local project_dir
        local ghq_list=$(ghq list)
        local list
        project_list="$(cat ~/.ghux_aliases | awk -F , '{print "[alias]", $1}')
$ghq_list"

        project_dir=$(echo $project_list|fzf)
        if [[ -z $project_dir ]]; then
            [[ -n $CURSOR ]] && zle redisplay
            return 1
        fi

        if [[ ! $project_dir =~ [alias] ]];then
            project_dir=$(ghq root)/$project_dir
            local project_name
            # session名にusernameを含めるかどうか
            if [[ $GHUX_WITH_USER_NAME == 0 ]] ; then
                project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
            else;
                project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s/%s", $1,$2}' |rev)
            fi
        else
            als=$(echo $project_dir| awk '{print $2}')
            line=( `cat $file|grep -E '^'$als | tr -s ',' ' '`)
            project_alias=${line[1]}
            project_name=${line[2]}
            project_dir=${line[3]}
        fi
    fi

    # if you in tmux sesion
    [[ -n $TMUX ]] && in_tmux=0

    local tmux_list=$(tmux list-session)

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    if [[ ! `echo $tmux_list | grep "$project_name"` ]]; then
        echo cant find. make session
        (cd $project_dir && TMUX=; tmux new-session -ds $project_name) > /dev/null
    fi

    if [[ -n $in_tmux ]] ; then
        tmux switch-client -t $project_name
    else;
        tmux attach-session -t $project_name
    fi
    [[ -n $CURSOR ]] && zle redisplay

}

zle -N ghux
