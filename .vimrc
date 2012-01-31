"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
source ~/.vim/basic.vimrc
source ~/.vim/encoding.vimrc
source ~/.vim/language.vimrc

"-----------------------------------------------------------------------------
" gmarik / vundle
" https://github.com/gmarik/vundle
"-----------------------------------------------------------------------------
set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/vundle.git/
call vundle#rc()

" original repos on github
Bundle 'altercation/vim-colors-solarized'

" vim-scripts repos
Bundle 'L9'
Bundle 'FuzzyFinder'
Bundle 'YankRing.vim'
Bundle 'neocomplcache'
" non github repos

filetype plugin indent on     " required!

source ~/.vim/plugin.vimrc
source ~/.vim/colors-solarized.vimrc

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
