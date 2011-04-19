" Vim plug-in
" Author: Peter Odding <peter@peterodding.com>
" Last Change: January 27, 2011
" URL: http://peterodding.com/code/vim/shell/
" License: MIT
" Version: 0.9.2

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 3123 1 :AutoInstall: shell.zip

" Configuration defaults. {{{1

if !exists('g:shell_patt_url')
 let g:shell_patt_url = '\<\w\{3,}://\(\S*\w\)\+[/?#]\?'
endif

if !exists('g:shell_patt_mail')
 let g:shell_patt_mail = '\<\w[^@ \t\r]*\w@\w[^@ \t\r]\+\w\>'
endif

" Regular commands. {{{1

command! -bar -nargs=? -complete=file Open call xolox#shell#open_cmd(<q-args>)

" vim: ts=2 sw=2 et fdm=marker
