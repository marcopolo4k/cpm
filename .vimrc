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
set hlsearch
" Press Space to turn off highlighting and clear any message already displayed.
:nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
set tags=./tags,tags,/usr/local/cpanel/t/qa/lib/tags

let perl_include_pod = 1

" Stuff I sometimes want to turn off
set ic
set smartcase

filetype on
autocmd FileType tsv set noexpandtab
autocmd FileType csv set noexpandtab

" experimental
" let @c = 'mp{j^V}}kI# `p'
" let @u = '{j}klx`p'
