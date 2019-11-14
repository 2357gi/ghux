# ghux

Select a project with ghq, launch (or select) a tmux session in one.

![ghux.gif (900×506)](https://i.imgur.com/8PPInKr.gif)

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
and do `^G` in zsh

### alias機能
![zXBgZWS.gif (960×540)](https://i.imgur.com/zXBgZWS.gif)

`~/.ghux_aliases`にghuxのaliasを登録することができる。
形式は`<alias>,<名前>,<ファイルパス>`

例: dotfilesのaliasを追加する

```
dotfiles,dotfiles,$HOME/dotfiles
```

## todo
- [ ] gifを追加する

## License
MIT :copyright: 2357gi
