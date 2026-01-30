" 基本設定：エンコーディングやインデントなど

" ファイルの文字コードと改行コードの自動判別
set encoding=utf-8
set fileencodings=utf-8,utf-16,ucs2le,ucs-2,iso-2022-jp,euc-jp,sjis,cp932
set fileformats=unix,dos,mac

" インデントとタブ設定（タブ→スペース）
set expandtab          " Tabキーでスペースを挿入
set tabstop=4          " 画面上のタブ幅
set shiftwidth=4       " 自動インデントで使う幅
set softtabstop=4      " Tab入力時に使うスペース数
set smartindent        " スマートインデント有効
set autoindent         " 前の行のインデントを継承

" タブ幅2スペース
augroup indent_two
  autocmd!
  autocmd FileType ruby,javascript,typescript,json,yaml,html,css,scss,vue,svelte setlocal ts=2 sw=2 sts=2
augroup END

" 括弧入力時に対応する括弧を一瞬表示
set showmatch

" ビジュアルモードで矩形選択を許可
set virtualedit=block

" 改行文字やタブ、行末スペースを可視化
set list
set listchars=tab:>-,trail:_
