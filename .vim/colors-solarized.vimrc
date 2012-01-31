"-----------------------------------------------------------------------------
" solarized settings
"-----------------------------------------------------------------------------
if has("syntax")
    syntax enable
    colorscheme solarized

    if colors_name == 'solarized'
        set background=dark

        if has('gui_macvim')
            set transparency=0
        endif

        if !has('gui_running') && $TERM_PROGRAM == 'Apple_Terminal'
            let g:solarized_termcolors = &t_Co
            let g:solarized_termtrans = 1
            colorscheme solarized
        endif

        call togglebg#map("<F2>")
    endif
endif
