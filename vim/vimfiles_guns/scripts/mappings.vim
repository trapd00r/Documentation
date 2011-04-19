" Conventions:
"
" Super
"   Modifies / Toggles windows and tabs
"   Write buffers
"   Should not override OS / WM bindings
"
" Meta
"   Emacs style Movement / Editing
"
" <Leader>
"   Buffer settings (toggles, etc)
"   Opens :command line


""" Preservations

" ++ i_Ctrl-X (insert mode completions)
" -- i_Ctrl-T (insert mode shift right)
PreserveMap! <C-t> <C-x>

" ++ Ctrl-X, Ctrl-A (decrement, increment)
" -- nil
PreserveMap <C-x>> <C-x>
PreserveMap <C-x>< <C-a>

" ++ i_Ctrl-R (insert register)
" -- i_Ctrl-Y (copy character above)
PreserveMap! <C-y> <C-r>

" ++ i_Ctrl-K (insert digraph)
" -- i_Ctrl-\ (mode switch)
PreserveMap! <C-Bslash> <C-k>

" ++ Ctrl-e (scroll window down)
" -- nil
PreserveMap <M-y> <C-e>


""" Metamappings

" Mapleader:
"   * breaks out of insert mode for universal availability
"   * -- i_Ctrl-X
let g:mapleader=''
map! <C-x> <Esc><Leader>

" Allow use of <C-c> to terminate visual block insertion
" and hellaciously break out of Select mode
vnoremap <C-c> <Esc>
snoremap <C-c> <Esc><C-c>


""" Editing / Movement like Emacs

" char left/right (insert only)
" -- i_Ctrl-B i_Ctrl-F
noremap! <C-b> <Left>
noremap! <C-f> <Right>

" word left/right
Mapall   <M-b> <C-o> b
cnoremap <M-b> <S-Left>
Mapall   <M-f> <C-o> w
cnoremap <M-f> <S-Right>

" bol/eol
" -- Ctrl-A i_Ctrl-A Ctrl-E i_Ctrl-E
noremap  <C-a> ^
noremap! <C-a> <Esc>I
cnoremap <C-a> <Home>
noremap  <C-e> $
noremap! <C-e> <Esc>A
cnoremap <C-e> <End>

" Rubout char / word / line
" -- Ctrl-U
noremap  <C-u>  d^
noremap  <M-BS> db
noremap! <M-BS> <C-w>

" Forward delete char / word / line
" FIXME: forward-delete-word does not delete newlines as expected
" FIXME: forward-delete-word also creeps forward on command line
" -- Ctrl-D i_Ctrl-D c_Ctrl-K i_Ctrl-K
noremap  <C-d> x
noremap! <C-d> <Del>
Mapall   <M-d> <C-o> dw
cnoremap <M-d> <S-Right><C-w>
Mapall   <C-k> <C-o> D
cnoremap <C-k> <C-n>

" Upper / Lower / Capitalize / Transpose
nnoremap <M-u> gUww
inoremap <M-u> <Esc><Right>gUwwi
nnoremap <M-l> guww
inoremap <M-l> <Esc><Right>guwwi
nnoremap <M-c> gU2<Space>guww
inoremap <M-c> <Esc><Right>gU2<Space>guwwi
nnoremap <M-t> x<Left>P2<Right>
inoremap <M-t> <Esc><Right>x<Left>P2<Right>i

" Undo / Redo and enter normal mode
" -- Ctrl-_ i_Ctrl-_ i_Ctrl-R
Mapall   <C-_> u
noremap! <C-r> <Esc>:redo<CR>


""" Editing / Movement with modifiers

" Page up / down
" -- Ctrl-F Ctrl-B
noremap <C-f> <PageDown>M
noremap <C-b> <PageUp>M

" Soft-wrapped up and down
Mapall   <Up>   <C-o> gk
cnoremap <Up>   <Up>
Mapall   <Down> <C-o> gj
cnoremap <Down> <Down>

" word movement with CamelCaseMotion
" -- C-Left C-Right
map  <C-Left>  <Plug>CamelCaseMotion_b
map! <C-Left>  <C-o><C-Left>
cmap <C-Left>  <S-Left>
map  <C-Right> <Plug>CamelCaseMotion_w
map! <C-Right> <C-o><C-Right>
cmap <C-Right> <S-Right>
map  <C-BS>    d<C-Left>
map! <C-BS>    <C-Left><C-o>D
cmap <C-BS>    <C-w>


