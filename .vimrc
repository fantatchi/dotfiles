"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
runtime! user/dein/*.vim
runtime! user/init/*.vim

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
