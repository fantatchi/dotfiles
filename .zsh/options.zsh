# オプション系の設定

# プロンプト・カラー
autoload -U colors && colors
setopt prompt_subst

# 補完
zstyle ':completion:*:default' menu select=1
setopt list_packed

# 履歴
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
# setopt hist_no_store

# ディレクトリ履歴
setopt auto_pushd
