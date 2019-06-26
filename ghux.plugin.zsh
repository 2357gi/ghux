#!/usr/bin/env zsh

# set -eu
#
# if you dont need user id in tmux session name, set this.
# GHUX_WITHOUT_USER_NAME=1

GHUX_WITHOUT_USER_NAME=0


function print_usage() {
    cat << EOL
You dont have ghq or fzf.
$ go get github.com/motemen/ghq
$ brew install fzf
or detach tmux session
EOL
}

function get_project_dir() {
    local _project_dir=$(ghq list|fzf)
    ghq_root=$(ghq root)
    echo $ghq_root/$_project_dir

}


function ghux() {
    if ! (type ghq &> /dev/null && type fzf &> /dev/null); then
        print_usage
        exit 1
    fi

#     if [[ ! -z $TMUX ]] ; then
#         print_usage
#         exit 1
#     fi

    project_dir=`get_project_dir`
    cd $project_dir

    
    if [[ $GHUX_WITHOUT_USER_NAME == 0 ]] ; then
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s/%s", $1,$2}' |rev)
    else;
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
    fi

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    is_session=$(tmux list-sessions | awk -v project_name="$project_name" '{if($1 == project_name":"){print 1}}')
    
    
    if [[ $is_session == 1 ]] ; then
        if [[ ! -z $TMUX ]] ; then
            tmux switch-client -t $project_name
        else;
            tmux attach-session -t $project_name
        fi
    else;
        if [[ ! -z $TMUX ]] ; then
            tmux ___________ $project_name
        else;
            tmux new -s $project_name
        fi
    fi
}

