""" Vim Autocommands

augroup GUNS
    autocmd!

    " From vimrc_example.vim:
    " When editing a file, always jump to the last known cursor position.  Don't
    " do it when the position is invalid or when inside an event handler (happens
    " when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   execute "normal! g`\"" |
        \ endif

    " When jumping to the first error in a quickfix list after :make, open
    " a new tab first
    autocmd QuickfixCmdPost *
        \ let b:qflist = filter(getqflist(), 'v:val["bufnr"]') |
        \ if len(b:qflist) && b:qflist[0]['bufnr'] != bufnr('%') |
        \   tabnew |
        \ endif

    " Vimscript
    autocmd FileType vim
        \ setlocal foldmethod=marker |
        \ SetWhitespace 4 8

    " Diff
    autocmd FileType diff
        \ setlocal foldmethod=diff foldlevel=0 |
        \ SetWhitespace 8

    " Shell
    autocmd BufRead,BufNewFile *profile,rc.conf
        \ setlocal filetype=sh
    autocmd FileType sh
        \ setlocal foldmethod=indent |
        \ SetWhitespace 4 8

    " Lisp
    autocmd Filetype lisp,scheme
        \ setlocal equalprg=~/.vim/scmindent/bin/lispindent.lisp |
        \ SetWhitespace 2 8

    " Ruby
    autocmd BufRead,BufNewFile *.irbrc,config.ru,Gemfile
        \ setlocal filetype=ruby
    autocmd FileType ruby,eruby
        \ setlocal makeprg=rake |
        \ setlocal iskeyword+=?,! |
        \ execute 'noremap <buffer> <Leader><C-b> :B<CR>' |
        \ SetWhitespace 2 8

    " PHP
    autocmd FileType php
        \ setlocal iskeyword-=- |
        \ SetWhitespace 2

    " X?HTML/XML
    autocmd FileType html,xhtml,xml
        \ setlocal matchpairs+=<:> |
        \ SetWhitespace 2

    " HAML/SASS/YAML
    autocmd FileType haml,sass,yaml
        \ setlocal foldmethod=indent |
        \ SetWhitespace 2
    autocmd FileType haml
	\ execute 'noremap  <M-CR> i%br<Esc><Right>' |
	\ execute 'noremap! <M-CR> %br'

    " CSS
    autocmd FileType css
        \ SetWhitespace 4

    " JavaScript
    autocmd FileType javascript
        \ execute 'noremap <buffer> <Leader>M :JSLintUpdate<CR>' |
        \ SetWhitespace 2

    " C
    autocmd FileType c
        \ SetWhitespace 4 8 |
        \ setlocal cinoptions=:0 iskeyword-=- makeprg=make\ -j2 |
        \ noremap! <buffer> <C-l> ->

    " Nginx
    autocmd BufRead,BufNewFile /usr/local/etc/nginx/*.conf,nginx.conf
        \ setlocal filetype=nginx
    autocmd FileType nginx
        \ setlocal iskeyword-=.,/,: |
        \ SetWhitespace 4

    " Ini conf
    autocmd BufRead,BufNewFile *gitconfig
        \ setlocal filetype=gitconfig
    autocmd FileType ini,gitconfig
        \ SetWhitespace 4

    " Apache conf
    autocmd FileType apache
        \ SetWhitespace 4

    " XDefaults
    autocmd BufRead,BufNewFile *Xdefaults
        \ setlocal filetype=xdefaults

    " SnipMate snippets
    autocmd FileType snippet
        \ SetWhitespace 8

    " Markdown
    autocmd BufRead,BufNewFile *.md,*.mkd,*.mdown
        \ setlocal filetype=markdown
    autocmd FileType markdown,rdoc
        \ setlocal wrap |
        \ execute 'SetTextwidth 80' |
        \ SetWhitespace 4

    " Mail
    autocmd BufRead,BufNewFile editserver-*
        \ setlocal filetype=mail
    autocmd FileType mail
        \ setlocal noexpandtab wrap |
        \ execute 'SetTextwidth 72 autowrap' |
        \ SetWhitespace 4

    " Archive browsing
    autocmd BufReadCmd *.jar,*.xpi,*.pk3
        \ call zip#Browse(expand("<amatch>"))
    autocmd BufReadCmd *.gem
        \ call tar#Browse(expand("<amatch>"))

    " git
    autocmd FileType gitcommit
        \ SetTextwidth 72 autowrap

    " tmux
    autocmd BufRead,BufNewFile *.tmux.conf
        \ setlocal filetype=tmux

    " http logs
    autocmd BufRead *access.log*
        \ setlocal filetype=httplog

    " Applescript (which sucks)
    autocmd BufRead,BufNewFile *.applescript
        \ setlocal filetype=applescript

    " Readline
    autocmd BufRead,BufNewFile *.inputrc
        \ setlocal filetype=readline

    " Nethack!
    autocmd BufRead,BufNewFile *.des
        \ setlocal filetype=nhdes

    " TeX
    autocmd FileType tex
        \ setlocal iskeyword+=\\ makeprg=rake |
        \ execute 'map <buffer> <Leader>M :BuildAndViewTexPdf<CR>' |
        \ execute 'SetTextwidth 80 autowrap' |
        \ SetWhitespace 2

    " CTags
    autocmd BufRead,BufNewFile .tags
        \ setlocal filetype=tags

augroup END

" screen.vim
augroup ScreenShellEnter
    autocmd!
    autocmd User *
        \ execute 'vmap <Leader><Leader> :ScreenSend<CR>' |
        \ execute 'nmap <Leader><Leader> mSvip<Leader><Leader>`S' |
        \ execute 'imap <Leader><Leader> <Esc><Leader><Leader><Right>'
augroup END

augroup ScreenShellExit
    autocmd!
    autocmd User *
        \ execute 'vunmap <Leader><Leader>' |
        \ execute 'nunmap <Leader><Leader>' |
        \ execute 'iunmap <Leader><Leader>'
augroup END
