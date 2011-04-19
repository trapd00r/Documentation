""" Modifier Normalization

" http://vim.wikia.com/wiki/Fix_meta-keys_that_break_out_of_Insert_mode
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim

" Set value of keycode or map in all modes {{{
command! -nargs=+ Setmap call <SID>Setmap(<f-args>)
function! <SID>Setmap(map, seq)
    " Some named values can be `set'
    try
        execute 'set '.a:map.'='.a:seq
    " but the rest can simply be mapped
    catch
        execute 'map  <special> '.a:seq.' '.a:map
        execute 'map! <special> '.a:seq.' '.a:map
    endtry
endfunction "}}}

" Named keycodes {{{
let s:keycode = {
    \ ' ': 'Space',
    \ '\': 'Bslash',
    \ '|': 'Bar',
    \ '<': 'lt'
\ } "}}}

" Normalize mod + ASCII printable chars "{{{
for n in range(0x20, 0x7e)
    let c = nr2char(n)
    let k = c

    " <M->> doesn't work
    if c == '>'
        continue
    endif

    if has_key(s:keycode, c)
        let c = s:keycode[c]
        let k = '<'.c.'>'
    endif

    " Option / Alt as Meta
    "  * M-[ is ^[[, which is terminal escape
    "  * M-" doesn't work
    "  * M-O is escape for arrow keys
    if c != '[' && c != '"' && c != 'O'
        execute 'Setmap <M-'.c.'> '.k
    endif

    " Super / Mod4
    "  * Assumes terminal sends <Esc><Space> as Mod4 prefix
    execute 'Setmap <4-'.c.'> \ '.k
endfor "}}}


""" Special Keys

" Backspace
Setmap <C-BS>       
Setmap <M-BS>       

" Arrow keys
Setmap <C-Up>       Oa
Setmap <C-Down>     Ob
Setmap <C-Right>    Oc
Setmap <C-Left>     Od

Setmap <M-Up>       <Up>
Setmap <M-Down>     <Down>
Setmap <M-Right>    <Right>
Setmap <M-Left>     <Left>

Setmap <S-Up>       [a
Setmap <S-Down>     [b
Setmap <S-Right>    [c
Setmap <S-Left>     [d

Setmap <4-Up>       \ a
Setmap <4-Down>     \ b
Setmap <4-Right>    \ c
Setmap <4-Left>     \ d

Setmap <4-S-Up>     \ A
Setmap <4-S-Down>   \ B
Setmap <4-S-Right>  \ C
Setmap <4-S-Left>   \ D

" Return
Setmap <M-CR>       
Setmap <4-CR>       \ 

" Backspace / Delete
Setmap <4-BS>       \ 


""" Syntax help for Mod4 mappings

" \c            case insensitive
" [4]           match Mod4
" bslash|bar    more keycodes
augroup EnhancedVimSyntax
    autocmd!
    autocmd Syntax vim
        \ syntax match vimNotation "\c\(\\\|<lt>\)\=<\([scamd4]-\)\{0,4}x\=\(f\d\{1,2}\|[^ \t:]\|bslash\|bar\|cr\|lf\|linefeed\|return\|k\=del\%[ete]\|bs\|backspace\|tab\|esc\|right\|left\|help\|undo\|insert\|ins\|k\=home\|k\=end\|kplus\|kminus\|kdivide\|kmultiply\|kenter\|space\|k\=\(page\)\=\(\|down\|up\)\)>" contains=vimBracket
augroup END


""" Cleanup

delcommand  Setmap
delfunction <SID>Setmap