""" Command line / Search shortcuts

" -- ;
noremap ;          :
Mapall  <4-;>      q:
noremap /          /\v
noremap ?          ?\v
noremap <Bslash>   /\V
noremap <Bar>      ?\V
noremap <Leader>h  :help<Space>
noremap <Leader>co :colorscheme<Space>

" Overload redraw mapping to also clear last match
noremap <C-l> :let @/=''<CR>:redraw!<CR>

" Settings
noremap <Leader>s<Space> :setlocal<Space>
noremap <Leader>sc       :setlocal clipboard=unnamed
noremap <Leader>sfm      :setlocal foldmethod=indent
noremap <Leader>sfc      :setlocal foldcolumn=
noremap <Leader>ss       :setlocal synmaxcol=1000
noremap <Leader>st       :SetTextwidth<Space>
noremap <Leader>sw       :SetWhitespace<Space>

" Toggles
noremap <Leader><C-e> :set expandtab!<CR>:set expandtab?<CR>
noremap <Leader><C-h> :set hlsearch!<CR>:set hlsearch?<CR>
noremap <Leader><C-o> :set cursorline!<CR>:set cursorline?<CR>
noremap <Leader><C-p> :set paste!<CR>:set paste?<CR>
noremap <Leader><C-a> :setlocal spell!<CR>:setlocal spell?<CR>
noremap <Leader><C-b> :setlocal scrollbind!<CR>:setlocal scrollbind?<CR>
noremap <Leader><C-l> :setlocal list!<CR>:setlocal list?<CR>
noremap <Leader><C-w> :setlocal wrap!<CR>:setlocal wrap?<CR>

" Other builtin commands
noremap <Leader>M :make<CR>

" Plugin: Fugitive (git)
noremap <Leader>g<Space> :Git<Space>
noremap <Leader>gc       :Gcommit<CR>
noremap <Leader>gd       :Git di<CR>
noremap <Leader>gf       :silent! Git f<CR>
noremap <Leader>gl       :silent! Git lp<CR>
noremap <Leader>gr       :silent! Git rs<CR>
noremap <Leader>gaa      :silent! Git aa<CR>:echo 'All files added to index'<CR>
noremap <Leader>gac      :Git aa<CR>:Gcommit<CR>
noremap <Leader>gap      :Git ap<CR>
noremap <4-g>            :Gstatus<CR>
noremap <4-G>            q:iGgrep<Space>

" Plugin: Manpageview
noremap <Leader>m :Man<Space>

" Plugin: CTAGS-Highlighting
noremap <Leader><C-u> :UpdateTypesFile!<CR>

" Plugin: ConqueTerm
noremap <Leader>t<Space> :ConqueTermSplit<Space>
noremap <Leader>tb       :ConqueTermSplit bash<CR>
noremap <Leader>tt       :ConqueTermSplit bash<CR>
noremap <Leader>ts       :ConqueTermSplit scheme<CR>
noremap <Leader>tr       :ConqueTermSplit irb<CR>
noremap <Leader>tR       :ConqueTermSplit rails c<CR>


""" Window / Tab Management

" Switch window focus
Mapall <4-Left>  :wincmd\ h<CR>
Mapall <4-Down>  :wincmd\ j<CR>
Mapall <4-Up>    :wincmd\ k<CR>
Mapall <4-Right> :wincmd\ l<CR>
Mapall <4-h>     :wincmd\ h<CR>
Mapall <4-j>     :wincmd\ j<CR>
Mapall <4-k>     :wincmd\ k<CR>
Mapall <4-l>     :wincmd\ l<CR>

" Move window position
Mapall <4-O>       :wincmd\ o<CR>
Mapall <4-S-Left>  :wincmd\ H<CR>
Mapall <4-S-Down>  :wincmd\ J<CR>
Mapall <4-S-Up>    :wincmd\ K<CR>
Mapall <4-S-Right> :wincmd\ L<CR>
Mapall <4-H>       :wincmd\ H<CR>
Mapall <4-J>       :wincmd\ J<CR>
Mapall <4-K>       :wincmd\ K<CR>
Mapall <4-L>       :wincmd\ L<CR>

