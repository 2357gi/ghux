# ghux

Have you ever had trouble with tmux session management?  
push *prefix-s* and search so many session:weary:  
Commands that must be changed inside or outside tmux:disappointed:  

if you use tmux, Sessions can be moved with instinct:cupid:  


![vBNMI3J.gif (1280×720)](https://i.imgur.com/vBNMI3J.gif)

![yjYWCeU.gif (500×321)](https://i.imgur.com/yjYWCeU.gif)


---

tmuxを1セッション1リポジトリで運用する上でのつらみ  
- セッション管理が大変
- 移動が面倒くさい
- tmuxのデフォルトの移動機能はいまいち
- コマンドでやろうとするとtmux内かtmux外かでコマンドを変える必要がある

いい感じにするスクリプト**ghux**

- fzfを用いたあいまい検索でセッションを移動することが可能
- セッション名も自動で設定してくれる
- zle-widgetを用いて直感的な操作が可能
- tmuxにすでにアタッチしているか否かを考える必要がない
- 移動先のセッションが存在するかどうか考えずに移動が可能(もしセッションが存在しなければ自動でつくる)

**ただし現状ではセッション名でアタッチ先を管理しているのでセッション名を変えられない**  


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


### ghqとの連携
ghqにてリポジトリを管理している場合、ghux_aliasesを登録する必要なく  
開きたいリポジトリのセッションを立ち上げる/アタッチする事が可能(しかもすでにセッションが立ち上がってるか意識する必要なしに！)  

### alias機能

![vBNMI3J.gif (1280×720)](https://i.imgur.com/vBNMI3J.gif)

`~/.ghux_aliases`にghuxのaliasを登録することができる。
形式は`<alias>,<名前>,<ファイルパス>`

例: dotfilesのaliasを追加する

```
dotfiles,dotfiles,$HOME/dotfiles
```

# 課題
aliasに登録してないけど開いたtmux sessionもよしなに管理したい  

## License
MIT :copyright: 2357gi
