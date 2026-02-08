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
        # ghq list をバックグラウンドで開始（tmux 情報収集と並列実行）
        setopt local_options no_monitor
        local ghq_tmp=${TMPDIR:-/tmp}/ghux_ghq_$$
        local ghq_pid=""
        if ( type ghq &> /dev/null ); then
            ghq list > "$ghq_tmp" &
            ghq_pid=$!
        fi

        # tmux セッション・ウィンドウ一覧を収集
        local tmux_sessions=""
        local tmux_windows=""
        if [[ -n $TMUX ]]; then
            local current_session=$(tmux display-message -p '#S')
            local current_window=$(tmux display-message -p '#S:#I')

            # 現在のセッション以外のセッション一覧（awk で一括処理）
            tmux_sessions=$(tmux list-sessions -F '#S' 2>/dev/null | awk -v cur="$current_session" '$0 != cur {printf "\033[32m[session]\033[0m\t%s\n", $0}')

            # 現在のウィンドウ以外のウィンドウ一覧
            # git-wt 使用時はブランチ名を表示（.git/HEAD を直接読んで fork 回避）
            tmux_windows=$(tmux list-windows -a -F $'#S\t#I\t#{pane_current_path}\t#W' 2>/dev/null | while IFS=$'\t' read -r sess idx pane_path win_name; do
                [[ "${sess}:${idx}" == "$current_window" ]] && continue
                local branch="" git_path="$pane_path/.git"
                if [[ -d "$git_path" ]]; then
                    local head=$(<"$git_path/HEAD")
                    [[ "$head" == ref:* ]] && branch="${head#ref: refs/heads/}"
                elif [[ -f "$git_path" ]]; then
                    local gitdir=$(<"$git_path")
                    gitdir="${gitdir#gitdir: }"
                    [[ -f "$gitdir/HEAD" ]] && { local head=$(<"$gitdir/HEAD"); [[ "$head" == ref:* ]] && branch="${head#ref: refs/heads/}"; }
                fi
                printf '\033[36m[window]\033[0m\t%s:%s: %s\n' "$sess" "$idx" "${branch:-$win_name}"
            done)
        fi

        # ghq list の完了を待つ
        if [[ -n "$ghq_pid" ]]; then
            wait $ghq_pid 2>/dev/null
            ghq_list=$(<"$ghq_tmp")
            command rm -f "$ghq_tmp"
        fi

        # 一覧の順序: sessions → windows → aliases → ghq projects
        local alias_list="$(awk -F , '{if ($1 != "") printf "\033[33m[alias]\033[0m\t%s\n", $1}' "$file")"
        local repo_list=""
        if [[ -n "$ghq_list" ]]; then
            repo_list=$(echo "$ghq_list" | awk '{printf "\033[34m[repo]\033[0m\t%s\n", $0}')
        fi
        local parts=()
        [[ -n "$tmux_sessions" ]] && parts+=("$tmux_sessions")
        [[ -n "$tmux_windows" ]] && parts+=("$tmux_windows")
        [[ -n "$alias_list" ]] && parts+=("$alias_list")
        [[ -n "$repo_list" ]] && parts+=("$repo_list")
        project_list="${(j:\n:)parts}"

        local selected
        selected=$(echo $project_list | fzf --ansi --tabstop=12)

        if [[ -z $selected ]]; then
            [[ -n $CURSOR ]] && zle redisplay
            return 1
        fi

        # ANSI コードを除去してプレフィックスとコンテンツを分離
        selected=$(echo "$selected" | sed $'s/\033\\[[0-9;]*m//g')
        local prefix=$(echo "$selected" | cut -f1)
        local content=$(echo "$selected" | cut -f2-)

        case "$prefix" in
            "[session]")
                if [[ -n $TMUX ]]; then
                    tmux switch-client -t "$content"
                else
                    tmux attach-session -t "$content"
                fi
                return 0
                ;;
            "[window]")
                local target_session=$(echo "$content" | awk -F: '{print $1}')
                local target_index=$(echo "$content" | awk -F: '{print $2}' | tr -d ' ')
                if [[ -n $TMUX ]]; then
                    tmux switch-client -t "$target_session"
                    tmux select-window -t "$target_session:$target_index"
                else
                    tmux attach-session -t "$target_session"
                    tmux select-window -t "$target_session:$target_index"
                fi
                return 0
                ;;
            "[alias]")
                local als="$content"
                line=( `cat $file|grep -E "^$als" | tr -s ',' ' '` )
                project_alias=${line[1]}
                project_name=$(echo ${line[2]}| awk '{sub("\\.",""); print $0}')
                project_dir=${line[3]}
                ;;
            "[repo]")
                project_dir=$(ghq root)/$content
                project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev | awk '{sub("\\.",""); print $0}')
                ;;
        esac
    fi

    # if you in tmux sesion
    local in_tmux
    [[ -n $TMUX ]] && in_tmux=0 || in_tmux=1

    local tmux_list=$(tmux list-session )

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    if  ! (echo $tmux_list | grep -E "^$project_name" &>/dev/null); then
        (cd $(eval echo ${project_dir}) && TMUX=; tmux new-session -ds $project_name) > /dev/null # cdした後lsしちゃうので
    fi


    if [[ $in_tmux == 0 ]] ; then
        if [[ -n $CONTEXT ]];then
            BUFFER="tmux switch-client -t $project_name"&& zle accept-line && zle redisplay
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
