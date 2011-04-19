
"  __     ___
"  \ \   / (_)_ __ ___
"   \ \ / /| | '_ ` _ \   Ftw
"    \ V / | | | | | | |
"     \_/  |_|_| |_| |_|  guns <sung@metablu.com>
"

if version < 702
    echo 'WARNING: Minimum vim version 7.2 not met, skipping $MYVIMRC'
    finish
endif


""" Meta """

" Clear all autocommands now
autocmd!

" Pathogen
syntax off filetype off         " must be off before calling pathogen
call pathogen#runtime_append_all_bundles()
filetype plugin indent on

" Custom platform detection
if filereadable('/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder')
    " has('macunix') doesn't describe vim compiled on OS X with --disable-darwin
    let g:VIM_PLATFORM='macunix'
elseif has('unix')
    let g:VIM_PLATFORM='unix'
endif

set nocompatible                " break away from crusty vi compatibility
set fileformats=unix            " support Unix LF only!
set history=1024                " default command history = 20
set backspace=indent,eol,start  " More intuitive backspace
set tags=.tags,tags


""" User Interface """

" Terminal-related settings
source ~/.vim/scripts/term.vim

" Turn on syntax and apply some global rules
source ~/.vim/scripts/syntax.vim

" Line wrapping
set nowrap                      " no soft wrap by default
set linebreak                   " but if gets turned on, break on words
set showbreak=…                 " and give us a nice visual indicator
set textwidth=0                 " don't break lines by default
set formatprg=par\ qrw80        " wrap with par at 80 chars if we call gq

" Wildmenu / Completions
set wildmenu                    " turn on command mode completion menu
set wildmode=list:longest       " completion list and match till longest
set completeopt=menu,longest,preview " more autocomplete <Ctrl>-P options
set wildignore+=*.o,*.jpg,*.jpeg,*.png,*.gif,*.tif,*.tiff,.DS_Store,Thumbs.db

" Folding
set foldmethod=syntax           " Use syntax to define folds by default
set foldlevelstart=99           " But don't fold anything at the outset

" Gutter / Status line
set number                      " yay line numbers
set ruler                       " show current position at bottom
set showcmd                     " show (partial) command in status line

" Messages
set report=0                    " report back on all changes
set shortmess=aoOstTI           " shorter and truncated messages; no intro

set nostartofline               " leave my cursor position alone!
set visualbell t_vb=            " don't make faces
set listchars=tab:▸\ ,trail:·   " Nice UTF-8 listchars for :set list


""" Text Editing """

" t - autowrap to textwidth
" c - autowrap comments to textwidth
" r - autoinsert comment leader with <Enter>
" q - allow formatting of comments with :gq
" l - don't format already long lines
" n - recognize numbered lists
" 1 - Don't break a line after a 1-letter word
set formatoptions=tcrqln1
set iskeyword+=-                " append to valid word chars

" Indenting / Tabs
set autoindent                  " set the cursor at same indent as line above
set copyindent                  " use existing indents for new indents
set shiftround                  " always round indents to multiple of shiftwidth
set expandtab                   " expand <Tab>s with spaces; death to tabs!
set shiftwidth=4                " autoindent mulitple
set tabstop=8                   " hard tab width
set softtabstop=4               " soft tab width

" Searching / Matching
set hlsearch                    " highlighting for searched patterns
set incsearch                   " highlight as we search however
set ignorecase                  " set case insensitivity
set smartcase                   " unless there's a capital letter

" Clipboard
if has('unnamedplus-that-really-truly-works')
    set clipboard=unnamedplus   " use X11 SYSTEM clipboard
else
    set clipboard=unnamed       " use X11 PRIMARY clipboard (selection)
endif

" Timeouts
set notimeout                   " Don't timeout on keymappings
set ttimeout                    " but timeout otherwise


"" Global Options """

" Bash
let g:is_bash=1
let g:readline_has_bash=1
let g:sh_minlines=300

" Ruby
let g:ruby_operators=1
let g:ruby_fold=1

" JavaScript
let g:javascript_enable_domhtmlcss=1

" Vim
let g:vimsyn_folding='afmpPrt'
let g:vim_indent_cont=4

" Javadoc
let g:java_javascript=1
let g:java_css=1
let g:java_vb=1

" TeX
let g:tex_fold_enabled=1

" Plugin: TeX-PDF
let g:tex_pdf_map_keys=0
let g:tex_flavor='xelatex'

" Plugin: closetag
let g:closetag_html_style=1

" Plugin: CommandT
let g:CommandTMatchWindowAtTop=1
let g:CommandTAlwaysShowDotFiles=1

" Plugin: NERDTree
let g:NERDChristmasTree=1
let g:NERDTreeChDirMode=2
let g:NERDTreeDirArrows=1
let g:NERDTreeHijackNetrw=0
let g:NERDTreeMinimalUI=1
let g:NERDTreeMouseMode=2
let g:NERDTreeQuitOnOpen=0
let g:NERDTreeShowHidden=1
let g:NERDTreeWinPos='right'

" Plugin: NERDCommenter
let g:NERDSpaceDelims=1
let g:NERDCompactSexyComs=1

" Plugin: delimitMate (expand <CR> still breaks undo/redo)
let g:delimitMate_expand_cr=0
let g:delimitMate_expand_space=1
let g:delimitMate_excluded_regions=''
let g:delimitMate_quotes="\" '"

" Plugin: Notes.vim
let g:notes_directory='~/.notes'
let g:notes_shadowdir='~/.vim/bundle/notes.vim/misc/notes/shadow'
let g:notes_indexfile='~/.notes/.index.sqlite3'
let g:notes_indexscript='~/.vim/bundle/notes.vim/misc/notes/scanner.py'

" Plugin: vim-preview
let g:PreviewBrowsers='chrome'

" Plugin: Gnupg
let g:GPGPreferArmor=1
let g:GPGDefaultRecipients=['sung@metablu.com']

" Plugin: Tlist
let g:Tlist_GainFocus_On_ToggleOpen=1

" Plugin: CTAGS-Highlighting
let g:TypesCTagsFile='.tags'
let g:TypesPrefix='.types'
let g:TypesFileIncludeLocals=0
let g:TypesFileIncludeSynMatches=0
highlight link CTagsLocalVariable NONE
highlight link CTagsMember        NONE
highlight link CtagsDefinedName   NONE
highlight link CTagsSingleton     NONE

" Plugin: Gundo.vim
let g:gundo_width=30
let g:gundo_preview_bottom=1
let g:gundo_right=1

" Plugin: ConqueTerm
let g:ConqueTerm_InsertOnEnter=0
let g:ConqueTerm_CWInsert=1
let g:ConqueTerm_SendVisKey='<C-x><C-x>'
let g:ConqueTerm_ToggleKey='<C-x>i'
let g:ConqueTerm_Color=0
let g:ConqueTerm_TERM='xterm'
let g:ConqueTerm_CloseOnEnd=0
let g:ConqueTerm_ReadUnfocused=1
let g:ConqueTerm_Syntax=''


""" Mappings, Commands, and Autocommands """

" Set modifiers and load modifier mapping functions
source ~/.vim/scripts/modifiers.vim

" Assorted commands and functions
source ~/.vim/scripts/commands.vim

" Main mappings file
source ~/.vim/scripts/mappings.vim

" Autocommands
source ~/.vim/scripts/autocommands.vim
