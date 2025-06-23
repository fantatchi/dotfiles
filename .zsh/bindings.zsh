# キーバインド
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

# 関数定義
function history-all {
  history -E 1
}
