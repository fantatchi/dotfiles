# 言語設定
export LANG=ja_JP.UTF-8       # ロケールを日本語＋UTF-8に設定
export LESSCHARSET=utf-8      # lessコマンドでUTF-8文字を正しく表示

# エイリアス設定
case "${OSTYPE}" in
  freebsd*|darwin*) alias ls="ls -GwF" ;;     # macOSやFreeBSD用
  linux*)           alias ls="ls --color" ;;  # Linux用
esac
alias vi='vim'      # viでvimを起動
alias du='du -h'    # duコマンドを読みやすい形式で表示
alias df='df -h'    # dfコマンドを読みやすい形式で表示

# プロンプト・カラー設定
autoload -U colors; colors         # カラー機能を有効化
setopt prompt_subst                # プロンプト内でコマンド置換などを有効に

# 補完機能の設定
zstyle ':completion:*:default' menu select=1  # 補完候補をメニュー形式で選択
setopt PRINT_EIGHT_BIT         # 8ビット文字（日本語など）を正しく扱う
setopt list_packed             # 補完リストをコンパクトに表示

# 履歴機能の設定
HISTFILE=$HOME/.zsh-history    # 履歴ファイルの保存先
HISTSIZE=100000                # メモリ上に保持する履歴数
SAVEHIST=100000                # 保存する履歴ファイルのエントリ数
setopt extended_history        # 履歴に実行時間を記録
setopt share_history           # シェル間で履歴を共有
setopt hist_ignore_all_dups    # 重複コマンドは古い方を削除
setopt hist_reduce_blanks      # 不要な空白を除去
setopt hist_no_store           # `history` コマンドは履歴に残さない
function history-all { history -E 1 }  # 全履歴を表示する関数

# キーバインド設定
bindkey '^P' history-beginning-search-backward  # Ctrl+Pで先頭マッチ履歴検索
bindkey '^N' history-beginning-search-forward   # Ctrl+Nで先頭マッチ履歴検索

# ディレクトリ履歴設定
setopt auto_pushd   # cd時にディレクトリ履歴を自動保存