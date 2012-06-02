package_install "vim.ruby"
package_install "vim.nox"

file "~/.vimrc" <<-FILE
	contents <<-CONTENTS
" Call pathogen
call pathogen#runtime_append_all_bundles()

" Formatting options
set shiftwidth=4
set tabstop=4
set noexpandtab
set incsearch
set ignorecase
set smartcase
set autoindent
set nu

" Set window properties.
"set gfn=Consolas:h12:cANSI
set guioptions-=T
set guioptions-=m
set bs=2
set nowrap
set cursorline

" Set standard plugin
filetype on
filetype plugin on
filetype indent on

syntax on
colorscheme zellner
"colorscheme southwest-fog

" Set mapleader
let mapleader = ';'

" Custom Mappings
nmap <silent> <leader>i :call ToggleIndentGuides()<CR>
nmap <silent> <leader>t :FuzzyFinderTextMate<CR>
nmap <silent> <leader>n :NERDTreeToggle<CR>
nmap <silent> <leader>o :TlistToggle<CR>
nmap <leader>s :SwitchWorkspace
nmap <silent> <leader>b :b#<CR>
nmap <silent> <leader>r :ruby refresh_finder<CR>

" Indent mappings
vmap <Tab> >gv
vmap <S-Tab> <gv

" Setup Taglist plugin
let Tlist_Auto_Update=1
let Tlist_Close_On_Select=1
let Tlist_Compact_Format=1
"let Tlist_Inc_Winwidth=0 " do not increase window width
let Tlist_Show_One_File=1
let Tlist_Use_Right_Window=1
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_Sort_Type = "name"

" Setup supertab
let g:SuperTabDefaultCompletionType = 'context'

" Setup taglist
let tlist_groovy_settings = 'groovy;c:Classes;f:Functions;u:Public Variables;v:Private Variables'

" Setup zencoding (html/css)
let g:user_zen_leader_key = ';'

" Setup ruby speicif
autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1

function! ToggleIndentGuides()
	if !exists('b:indent_guides')
		let b:indent_guides=0
	endif

	" Handle: turn off indent guides.
	if b:indent_guides
		set listchars=tab:\ \ 
		set nolist
		let b:indent_guides=0
	else
		set listchars=tab:\|\ 
		set list
		let b:indent_guides=1
	endif
endfunction

CONTENTS 
FILE
