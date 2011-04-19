" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: January 27, 2011
" URL: http://peterodding.com/code/vim/shell/

if !exists('s:script')
  let s:script = expand('<sfile>:p:~')
  let s:enoimpl = "%s() hasn't been implemented on your platform! %s"
  let s:contact = "If you have suggestions, please contact the vim_dev mailing-list or peter@peterodding.com."
endif

function! xolox#shell#open_cmd(arg) " -- implementation of the :Open command {{{1
  try
    if a:arg !~ '\S'
      if !s:open_at_cursor()
        call xolox#open#file(expand('%:p:h'))
      endif
    elseif a:arg =~ g:shell_patt_url || a:arg =~ g:shell_patt_mail
      call xolox#open#url(a:arg)
    else
      let arg = fnamemodify(a:arg, ':p')
      if isdirectory(arg) || filereadable(arg)
        call xolox#open#file(arg)
      else
        let msg = "%s: I don't know how to open %s!"
        echoerr printf(msg, s:script, string(a:arg))
      endif
    endif
  catch
    call xolox#warning("%s at %s", v:exception, v:throwpoint)
  endtry
endfunction

function! s:open_at_cursor()
  let cWORD = expand('<cWORD>')
  " Start by trying to match a URL in <cWORD> because URLs can be more-or-less
  " unambiguously distinguished from e-mail addresses and filenames.
  let match = matchstr(cWORD, g:shell_patt_url)
  if match == ''
    " Now try to match an e-mail address in <cWORD> because most filenames
    " won't contain an @-sign while e-mail addresses require it.
    let match = matchstr(cWORD, g:shell_patt_mail)
  endif
  if match != ''
    call xolox#open#url(match)
    return 1
  else
    " As a last resort try to match a filename at the text cursor position.
    let line = getline('.')
    let idx = col('.') - 1
    let match = matchstr(line[0 : idx], '\f*$')
    let match .= matchstr(line[idx+1 : -1], '^\f*')
    " Expand leading tilde and/or environment variables in filename?
    if match =~ '^\~' || match =~ '\$'
      let match = split(expand(match), "\n")[0]
    endif
    if match != '' && (isdirectory(match) || filereadable(match))
      call xolox#open#file(match)
      return 1
    endif
  endif
endfunction

function! xolox#shell#execute(command, synchronous, ...) " -- execute external commands asynchronously {{{1
  try
    let cmd = a:command
    let has_input = a:0 > 0
    if has_input
      let tempin = tempname()
      call writefile(type(a:1) == type([]) ? a:1 : split(a:1, "\n"), tempin)
      let cmd .= ' < ' . shellescape(tempin)
    endif
    if a:synchronous
      let tempout = tempname()
      let cmd .= ' > ' . shellescape(tempout) . ' 2>&1'
    endif
    if has('unix') && !a:synchronous
      let cmd = '(' . cmd . ') &'
    endif
    call s:handle_error(cmd, system(cmd))
    if a:synchronous
      if !filereadable(tempout)
        let msg = '%s: Failed to execute %s!'
        throw printf(msg, s:script, strtrans(cmd))
      endif
      return readfile(tempout)
    else
      return 1
    endif
  catch
    call xolox#warning("%s: %s at %s", s:script, v:exception, v:throwpoint)
  finally
    if exists('tempin') | call delete(tempin) | endif
    if exists('tempout') | call delete(tempout) | endif
  endtry
endfunction

" Miscellaneous script-local functions. {{{1

function! s:handle_error(cmd, output) " {{{2
  if v:shell_error
    let msg = "Command %s failed!"
    if a:output =~ '^\_s*$'
      throw printf(msg, string(a:cmd))
    else
      let msg .= ' (output: %s)'
      let output = strtrans(xolox#trim(a:output))
      throw printf(msg, string(a:cmd), )
    endif
  endif
endfunction

" vim: ts=2 sw=2 et fdm=marker
