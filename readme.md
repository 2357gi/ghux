# ghux

Select a project with ghq, launch (or select) a tmux session in one.

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


## License
MIT :copyright: 2357gi
