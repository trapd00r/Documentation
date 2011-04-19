" Shebang: Automatically set shebang based on the filetype
" Author:  Johannes Hoff
" Date:    Dec 13, 2010

function! SetExecutableBit()
	" This function is taken from
	" http://vim.wikia.com/wiki/Setting_file_attributes_without_reloading_a_buffer
	" Thanks Max Ischenko!
	let fname = expand("%:p")
	checktime
	execute "au FileChangedShell " . fname . " :echo"
	silent !chmod a+x %
	checktime
	execute "au! FileChangedShell " . fname
endfunction

function! SetShebang()
python << endpython
import vim
shebang = {
	'python': '#!/usr/bin/env python',
	'ruby':   '#!/usr/bin/env ruby',
	'bash':   '#!/usr/bin/env bash',
	'sh':     '#!/bin/sh',
}
if not vim.current.buffer[0].startswith('#!'):
	filetype = vim.eval('&filetype')
	if filetype in shebang:
		vim.current.buffer[0:0] = [ shebang[filetype] ]
endpython
endfunction

function! SetExecutable()
	call SetExecutableBit()
	call SetShebang()
endfunction

