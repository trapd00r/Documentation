""" Assorted Commands and Functions

" FIXME: Make me work better with <plug> mappings "{{{
" DRY up repetitive noremap, noremap! invocations
command! -nargs=+ Mapall   call <SID>Mapall('nore', <f-args>)
command! -nargs=+ Remapall call <SID>Mapall('',     <f-args>)
function! <SID>Mapall(prefix, map, ...)
    if a:0 == 1
        let esc='<Esc>'
        let seq=a:1
        let endesc=''
    elseif a:0 == 2
        let esc=a:1
        let seq=a:2
        let endesc=''
    elseif a:0 == 3
        let esc=a:1
        let seq=a:2
        let endesc=a:3
    else
        return
    endif

    execute a:prefix.'map  <special> '.a:map.' '.seq
    execute a:prefix.'map! <special> '.a:map.' '.esc.seq.endesc
endfunction " }}}


" Alias and nullify old mapping {{{
command! -nargs=+ -bang PreserveMap call <SID>PreserveMap('<bang>', <f-args>)
function! <SID>PreserveMap(bang, new, old)
    execute 'noremap'.a:bang.' '.a:new.' '.a:old
    execute     'map'.a:bang.' '.a:old.' <C-c>'
endfunction "}}}


command! -nargs=+ SetWhitespace call <SID>SetWhitespace(<f-args>) "{{{
function! <SID>SetWhitespace(width, ...)
    let &l:shiftwidth  = a:width
    let &l:softtabstop = a:width
    if a:0
        let &l:tabstop = a:1
    else
        let &l:tabstop = a:width
    endif
endfunction "}}}


command! -nargs=+ SetTextwidth call <SID>SetTextwidth(<f-args>) "{{{
function! <SID>SetTextwidth(width, ...)
    let &l:textwidth = a:width
    let &l:formatprg = 'par qrw'.a:width
    if a:0 && a:1 == 'autowrap'
        setlocal formatoptions+=aw formatoptions-=c
    endif
endfunction "}}}


" TextMate style syntax highlighting stack for word under cursor "{{{
" http://vimcasts.org/episodes/creating-colorschemes-for-vim/
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunction "}}}
noremap <4-p> :call <SID>SynStack()<CR>


" TextMate's Todo.bundle via grep + quickfix "{{{
command! Todo call <SID>Todo()
function! <SID>Todo()
    let words=['TODO:', 'FIXME:', 'NOTE:', 'WARNING', 'DEBUG', 'HACK',]

    " Fugitive detects Git repos for us
    if exists(':Ggrep')
        execute 'silent! Ggrep -Ew "'.join(words,'|').'"'
    elseif exists(':Ack')
        execute 'silent! Ack -w "'.join(words,'\|').'"'
    else
        execute 'silent! grep -r -Pw "'.join(words,'\|').'" .' | botright copen
    endif
endfunction "}}}


" A sometimes useful command for interleaving lines of a diff
command! -range Interleave
    \ '<,'>! ruby -e 'l = STDIN.read.lines; puts l.take(l.count/2).zip(l.drop l.count/2).join'


" http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
command! Hitest
    \ 45vnew | source $VIMRUNTIME/syntax/hitest.vim | setlocal synmaxcol=5000 nocursorline nocursorcolumn


" From vimrc_example.vim:
" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
command! DiffOrig
    \ vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
