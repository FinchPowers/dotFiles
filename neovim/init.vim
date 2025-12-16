let g:python3_host_prog = '/Users/fmlheureux/.local/share/nvim/mich-made-venv/.venv-314/bin/python3'
" disable mouse
set mouse=

" Plugin location: ~/.local/share/nvim/plugged
call plug#begin()

Plug 'folke/tokyonight.nvim'

" List your plugins here
Plug 'tpope/vim-sensible'

" git plugin
Plug 'tpope/vim-fugitive'

" autocompleter
Plug 'https://github.com/Valloric/YouCompleteMe.git'

" search # of #
Plug 'https://github.com/henrik/vim-indexed-search'

" autoclose quotes
Plug 'https://github.com/Raimondi/delimitMate.git'

" :A .cc <-> .h
Plug 'https://github.com/vim-scripts/a.vim.git'

" Directory explorer
Plug 'https://github.com/kien/ctrlp.vim.git'

" Mini buffer explorer
Plug 'https://github.com/thasmin/minibufexpl.vim.git'

" Align stuff
Plug 'https://github.com/godlygeek/tabular.git'

" Bottom airline bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Left pane with tags/functions/classes
Plug 'vim-scripts/taglist.vim'

Plug 'heavenshell/vim-pydocstring'

Plug 'dense-analysis/ale'

Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

" double <leader> + char, get 1 key to get there
" eg.: <leader><leader> w: give key options to get to the next ~20 words
Plug 'easymotion/vim-easymotion'

" vim only compatible
Plug 'maxmx03/solarized.nvim'
Plug 'morhetz/gruvbox'

Plug 'github/copilot.vim'
Plug 'zbirenbaum/copilot.lua'
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim'

Plug 'vim-pandoc/vim-pandoc-syntax'

" visual vertical indent guide
Plug 'lukas-reineke/indent-blankline.nvim'

Plug '4DRIAN0RTIZ/complexity.nvim'

Plug 'kkrampis/codex.nvim'

Plug 'neovim/nvim-lspconfig'

call plug#end()

set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set hlsearch
set nu
"
"set term=xterm-256color
set termguicolors


" allows to move away from unsaved buffer
set hidden

" Ctrl-{Left/Right} move buffer
:map <C-left> :bp!<CR>
:map <C-right> :bn!<CR>

let g:miniBufExplMapWindowNavVim = 0
let g:miniBufExplMapWindowNavArrows = 0
let g:miniBufExplModSelTarget = 1

" commenting/uncommenting a block of text
au FileType haskell,vhdl,ada let b:comment_leader = '-- '
au FileType vim let b:comment_leader = '" '
au FileType c,cpp,java,javascript,typescript let b:comment_leader = '// '
au FileType sh,make,coffee,python,yaml,yml let b:comment_leader = '# '
au FileType tex let b:comment_leader = '% '

au FileType make setl tabstop=2 noexpandtab softtabstop=2
au FileType html,css,xml,rst,javascript,typescript,javascriptreact,typescriptreact,yaml,yml setl shiftwidth=2 expandtab tabstop=2 softtabstop=2

xnoremap <silent> ,c :<C-u>silent '<,'>s/^/\=escape(b:comment_leader,'\/')/<CR>:noh<CR>
xnoremap <silent> ,u :<C-u>silent '<,'>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:noh<CR>

" bash like <tab>
set wildmode=longest,list
set wildmenu

" Default value is "normal", Setting this option to "high" or "low" does use the
" same Solarized palette but simply shifts some values up or down in order to
" expand or compress the tonal range displayed.
let g:neosolarized_contrast = "normal"

" Special characters such as trailing whitespace, tabs, newlines, when displayed
" using ":set list" can be set to one of three levels depending on your needs.
" Default value is "normal". Provide "high" and "low" options.
let g:neosolarized_visibility = "normal"

" I make vertSplitBar a transparent background color. If you like the origin
" solarized vertSplitBar style more, set this value to 0.
let g:neosolarized_vertSplitBgTrans = 1

" If you wish to enable/disable NeoSolarized from displaying bold, underlined
" or italicized" typefaces, simply assign 1 or 0 to the appropriate variable.
" Default values:
let g:neosolarized_bold = 1
let g:neosolarized_underline = 1
let g:neosolarized_italic = 1

" Used to enable/disable "bold as bright" in Neovim terminal. If colors of bold
" text output by commands like `ls` aren't what you expect, you might want to
" try disabling this option. Default value:
let g:neosolarized_termBoldAsBright = 1


