""" Syntax Initialization

if has('syntax')
    syntax on
    set synmaxcol=160 " if you need more than this use another tool

    if &t_Co == 256
        set cursorline
        let g:jellyx_show_whitespace=1
        colorscheme jellyx
    else
        " fall back on invisibles for showing whitespace errors
        set list
        colorscheme peachpuff
    endif
endif
