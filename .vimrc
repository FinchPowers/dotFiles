set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo

" git plugin
Plugin 'tpope/vim-fugitive'

" autocompleter
Plugin 'https://github.com/Valloric/YouCompleteMe.git'

" search # of #
Plugin 'https://github.com/henrik/vim-indexed-search'

" Syntax Checking/Highlighting
" TODO checkout version 0.8.1
" Plugin 'python-mode/python-mode'

" autoclose quotes
Plugin 'https://github.com/Raimondi/delimitMate.git'

" :A .cc <-> .h
Plugin 'https://github.com/vim-scripts/a.vim.git'

" Directory explorer
Plugin 'https://github.com/kien/ctrlp.vim.git'

" Mini buffer explorer
" Plugin 'https://github.com/fholgado/minibufexpl.vim.git'
Plugin 'https://github.com/thasmin/minibufexpl.vim.git'

" Align stuff
Plugin 'https://github.com/godlygeek/tabular.git'

" Bottom airline bar
Plugin 'https://github.com/vim-airline/vim-airline.git'
Plugin 'https://github.com/vim-airline/vim-airline-themes.git'

" Plugin 'https://github.com/sjbach/lusty.git'

" Left pane with tags/functions/classes
Plugin 'https://github.com/vim-scripts/taglist.vim.git'

Plugin 'https://github.com/tpope/vim-sensible.git'

Plugin 'https://github.com/heavenshell/vim-pydocstring.git'

Plugin 'vim-syntastic/syntastic'
Plugin 'nvie/vim-flake8'

Plugin 'leafgarland/typescript-vim'

Plugin 'easymotion/vim-easymotion'

Plugin 'altercation/vim-colors-solarized'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set hlsearch
set nu
set term=xterm-color
set hidden

" since vim8, w/o it you can't backspace beyond the insert point
set backspace=2

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
au FileType c,cpp,java,javascript,typescript let b:comment_leader = '// '
au FileType sh,make,coffee,python let b:comment_leader = '# '
au FileType tex let b:comment_leader = '% '

au FileType make setl tabstop=2 noexpandtab softtabstop=2
au FileType html,css,xml,rst,javascript,typescript,yaml,yml setl shiftwidth=2 expandtab tabstop=2 softtabstop=2

noremap <silent> ,c :<C-B>sil <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:noh<CR>
noremap <silent> ,u :<C-B>sil <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:noh<CR>'"'

" closes the doc window when autocompleting with rope
 autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
 autocmd InsertLeave * if pumvisible() == 0|pclose|endif
" ------

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

" CTRL P
nmap <Leader>p :CtrlPBuffer<CR>
let g:ctrlp_custom_ignore = 'build/x86_64'
let g:ctrlp_working_path_mode = ''

" Show trailing whitespaces as ~
set list
set listchars=trail:~,tab:▸\ 

" syntastic
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_cpp_compiler_options = '-std=c++11'
let g:syntastic_python_checkers=['flake8']
if filereadable("mypy.ini")
    let g:syntastic_python_checkers += ['mypy']
endif

" terminal 256 colors
set t_Co=256

" 10 msec delay when pressing ESC
set ttimeoutlen=10

let g:ycm_autoclose_preview_window_after_completion=1
"map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>
:noremap <F2> :YcmCompleter GetType<CR>
:noremap <C-down> :YcmCompleter GoToDeclaration<CR>
:noremap <C-up> :YcmCompleter GetDoc<CR>
"let g:ycm_confirm_extra_conf = 0
"let g:ycm_global_ycm_extra_conf = '/home/fmlheureux/.ycm_extra_conf.py'
"let g:ycm_python_binary_path = '/usr/bin/python'
"let g:ycm_show_diagnostics_ui = 1

let python_highlight_all=1

" vim-sensible
set noautoread

let g:ycm_global_ycm_extra_conf = '~/global_ycm_extra_conf.py'

function! Black()
    w
    silent !black %
    redraw!
    edit!
    w
endfunction

function! Format()
    w
    silent !make format %
    redraw!
    edit!
    w
endfunction

:let mapleader="é"

set scrolloff=5

let g:pydocstring_doq_path = '/Users/francois-mi.lheureux/.pyenv/shims/doq'
let g:pydocstring_formatter = 'google'
