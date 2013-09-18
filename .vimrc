set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set hlsearch
set nu

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

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

" commenting/uncommenting a block of text
au FileType haskell,vhdl,ada let b:comment_leader = '-- '
au FileType vim let b:comment_leader = '" '
au FileType c,cpp,java,javascript let b:comment_leader = '// '
au FileType sh,make,coffee let b:comment_leader = '# '
au FileType tex let b:comment_leader = '% '
noremap <silent> ,c :<C-B>sil <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:noh<CR>
noremap <silent> ,u :<C-B>sil <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:noh<CR>

execute pathogen#infect()

" bash like <tab>
set wildmode=longest,list
set wildmenu
"
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
