"-----------------------------------------------------------------------------
" Basic settings
"-----------------------------------------------------------------------------
" 行番号を表示しない
set nonumber
" 入力中のコマンドをステータスに表示する
set showcmd
" 検索結果文字列のハイライトを有効にする
set hlsearch
" Escの2回押しでハイライト消去
nmap <ESC><ESC> :nohlsearch<CR><ESC>
" ステータスラインを常に表示
set laststatus=2
" ステータスラインに文字コードと改行文字を表示する
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索文字列入力時に順次対象文字列にヒットさせない
set noincsearch
" インデントはスマートインデント
set smartindent
" タブはスペースで入力
set expandtab
" タブ幅
set ts=4 sw=4 sts=4
au FileType ruby set ts=2 sw=2 sts=2
" オートインデントする
set autoindent
" 括弧入力時の対応する括弧を表示
set showmatch
" tab と 行末スペース
set list listchars=tab:>-,trail:_
" 最後の編集位置にカーソルを自動移動
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif
" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" ビジュアルモードの設定
set virtualedit=block
" syntax color
syntax on
