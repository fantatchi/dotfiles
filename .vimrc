"-----------------------------------------------------------------------------
" Personal preference .vimrc file
" Created by fantatchi fantatchi@twitter
"-----------------------------------------------------------------------------
source ~/.vim/basic.vimrc
source ~/.vim/encoding.vimrc

"-----------------------------------------------------------------------------
" gmarik/Vundle.vim
" https://github.com/gmarik/Vundle.vim
"-----------------------------------------------------------------------------
if empty($SUDO_USER)
    set nocompatible              " be iMproved, required
    filetype off                  " required

    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/Vundle.vim
    call vundle#begin()

    " plugin on GitHub repo
    Plugin 'Shougo/vimproc'
    Plugin 'Shougo/vimshell'
    Plugin 'Shougo/unite.vim'
    Plugin 'Shougo/neomru.vim'
    Plugin 'Shougo/vimfiler'
    Plugin 'tomasr/molokai'
    Plugin 'w0ng/vim-hybrid'
    Plugin 'tomtom/tcomment_vim'

    " plugin from http://vim-scripts.org/vim/scripts.html
    Plugin 'YankRing.vim'
    Plugin 'neocomplcache'
    Plugin 'buftabs'
    Plugin 'PDV--phpDocumentor-for-Vim'

    " Git plugin not hosted on GitHub
    "Plugin 'git://git.wincent.com/command-t.git'

    " git repos on your local machine (i.e. when working on your own plugin)
    "Plugin 'file:///home/gmarik/path/to/plugin'

    " All of your Plugins must be added before the following line
    call vundle#end()            " required
    filetype plugin indent on    " required
    " To ignore plugin indent changes, instead use:
    "filetype plugin on
    "
    " Brief help
    " :PluginList       - lists configured plugins
    " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
    " :PluginSearch foo - searches for foo; append `!` to refresh local cache
    " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal

    source ~/.vim/color.vimrc
    source ~/.vim/plugin.vimrc
endif

if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif

