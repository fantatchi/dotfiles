"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
source ~/.vim/basic.vimrc
source ~/.vim/encoding.vimrc

"-----------------------------------------------------------------------------
" gmarik / vundle
" https://github.com/gmarik/vundle
"-----------------------------------------------------------------------------
if empty($SUDO_USER)
    set nocompatible                " be iMproved
    filetype off                    " required!

    set rtp+=~/.vim/vundle.git/
    call vundle#rc()
    "let g:vundle_default_git_proto = 'git'

    " original repos on github
    Bundle 'Shougo/vimproc'
    Bundle 'Shougo/vimshell'
    Bundle 'Shougo/unite.vim'
    Bundle 'Shougo/vimfiler'
    Bundle 'mattn/zencoding-vim'
    Bundle 'tomasr/molokai'

    " vim-scripts repos
    Bundle 'YankRing.vim'
    Bundle 'neocomplcache'
    Bundle 'buftabs'
    "Bundle 'dbext.vim'
    Bundle 'PDV--phpDocumentor-for-Vim'

    " non github repos


    filetype plugin indent on       " required!
    " Brief help
    " :BundleList          - list configured bundles
    " :BundleInstall(!)    - install(update) bundles
    " :BundleSearch(!) foo - search(or refresh cache first) for foo
    " :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles

    source ~/.vim/color.vimrc
    source ~/.vim/plugin.vimrc
endif

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif

