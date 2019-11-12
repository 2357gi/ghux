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

## golang
branch - dev_goにてgolangで書き直してます。

# todo
- [ ] tmuxの中で使えないバグ

## License
MIT :copyright: 2357gi