set colorcolumn=80,100,120

" taglist
let Tlist_Auto_Open = 1
let Tlist_Auto_Update = 1
let Tlist_Exit_OnlyWindow = 1
let Tlist_GainFocus_On_ToggleOpen = 0
let Tlist_Sort_Type = "name"
" autocmd FileType taglist setlocal winfixwidth
"
" ========= START =========
" Disable auto equalizing
set noequalalways
" Prevent extreme shrinking of non-current windows
set winminwidth=10

" Taglist default width
let g:Tlist_WinWidth = 30

augroup TaglistWidthFix
  autocmd!
  " When taglist opens, set and lock width
  autocmd FileType taglist call s:TaglistLock()
  " Reassert width after window/layout events
  autocmd WinEnter,BufWinEnter,VimResized * if &filetype ==# 'taglist' | call s:TaglistLock() | endif
augroup END

function! s:TaglistLock() abort
  let l:w = get(g:, 'Tlist_WinWidth', 30)
  execute 'vertical resize ' . l:w
  setlocal winfixwidth
endfunction
" ========= END =========

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

" 10 msec delay when pressing ESC
set ttimeoutlen=10

let g:ycm_server_python_interpreter= '/Users/fmlheureux/.local/share/nvim/mich-made-venv/.venv-313/bin/python3'
let g:ycm_autoclose_preview_window_after_completion=1
:noremap <F2> :YcmCompleter GetType<CR>
:noremap <C-down> :YcmCompleter GoTo<CR>
:noremap <C-up> :YcmCompleter GetDoc<CR>

let python_highlight_all=1

" vim-sensible
set noautoread

:let mapleader="é"

set scrolloff=5

let g:pydocstring_doq_path = '/Users/fmlheureux/.pyenv/shims/doq'
let g:pydocstring_formatter = 'google'

" ale
let g:ale_fixers_python = []
let g:ale_linters_python = []
" apply ruff first, so that black overrides if it's installed
if filereadable(".venv/bin/ruff")
    let g:ale_fixers_python += ['ruff_format', 'ruff']
    let g:ale_linters_python += ['ruff']
endif
if filereadable(".venv/bin/black")
    let g:ale_fixers_python += ['black']
endif
if filereadable(".venv/bin/mypy")
    let g:ale_linters_python += ['mypy']
endif
let g:ale_fixers = {
\   'python': ale_fixers_python
\}
let g:ale_linters = {
\   'python': ale_linters_python
\}
let g:ale_fix_on_save = 1
" Use Neovim diagnostics API (so LSP + ALE can be unified)
let g:ale_use_neovim_diagnostics_api = 1
" loclist -> bottom list, one per buffer (managed via vim.diagnostic in lua_config)
let g:ale_set_loclist = 0
" quickfix -> bottom list, one per session
let g:ale_set_quickfix = 0
" automatically open the bottom list on errors (managed via vim.diagnostic in lua_config)
let g:ale_open_list = 0

" git color for overlength summary
" check vim color options with `:hi`
" vim builtin colors for git
" https://github.com/vim/vim/blob/master/runtime/syntax/gitcommit.vim
au FileType gitcommit
 \ hi gitcommitOverflow ctermfg=red

" copilot config
" CTRL + A to accept
imap <silent><script><expr> <C-A> copilot#Accept("\<CR>")
" don't do anything with <TAB>
let g:copilot_no_tab_map = v:true
" CTRL + Shift + Down for next suggestion
imap <C-S-Down> <Plug>(copilot-next)
" CTRL + Shift + Up for previous suggestion
imap <C-S-Up> <Plug>(copilot-previous)

" solarized does not trigger on mdx files
augroup pandoc_syntax
    au! BufNewFile,BufFilePre,BufRead *.mdx set filetype=markdown.pandoc
augroup END

set background=dark
colorscheme gruvbox"

lua require("lua_config")


" Protect taglist window from accidental opens/edits
augroup TaglistProtect
  autocmd!
  " When taglist buffer appears
  autocmd FileType taglist call s:protect_taglist()
augroup END

function! s:protect_taglist() abort
  " Do not allow editing
  setlocal buftype=nofile
  setlocal nomodifiable
  setlocal noswapfile
  " Disable accidental Enter/o (default jumps)
  nnoremap <silent><buffer> <CR> <NOP>
  nnoremap <silent><buffer> o <NOP>
  " Provide an intentional mapping (Leader+Enter) to jump if you still want it
  nnoremap <silent><buffer> <Leader><CR> :<C-u>normal! <CR><CR>
endfunction
