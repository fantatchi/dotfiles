"-----------------------------------------------------------------------------
" color settings
"-----------------------------------------------------------------------------
if has("syntax")

    syntax enable

    " 全角スペースを表示
    scriptencoding utf-8
    augroup hilightIdegraphicSpace
        autocmd!
        autocmd ColorScheme * highlight IdeographicSpace term=underline ctermbg=DarkGray guibg=DarkGray
        autocmd VimEnter,WinEnter * match IdeographicSpace /　/
    augroup END

    if !has('gui_running') && &t_Co >= 256
        " colorscheme molokai
        colorscheme hybrid
    else
        colorscheme default
    endif

endif
