"""" ========================
"""" Basic Behavior
"""" ========================

set number              " Show absolute line numbers
set wrap                " Wrap long lines instead of overflowing horizontally
set encoding=utf-8      " Use UTF-8 encoding for files and buffers
""set mouse=a           " Enable mouse support in all modes (disabled – can be buggy on macOS)
set mouse=              " Explicitly disable mouse support
set wildmenu            " Enable enhanced command-line completion menu
set lazyredraw          " Do not redraw screen during macros (improves performance)
set showmatch           " Highlight matching brackets/parentheses
set laststatus=2        " Always show the statusline, even with one window
set ruler               " Show cursor position (line and column) in the statusline
""""set visualbell      " Use visual bell instead of sound (disabled)


"""" ========================
"""" Key Bindings
"""" ========================

" Move down by *visual* line (respects wrapped lines)
nmap j gj

" Move up by *visual* line (respects wrapped lines)
nmap k gk


"""" ========================
"""" Vim Appearance
"""" ========================

" Load colorscheme from ~/.vim/colors/
"colorscheme murphy      " Set colorscheme (alternatives: slate, molokai, badwolf, solarized)
colorscheme koehler      " Set colorscheme (alternatives: slate, molokai, badwolf, solarized)
"colorscheme desert      " Set colorscheme (alternatives: slate, molokai, badwolf, solarized)
"colorscheme default      " Set colorscheme (alternatives: slate, molokai, badwolf, solarized)

set nocompatible        " Disable Vi compatibility for full Vim feature set
syntax on               " Enable syntax highlighting
syntax enable           " Ensure syntax highlighting is fully enabled
filetype plugin indent on " Enable filetype detection, plugins, and indentation rules


"""" ========================
"""" Tab and Indentation Settings
"""" ========================

set tabstop=4           " Display width of a <TAB> character
set expandtab           " Convert tabs into spaces
set shiftwidth=4        " Number of spaces for each indentation level
set softtabstop=4       " Number of spaces removed when pressing backspace

set autoindent          " Copy indentation from the current line
set smartindent         " Automatically add indentation after blocks (e.g. '{')


"""" ========================
"""" Search Settings
"""" ========================

set incsearch           " Show search matches as you type
set hlsearch            " Highlight all search matches


"""" ========================
"""" Editing & UI Enhancements
"""" ========================

set relativenumber      " Show relative line numbers (useful for motions like 5j)
set showcmd             " Display incomplete commands in the statusline
set hidden              " Allow switching buffers without saving
set clipboard=unnamedplus " Use system clipboard for yank, delete, and paste

set linebreak           " Wrap lines at word boundaries (no mid-word breaks)
set cursorline          " Highlight the line where the cursor is
set background=dark     " Optimize colors for dark terminal backgrounds
"colorscheme desert      " Override colorscheme with 'desert'

set updatetime=300      " Faster CursorHold events (useful for LSP, git signs)
set signcolumn=yes      " Always show sign column (prevents text shifting)
