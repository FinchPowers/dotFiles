set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set hlsearch
set nu

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

" solarized
" syntax enable
" set background=dark
" let g:solarized_termtrans = 1
" colorscheme solarized

" smart home
noremap <expr> <silent> <Home> col('.') == match(getline('.'),'\S')+1 ? '0' : '^'
imap <silent> <Home> <C-O><Home>

" Ctrl-{Left/Right} move tabs
:map <C-left> gT
:map <C-right> gt
" also move tabs, but through TMUX, special escape char  is printed with 
" <CTRL-v><ESC>
:map [1;5D gT
:map [1;5C gt
