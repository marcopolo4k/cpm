".vimrc 
syntax on 

set shiftwidth=4 
set tabstop=4 
set paste
set nu
set incsearch
set hlsearch

" order is important, keep these below the above
set autoindent 
set smarttab
set expandtab 

" Press Space to turn off highlighting and clear any message already displayed.
:nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
set tags=./tags,tags,/usr/local/cpanel/t/qa/lib/tags

let perl_include_pod = 1

" Stuff I sometimes want to turn off
set ic
set smartcase

filetype on
autocmd FileType make set nosmarttab
autocmd FileType make set noexpandtab
autocmd FileType tsv set noexpandtab
autocmd FileType csv set noexpandtab

" experimental
" let @c = 'mp{j^V}}kI# `p'
" let @u = '{j}klx`p'
