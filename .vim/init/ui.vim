" 表示・UI設定

" 行番号の表示
set number

" ステータスラインを常に表示
set laststatus=2

" 入力中のコマンドをステータスに表示
set showcmd

" 検索のハイライトと挙動
set hlsearch          " 検索後に該当箇所をハイライト
set incsearch         " 検索語入力中にも順次マッチを表示
set ignorecase        " 小文字検索→大文字小文字を無視
set smartcase         " 大文字を含む検索語→区別して検索
set wrapscan          " 最後まで検索したら先頭に戻る

" ステータスラインの内容をカスタマイズ（文字コードや行末形式）
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
