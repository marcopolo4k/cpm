".vimrc 
syntax on 
set autoindent 
set smartindent 
set shiftwidth=4 
set tabstop=4 
set expandtab 
set paste
set nu
set incsearch

filetype on
autocmd FileType tsv set noexpandtab
autocmd FileType csv set noexpandtab
