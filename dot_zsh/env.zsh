# 言語・環境変数
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LESSCHARSET=utf-8

# テーマ
autoload promptinit
promptinit
prompt walters

# エイリアス
case "${OSTYPE}" in
  freebsd*|darwin*) alias ls="ls -GwF" ;;
  linux*)           alias ls="ls --color=auto" ;;
esac
alias vi='vim'
alias du='du -h'
alias df='df -h'

alias ll='ls -lh'          # サイズ・日付つき
alias la='ls -la'          # ドットファイル含む
alias l='ls -lAhF'         # フル情報付き + 色 + /区別

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 補完機能を有効にする
autoload -Uz compinit
compinit
