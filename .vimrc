"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
source ~/.vim/basic.vimrc
source ~/.vim/encoding.vimrc

"-----------------------------------------------------------------------------
" Shougo/neobundle.vim
" https://github.com/Shougo/neobundle.vim
"-----------------------------------------------------------------------------
if empty($SUDO_USER)

    " Note. Skip initialization for vim-tiny or vim-small.
    if !1 | finish | endif

    if has('vim_starting')
        set nocompatible               " Be iMproved

        " Required
        set runtimepath+=~/.vim/bundle/neobundle.vim/
    endif

    " Required
    call neobundle#begin(expand('~/.vim/bundle/'))

    " Required
    NeoBundleFetch 'Shougo/neobundle.vim'

    " plugin on GitHub repo
    NeoBundle 'Shougo/vimproc', {
        \ 'build' : {
            \ 'windows' : 'make -f make_mingw32.mak',
            \ 'cygwin' : 'make -f make_cygwin.mak',
            \ 'mac' : 'make -f make_mac.mak',
            \ 'unix' : 'make -f make_unix.mak',
        \ },
    \ }
    NeoBundle 'Shougo/vimshell'
    NeoBundle 'Shougo/unite.vim'
    NeoBundle 'Shougo/neomru.vim'
    NeoBundle 'Shougo/vimfiler'
    NeoBundle 'tomasr/molokai'
    NeoBundle 'w0ng/vim-hybrid'
    NeoBundle 'tomtom/tcomment_vim'

    " plugin from http://vim-scripts.org/vim/scripts.html
    NeoBundle 'YankRing.vim'
    NeoBundle 'neocomplcache'
    NeoBundle 'buftabs'
    NeoBundle 'PDV--phpDocumentor-for-Vim'

    call neobundle#end()

    " Required
    filetype plugin indent on

    " If there are uninstalled bundles found on startup,
    " this will conveniently prompt you to install them.
    NeoBundleCheck

    source ~/.vim/color.vimrc
    source ~/.vim/plugin.vimrc
endif

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
