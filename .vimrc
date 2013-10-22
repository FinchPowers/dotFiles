set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set hlsearch
set nu
set term=xterm-color
set hidden

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

""""""""""""""
" tmux fixes "
""""""""""""""
" Handle tmux $TERM quirks in vim
"if $TERM =~ '^screen-256color'
"    map <Esc>OH <Home>
"    map! <Esc>OH <Home>
"    map <Esc>OF <End>
"    map! <Esc>OF <End>
"endif

" smart home
":noremap <expr> <Home> (col('.') == matchend(getline('.'), '^\s*')+1 ? '0' : '^')
":noremap <expr> <End> (col('.') == match(getline('.'), '\s*$') ? '$' : 'g_')
":vnoremap <expr> <End> (col('.') == match(getline('.'), '\s*$') ? '$h' : 'g_')
":imap <Home> <C-o><Home>
":imap <End> <C-o><End>

:map <Home> :coco

" Ctrl-{Left/Right} move buffer
:map <C-left> :bp<CR>
:map <C-right> :bn<CR>
" also move tabs, but through TMUX, special escape char  is printed with 
" <CTRL-v><ESC>
" :map [1;5D gT
" :map [1;5C gt

let g:miniBufExplMapWindowNavVim = 0
let g:miniBufExplMapWindowNavArrows = 0
let g:miniBufExplModSelTarget = 1 

" commenting/uncommenting a block of text
au FileType haskell,vhdl,ada let b:comment_leader = '-- '
au FileType vim let b:comment_leader = '" '
au FileType c,cpp,java,javascript let b:comment_leader = '// '
au FileType sh,make,coffee,python let b:comment_leader = '# '
au FileType tex let b:comment_leader = '% '
noremap <silent> ,c :<C-B>sil <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:noh<CR>
noremap <silent> ,u :<C-B>sil <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:noh<CR>'"'

" disables some pep8 errors. must run before pathogen
" E201 - json identation police
" E203 - json identation police
" E221 - multiple spaces before operator -> anoying with alignment
" E261 - inline comments start with 2 spaces
" E262 - inline comments space after #
" E401 - multiple imports same line
 let g:pymode_lint_ignore="E201,E203,E221,E261,E262,E401"
 let g:pymode_folding = 0

" Pathogen load
filetype off

call pathogen#infect()
call pathogen#helptags()

filetype plugin indent on
syntax on


" bash like <tab>
set wildmode=longest,list
set wildmenu

" solarized
syntax enable
set background=dark
let g:solarized_termtrans = 1
colorscheme solarized

set colorcolumn=80

" taglist
let Tlist_Auto_Open = 1
let Tlist_Auto_Update = 1
let Tlist_Exit_OnlyWindow = 1
let Tlist_GainFocus_On_ToggleOpen = 0

" ctags
set tags=./tags;/
" "au BufWritePost *.cc,*.c,*.cpp,*.h !ctags -R &
"
" FSwitch
au! BufEnter *.cc,*.c let b:fswitchdst = 'h'
au! BufEnter *.h let b:fswitchdst = 'cc,c'
nmap <Leader>s :FSHere<CR>
