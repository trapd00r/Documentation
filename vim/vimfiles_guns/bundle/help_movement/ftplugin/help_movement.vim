" help_movement.vim: Movement over Vim help sections with ]] etc. 
"
" DEPENDENCIES:
"   - CountJump.vim, CountJump/Motion.vim autoload scripts.
"
" Copyright: (C) 2009-2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
" 1.00.002	03-Aug-2010	Published. 
"	001	16-Feb-2009	file creation

" Avoid installing when in unsupported Vim version. 
if v:version < 700
    finish
endif 

"			Move around Vim help sections (starting with a =====
"			line). 
"]]			Go to [count] next start of a help section. 
"][			Go to [count] next end of a help section. 
"[[			Go to [count] previous start of a help section. 
"[]			Go to [count] previous end of a help section. 

call CountJump#Motion#MakeBracketMotion('<buffer>', '', '', '^=\{10,}$\n\zs', '^.*\n=\{10,}$', 0)

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
