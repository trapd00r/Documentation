" Filename:      reporoot.vim
" Description:   Change directory to the nearest repository root directory
" Maintainer:    Jeremy Cantrell <jmcantrell@gmail.com>
" Last Modified: Thu 2010-10-28 22:48:19 (-0400)

if exists("g:reporoot_loaded")
    finish
endif

let g:reporoot_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:Warn(message)
    echohl WarningMsg
    echo a:message
    echohl None
endfunction

function! s:IsRepo(dir)
    for type in ['svn', 'git', 'hg', 'bzr']
        if isdirectory(a:dir.'/.'.type)
            return 1
        endif
    endfor
    return 0
endfunction

function! s:RepoRoot(force, ...)
    let l:dir = a:0 == 0 ? getcwd() : a:1
    if a:force
        let l:dir = l:dir.'/..'
    endif
    if isdirectory(l:dir.'/.svn')
        execute 'cd '.l:dir
        while isdirectory('../.svn')
            cd ..
        endwhile
    else
        let l:dirbak = getcwd()
        execute 'cd '.l:dir
        while ! (getcwd() == '/' || s:IsRepo(getcwd()))
            cd ..
        endwhile
        if getcwd() == '/'
            execute 'cd '.l:dirbak
            call Warn('No repository root directory found')
        else
            pwd
        endif
    endif
endfunction

command! -nargs=? -bang RepoRoot call s:RepoRoot(strlen('<bang>'), <f-args>)

let &cpo = s:save_cpo
