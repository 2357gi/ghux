# ghux

Select a project with ghq, launch (or select) a tmux session in one.

ghqで落としたリポジトリを1リポジトリ1セッションで開く。(セッション名も自動で設定される)  
該当リポジトリのセッションが既に開いてあればそのセッションにアタッチする  

これらのアクションを
- 既にセッションが開かれているか
- tmuxの他のセッションにアタッチしているか
- tmuxの中か外か
上記を気にせず、  
つまり*とりあえずプロジェクト移動したかったらghux使う*ということが可能になる！

## Requirements
- tmux
- ghq
- fzf

## Installation
Zplug

```zsh:.zshrc
zplug 2357gi/ghux
```
* i have not test this

## Usage
```
$ ghux
```

or

```zsh:.zshrc
bindkey ^G ghux
```

`GHUX_WITHOUT_USER_NAME=1`するとセッション名がリポジトリ名だけになる

## todo
- [ ] dotfilesだけ特殊な動きをするが、そういった動きをユーザーが自由に作れるように\
e.g. 外部に`alias, project_name, project_dir` のリストを保持しそれをよしなに
- [ ] gifを追加する

## License
MIT :copyright: 2357gi
