
ma     " set mark 'a'
y'a    " yank lines linewise
y`a    " yank the specific position of the mark

gf     " open the file under the cursor in a new buffer (Goto File):

[|     " find the word under the cursor in libraries:
[<TAB> " to jump there

'.      " jump to the last modified line
`.      " jump to exact pos of last modification

  let foo_bar = {
    \'foo'    : 42,
    \'bar'    : 'baz',
  \}

" Extradite {{{

:Extradite toggles the commit browser.
:Extradite! opens it in a vsplit.

g:extradite_width controls the width


<CR> edits the revision on the current line in a fugitive-buffer

Edit the revision in a new

oh  split
ov  vsplit
ot  tab

Diff the current file against the revision under the cursor in a new

dh  split
dv  vsplit
dt  tab

t toggles the visibility of the file diff buffer

q closes the Extradite buffer

"}}}

" vim:tw=78:ft=vim:colorcolumn=+1
