"Visual
syntax on
set cursorline
set number
set ruler
set showcmd
set showmatch
set matchtime=1
set laststatus=2

"Search
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>
set wildmode=longest:full,full

"Tab
set expandtab
set smarttab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set clipboard=unnamed

"Indent
set autoindent
set smartindent

"File
set nobackup
set noswapfile
set autoread
set hidden

"vim-plug
call plug#begin('~/.vim/plugged')
Plug 'arcticicestudio/nord-vim'
Plug 'vim-airline/vim-airline'
call plug#end()
colorscheme nord
let g:airline_powerline_fonts = 1
