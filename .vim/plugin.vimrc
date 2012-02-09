"-----------------------------------------------------------------------------
" plugin settings
"-----------------------------------------------------------------------------
"-----------------------------------------------------------------------------
" unite.vim
"-----------------------------------------------------------------------------
"インサートモードで開始
let g:unite_enable_start_insert = 1
""最近開いたファイル履歴の保存数
let g:unite_source_file_mru_limit = 50
" バッファ一覧
noremap <unique> <silent> <space>fb :Unite buffer<CR>
" 最近使ったファイルの一覧
noremap <unique> <silent> <space>fr :Unite file_mru<CR>
" ファイル一覧
noremap <unique> <silent> <space>ff :UniteWithBufferDir -buffer-name=files file<CR>
" ファイルとバッファ
noremap <unique> <silent> <space>fu :Unite buffer file_mru<CR>
" 全部
noremap <unique> <silent> <space>fa :UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>
" ESCキーを2回押すと終了する
au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>

"-----------------------------------------------------------------------------
" Vimfiler
"-----------------------------------------------------------------------------
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_safe_mode_by_default=0
noremap <unique> <silent> <space>fv :VimFiler<CR>

"-----------------------------------------------------------------------------
" neocomplcache
"-----------------------------------------------------------------------------
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use underbar completion.
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : '',
    \ }

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
  let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
imap <C-k>     <Plug>(neocomplcache_snippets_expand)
smap <C-k>     <Plug>(neocomplcache_snippets_expand)
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'
"autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplcache_omni_patterns.c = '\%(\.\|->\)\h\w*'
let g:neocomplcache_omni_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'

"-----------------------------------------------------------------------------
" buftabs
"-----------------------------------------------------------------------------
let g:buftabs_only_basename=1
let g:buftabs_in_statusline=1

"-----------------------------------------------------------------------------
" PDV--phpDocumentor-for-Vim
"-----------------------------------------------------------------------------
nnoremap <unique> <silent> <space>p :call PhpDocSingle()<CR>
