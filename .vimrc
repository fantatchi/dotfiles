"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
runtime! init/*.vim

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