" Tabs
" -- gt
Mapall  <4-t> :tabnew<CR>
Mapall  <4-T> :tabnew<CR>
Mapall  <4-{> :tabprevious<CR>
Mapall  <4-}> :tabnext<CR>
Mapall  <4-_> :execute\ 'tabmove\ '.(tabpagenr()-2)<CR>
Mapall  <4-+> :execute\ 'tabmove\ '.tabpagenr()<CR>
noremap gt    :wincmd gf<CR>

" Quickfix window
Mapall <4-x> :copen<CR>

" Plugin: Command-T
Mapall  <4-o>         :CommandT<CR>
Mapall  <4-b>         :CommandTBuffer<CR>
Mapall  <4-t>         :tabnew<CR>:CommandT<CR>
noremap <Leader><C-t> :CommandTFlush<CR>:echo 'Command-T flushed!'<CR>

" Plugin: NERDTree
Mapall <4-d> :NERDTreeToggle<CR>
Mapall <4-D> :NERDTreeFind<CR>

" Plugin: Taglist
Mapall <4-i> :TlistToggle<CR>
Mapall <4-I> :TlistOpen<CR>

" Plugin: Ack.vim
Mapall <4-A> q:iAck<Space>

" Plugin: Gundo
Mapall <4-u> :GundoToggle<CR>

" Plugin: TRegisters
Mapall <4-y> :TRegisters<CR>

" Plugin: Preview
Mapall <4-P> :Preview<CR>

" Plugin: Open URLs and files
Mapall <4-U> :Open<CR>


""" Buffer commands

" Open Files
noremap <Leader>e<Space> :tabedit<Space>
noremap <Leader>ev       :execute 'tabedit '.resolve(expand($MYVIMRC))<CR>
noremap <Leader>ea       :execute 'tabedit '.resolve(expand('~/.vim/scripts/autocommands.vim'))<CR>
noremap <Leader>ec       :execute 'tabedit '.resolve(expand('~/.vim/scripts/commands.vim'))<CR>
noremap <Leader>em       :execute 'tabedit '.resolve(expand('~/.vim/scripts/mappings.vim'))<CR>
noremap <Leader>ep       :execute 'tabedit '.resolve(expand('~/.nerv_profile'))<CR>
noremap <Leader>en       :tabnew<CR>:lcd ~/.notes/<CR>:CommandT<CR>
noremap <Leader>eN       :tabnew<CR>:Note<CR>
noremap <Leader>et       :tabedit ~/.notes/TODO<CR>
noremap <Leader>es       :tabnew<CR>:Scratch<CR>
noremap <Leader>eS       :execute 'tabedit '.resolve(expand('~/.vim/bundle/snipmate/snippets'))<CR>

" Set Filetypes
noremap <Leader>f<Space> :setlocal filetype=
noremap <Leader>f?       :setlocal filetype?<CR>
noremap <Leader>fb       :setlocal filetype=sh<CR>
noremap <Leader>fc       :setlocal filetype=c<CR>
noremap <Leader>fd       :setlocal filetype=diff<CR>
noremap <Leader>fh       :setlocal filetype=html<CR>
noremap <Leader>fj       :setlocal filetype=javascript<CR>
noremap <Leader>fm       :setlocal filetype=markdown<CR>
noremap <Leader>fM       :setlocal filetype=mail<CR>
noremap <Leader>fn       :setlocal filetype=notes<CR>
noremap <Leader>fp       :setlocal filetype=plain<CR>
noremap <Leader>fr       :setlocal filetype=ruby<CR>
noremap <Leader>fs       :setlocal filetype=sh<CR>
noremap <Leader>fv       :setlocal filetype=vim<CR>
" Plugin: Shebang
noremap <Leader>fx       :call SetExecutable()<CR>

" Save / Exit
" -- Q
Mapall  <4-s>      :update<CR>
Mapall  <4-S>      :w\ !sudo\ tee\ %\ >/dev/null<CR>
noremap Q          :q<CR>
Mapall  <4-Bslash> :q<CR>
Mapall  <4-Bar>    :q!<CR>

" Reload files
noremap <Leader><C-r>
    \ :source ~/.vim/scripts/mappings.vim<CR>
    \ :source ~/.vim/scripts/commands.vim<CR>
    \ :call ReloadAllSnippets()<CR>
    \ :echo 'Mappings, Commands, and Snippets reloaded!'<CR>
noremap <Leader>5
    \ :if &filetype == 'vim'<CR>
    \   :execute 'source %'<CR>
    \ :endif<CR><CR>


""" Text editing

