# ghux
easy movement and management tmux session.


![vBNMI3J.gif (1280×720)](https://i.imgur.com/vBNMI3J.gif)


# Introduction
## En
*1 repository 1 tmux session* is good bad not best.
### cons
- sessions management is not easy if you open many sessions
- tmux default move is hard to use (for me. i wanna use fzf)
- tmux has `tmux swich-client` and `tmux attatch-session`. there are in or out of tmux :sob:

so, i made **ghux**.
- can switch with built-in fuzzy search UI
- auto setting session name
- ghux is one command then in or out of tmux :joy:
- No need to consider whether there is a destination session

## ja
tmuxを1セッション1リポジトリで運用する上でのつらみ  
- セッション管理が大変
- tmuxのデフォルトの移動機能はいまいち(あいまい検索で移動したい)
- コマンドでやろうとするとtmux内かtmux外かでコマンドを変える必要がある

いい感じにするスクリプト**ghux**

- Go内蔵のあいまい検索UIでセッションを移動可能
- セッション名も自動で設定してくれる
- tmuxにすでにアタッチしているか否かを考える必要がない
- 移動先のセッションが存在するかどうか考えずに移動が可能(もしセッションが存在しなければ自動でつくる)

**ただし現状ではセッション名でアタッチ先を管理しているのでセッション名を変えられない**  



# Requirements
- go (build時)
- tmux
- ghq (optional)

# Installation
Build binary

```bash
go build -o ghux ./cmd/ghux
```

# Usage
対話選択:

```
$ ghux
```

alias指定:

```bash
$ ghux dotfiles
```

`~/.ghux_aliases`:

```text
<alias>,<name>,<path>
```

例:

```text
dotfiles,dotfiles,$HOME/dotfiles
```

### Config (TOML)
`$XDG_CONFIG_HOME/ghux/config.toml` (default: `~/.config/ghux/config.toml`)

```toml
aliases_path = "~/.ghux_aliases"
recent_path = "~/.cache/ghux/recent"
recent_limit = 10
dotfiles_option = false
```

envでも上書き可能:
- `GHUX_CONFIG`
- `GHUX_ALIASES_PATH`
- `GHUX_RECENT_PATH`
- `GHUX_RECENT_LIMIT`
- `GHUX_DOTFILES_OPTION`

### ghqとの連携
![yjYWCeU.gif (500×321)](https://i.imgur.com/yjYWCeU.gif)  
ghqにてリポジトリを管理している場合、ghux_aliasesを登録する必要なく  
開きたいリポジトリのセッションを立ち上げる/アタッチする事が可能(しかもすでにセッションが立ち上がってるか意識する必要なしに！)  

### alias機能

![vBNMI3J.gif (500×321)](https://i.imgur.com/vBNMI3J.gif)  

`~/.ghux_aliases`にghuxのaliasを登録することができる。  
形式は`<alias>,<名前>,<ファイルパス>`

# 課題
aliasに登録してないけど開いたtmux sessionもよしなに管理したい  

## License
MIT :copyright: 2357gi
