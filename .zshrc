#-------------------------------------------------------------------------------
# zsh setting
#-------------------------------------------------------------------------------
# language
export LANG=ja_JP.UTF-8
export LESSCHARSET=utf-8

# alias
case "${OSTYPE}" in
freebsd*|darwin*)
    alias ls="ls -GwF"
    ;;
linux*)
    alias ls="ls --color"
    ;;
esac
alias ll='ls -al'
alias vi='vim'
alias du="du -h"
alias df="df -h"

# compinitの初期化
autoload -U compinit
compinit

# プロンプトのカラー表示を有効
autoload -U colors
colors

# 補完候補をカーソルで選択できる
zstyle ':completion:*:default' menu select=1

# 補完リストに8ビットコードを使う
setopt PRINT_EIGHT_BIT

HISTFILE=$HOME/.zsh-history           # 履歴をファイルに保存する
HISTSIZE=100000                       # メモリ内の履歴の数
SAVEHIST=100000                       # 保存される履歴の数
setopt extended_history               # 履歴ファイルに時刻を記録
function history-all { history -E 1 } # 全履歴の一覧を出力する

setopt share_history            # 履歴の共有
setopt hist_ignore_all_dups     # 既にヒストリにあるコマンド行は古い方を削除
setopt hist_reduce_blanks       # コマンドラインの余計なスペースを排除
setopt hist_no_store            # historyコマンドは登録しない

bindkey '^P' history-beginning-search-backward  # 先頭マッチのヒストリサーチ
bindkey '^N' history-beginning-search-forward   # 先頭マッチのヒストリサーチ

# エスケープシーケンスを使う。
setopt prompt_subst
setopt list_packed   #補完リストをコンパクトに

# プロンプト
autoload promptinit
promptinit
prompt walters

# ディレクトリ履歴
setopt auto_pushd

# ssh時にホスト名で開く
function ssh_screen(){
 eval server=\${$#}
  screen -t $server ssh "$@"
}
if [ x$TERM = xscreen ]; then
  alias ssh=ssh_screen
fi

if [ -r "$HOME/.zshrc.local" ]; then
    source $HOME/.zshrc.local
fi
