" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! visualctrlg#load() "{{{
    " dummy function to load this script.
endfunction "}}}


function! visualctrlg#report(verbose) "{{{
    let default = 1
    let sleep_arg = v:count != 0 ? v:count : default
    let text = s:get_selected_text()

    let lines_num = getpos("'>")[1] - getpos("'<")[1] + 1
    if a:verbose
        echo printf('%d line(s), %d byte(s), %d char(s), %d width, %d display width',
        \           lines_num, strlen(text), s:strchars(text), s:strwidth(text), s:strdisplaywidth(text))
    else
        echo printf('%d line(s), %d byte(s), %d char(s)',
        \           lines_num, strlen(text), s:strchars(text))
    endif

    " Sleep to see the output in command-line.
    execute 'sleep' sleep_arg
endfunction "}}}

function! visualctrlg#report_verbosely(...) "{{{
    return call('visualctrlg#report', [1] + a:000)
endfunction "}}}

function! visualctrlg#report_briefly(...) "{{{
    return call('visualctrlg#report', [0] + a:000)
endfunction "}}}


function! s:get_selected_text() "{{{
    let save_z      = getreg('z', 1)
    let save_z_type = getregtype('z')
    try
        silent normal! gv"zy
        return @z
    finally
        call setreg('z', save_z, save_z_type)
    endtry
endfunction "}}}

" strchars() {{{
if exists('*strchars')
    let s:strchars = function('strchars')
else
    function! s:strchars(expr)
        return strlen(substitute(a:expr, '.', 'x', 'g'))
    endfunction
endif
" }}}
" strwidth() {{{
if exists('*strwidth')
    let s:strwidth = function('strwidth')
else
    " From s:wcswidth() of googlereader.vim. mattn++
    function! s:strwidth(expr)
        let mx_first = '^\(.\)'
        let str = a:expr
        let width = 0
        while 1
            let ucs = char2nr(substitute(str, mx_first, '\1', ''))
            if ucs == 0
                break
            endif
            let width = width + s:wcwidth(ucs)
            let str = substitute(str, mx_first, '', '')
        endwhile
        return width
    endfunction
    " From s:wcwidth() of googlereader.vim. ++mattn++
    " (yes, I know the difference between lvalue and rvalue.
    " it results in "error: lvalue required as increment operand" in gcc.)
    function! s:wcwidth(expr)
        " XXX: 'ambiwidth', 'display'
        let ucs = a:expr
        if (ucs >= 0x1100
        \  && (ucs <= 0x115f
        \  || ucs == 0x2329
        \  || ucs == 0x232a
        \  || (ucs >= 0x2e80 && ucs <= 0xa4cf
        \      && ucs != 0x303f)
        \  || (ucs >= 0xac00 && ucs <= 0xd7a3)
        \  || (ucs >= 0xf900 && ucs <= 0xfaff)
        \  || (ucs >= 0xfe30 && ucs <= 0xfe6f)
        \  || (ucs >= 0xff00 && ucs <= 0xff60)
        \  || (ucs >= 0xffe0 && ucs <= 0xffe6)
        \  || (ucs >= 0x20000 && ucs <= 0x2fffd)
        \  || (ucs >= 0x30000 && ucs <= 0x3fffd)
        \  ))
            return 2
        endif
        return 1
    endfunction
endif
" }}}
" strdisplaywidth() {{{
if exists('*strdisplaywidth')
    let s:strdisplaywidth = function('strdisplaywidth')
else
    " From s:strdisplaywidth() of autofmt.vim. ynkdir++
    function s:strdisplaywidth(str, ...)
        let vcol = get(a:000, 0, 0)
        let w = 0
        for c in split(a:str, '\zs')
            if c == "\t"
                let w += &tabstop - ((vcol + w) % &tabstop)
            elseif c =~ '^.\%2v'  " single-width char
                let w += 1
            elseif c =~ '^.\%3v'  " double-width char or ctrl-code (^X)
                let w += 2
            elseif c =~ '^.\%5v'  " <XX>    (^X with :set display=uhex)
                let w += 4
            elseif c =~ '^.\%7v'  " <XXXX>  (e.g. U+FEFF)
                let w += 6
            endif
        endfor
        return w
    endfunction
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