" Add numbers in selection
vnoremap + "ey:ruby
    \ e = VIM.evaluate('@e').scan(/(\d+(?:\.\d+))/).flatten.map(&:to_f).inject(:+);
    \ VIM.command("let @e = '#{e}'");
    \ print e<CR>

" Center on next match
" - n NN
nnoremap n nzz
nnoremap N Nzz

" Join lines
Mapall <Leader><C-j> <C-o> J

" Select all
noremap <4-a> ggVG

" Kill trailing whitespace
noremap <Leader><C-k> mK:%s/[ \t\r]\+$//e<CR>:let @/ = ''<CR>`K

" Insert common characters
noremap  <M-CR> i\n<Esc><Right>
noremap! <M-CR> \n
noremap  <4-CR> A;<Esc>
noremap! <4-CR> <C-o>A;

" Remap <C-space> to word completion (terminal sends NUL, interestingly)
noremap! <Nul> <C-n>

" map and arrow
noremap! <C-l> <Space>=><Space>

" Indent lines a la TextMate
nnoremap <4-[> <<
nnoremap <4-]> >>
inoremap <4-[> <C-o><<
inoremap <4-]> <C-o>>>
vnoremap <4-[> <gv
vnoremap <4-]> >gv

" http://vim.wikia.com/wiki/Moving_lines_up_or_down
nnoremap <M-j> :m+<CR>==
nnoremap <M-k> :m-2<CR>==
inoremap <M-j> <Esc>:m+<CR>==gi
inoremap <M-k> <Esc>:m-2<CR>==gi
vnoremap <M-j> :m'>+<CR>gv=gv
vnoremap <M-k> :m-2<CR>gv=gv

" http://vim.wikia.com/wiki/Drag_words_with_Ctrl-left/right
vnoremap <M-h> <Esc>`<<Left>i_<Esc>mz"_xgvx`zPgv<Left>o<Left>o
vnoremap <M-l> <Esc>`><Right>gvxpgv<Right>o<Right>o

" FIXME: Doesn't work so hot
" Paste from clipboard
if g:VIM_PLATFORM == 'macunix'
    nnoremap <4-V> mVi<CR><Esc>`Va<C-o>:r!pbpaste<CR><Esc>J`VJ
    inoremap <4-V> <C-o>mV<CR><Esc>`Va<C-o>:r!pbpaste<CR><Esc>J`VJi
    vnoremap <4-V> xmVi<CR><Esc>`Va<C-o>:r!pbpaste<CR><Esc>J`VJ
else
    nnoremap <4-V> mVi<CR><Esc>`Va<C-o>:r!xclip -o<CR><Esc>J`VJ
    inoremap <4-V> <C-o>mV<CR><Esc>`Va<C-o>:r!xclip -o<CR><Esc>J`VJi
    vnoremap <4-V> xmVi<CR><Esc>`Va<C-o>:r!xclip -o<CR><Esc>J`VJ
endif

" Plugin: surround.vim - visual surround shortcuts (a la TextMate)
" -- ( '
vmap ( s(
vmap ' s'

" Plugin: Align
noremap <Leader>a<Space> :Align<Space>
noremap <Leader>a<C-l>   :Align =><CR>

" Plugin: operator-camelize
nmap <Leader>+ viw<Plug>(operator-camelize)
vmap <Leader>+ <Plug>(operator-camelize)
nmap <Leader>_ viw<Plug>(operator-decamelize)
vmap <Leader>_ <Plug>(operator-decamelize)

" Plugin: NERD_commenter (assigning to <plug> via Mapall doesn't seem to work)
map  <4-/> <plug>NERDCommenterToggleAlign
map! <4-/> <Esc><plug>NERDCommenterToggleAlign

" Plugin: closetag
noremap! <4-.> <C-r>=GetCloseTag()<CR>
noremap  <4-.> a<C-r>=GetCloseTag()<CR><Esc>
