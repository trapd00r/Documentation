" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: December 4, 2010
" URL: http://peterodding.com/code/vim/open-associated-programs/
" Version: 1.2.1

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 3242 1 :AutoInstall: open-associated-programs.zip

if !exists('s:script')
  let s:script = expand('<sfile>:p:~')
  let s:enoimpl = "%s: %s() hasn't been implemented for your platform!"
  let s:enoimpl .= " If you have suggestions, please contact peter@peterodding.com."
  let s:handlers = ['gnome-open', 'kde-open', 'exo-open', 'xdg-open']
endif

function! xolox#open#file(path, ...)
  if !system('id -u')
    echo 'Do not open files as root!'
    return
  elseif filereadable('/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder')
    let cmd = 'open ' . shellescape(a:path) . ' 2>&1'
    call s:handle_error(cmd, system(cmd))
    return
  else
    for handler in s:handlers + a:000
      if executable(handler)
        call xolox#debug("%s: Using `%s' to open %s", s:script, handler, a:path)
        let cmd = shellescape(handler) . ' ' . shellescape(a:path) . ' 2>&1'
        call s:handle_error(cmd, system(cmd))
        return
      endif
    endfor
  endif
  throw printf(s:enoimpl, s:script, 'xolox#open#file')
endfunction

function! xolox#open#url(url)
  let url = a:url
  if url !~ '^\w\+://'
    if url !~ '@'
      let url = 'http://' . url
    elseif url !~ '^mailto:'
      let url = 'mailto:' . url
    endif
  endif
  if has('unix') && !has('gui_running') && $DISPLAY == ''
    for browser in ['lynx', 'links', 'w3m']
      if executable(browser)
        execute '!' . browser fnameescape(url)
        call s:handle_error(browser . ' ' . url, '')
        return
      endif
    endfor
  endif
  call xolox#open#file(url, 'firefox', 'google-chrome')
endfunction

function! s:handle_error(cmd, output)
  if v:shell_error
    let message = "%s: Failed to execute program! (command line: %s%s)"
    let output = strtrans(xolox#trim(a:output))
    if output != ''
      let output = ", output: " . string(output)
    endif
    throw printf(message, s:script, a:cmd, output)
  endif
endfunction

" vim: et ts=2 sw=2 fdm=marker
