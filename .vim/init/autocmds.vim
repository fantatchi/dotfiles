" 自動コマンド設定（ファイル保存や読み込みに反応）

" 保存時に行末の空白を削除
augroup trim_whitespace
  autocmd!
  autocmd BufWritePre * :%s/\s\+$//e
augroup END

" 前回編集位置にカーソルを復元
augroup restore_cursor
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") |
    \ execute "normal! g`\"" |
    \ endif
augroup END
