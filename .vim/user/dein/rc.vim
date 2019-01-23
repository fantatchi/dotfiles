if &compatible
  set nocompatible
endif
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.vim/dein')
  call dein#begin('~/.vim/dein')

  call dein#add('~/.vim/dein/repos/github.com/Shougo/dein.vim')

  call dein#add('w0ng/vim-hybrid')

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
syntax enable
