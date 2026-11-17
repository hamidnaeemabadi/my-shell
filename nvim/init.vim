" Neovim version of ../vimrc. Install as ~/.config/nvim/init.vim.

" Basic behavior
set number
set wrap
set mouse=
set wildmenu
set lazyredraw
set showmatch
set laststatus=2
set ruler

" Move by visual lines when text wraps.
nmap j gj
nmap k gk

" Appearance (Neovim always uses UTF-8 and disables Vi compatibility).
set background=dark
colorscheme koehler
syntax enable
filetype plugin indent on

" Tabs and indentation
set tabstop=4
set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

augroup my_shell_yaml
    autocmd!
    autocmd FileType yaml,yml,yaml.* setlocal shiftwidth=2 tabstop=2 softtabstop=2
augroup END

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Editing and UI
set relativenumber
set showcmd
set hidden
set clipboard=unnamedplus
set linebreak
set cursorline
set updatetime=300
set signcolumn=yes

" Keep undo history in Neovim's default state directory.
set undofile

" Use the installer's workstation check before loading or downloading plugins.
let s:config_dir = expand('<sfile>:p:h')
call system(['sh', s:config_dir . '/is-workstation.sh'])
if v:shell_error == 0 && filereadable(s:config_dir . '/lua/my_shell/plugins.lua')
    execute 'luafile ' . fnameescape(s:config_dir . '/lua/my_shell/plugins.lua')
endif
