""" Terminal Settings
" http://vim-fr.org/index.php/Julm

if !has('gui_running')
    set mouse=a         " enable full mouse support
    set ttymouse=xterm2 " more accurate mouse tracking
    set ttyfast         " more redrawing characters sent to terminal

    " Goddammit Apple, just enable 256 colors
    if g:VIM_PLATFORM == 'macunix' && $TERM_PROGRAM == 'Apple_Terminal'
        let &t_Co = 16
    elseif &term =~ '^rxvt-unicode' || &term =~ '^xterm'
        " From ECMA-48:
        "   OSC - OPERATING SYSTEM COMMAND:
        "     Representation: 09/13 or ESC 05/13 (this is \033] here)
        "     OSC is used as the opening delimiter of a control string for
        "     operating system use.  The command string following may consist
        "     of a sequence of bit combinations in the range 00/08 to 00/13 and
        "     02/00 to 07/14.  The control string is closed by the terminating
        "     delimiter STRING TERMINATOR (ST).  The interpretation of the
        "     command string depends on the relevant operating system.
        " From :h t_SI:
        "   Added by Vim (there are no standard codes for these):
        "     t_SI start insert mode (bar cursor shape)
        "     t_EI end insert mode (block cursor shape)
        let &t_SI = "\033]12;rgb:00/CC/FF\007"
        let &t_EI = "\033]12;rgb:FF/F5/9B\007"

        :silent !echo -ne "\033]12;rgb:FF/F5/9B\007"

        augroup Terminal
            autocmd!
            autocmd VimLeave * :silent :!echo -ne "\033]12;rgb:FF/F5/9B\007"
        augroup END
    elseif &term =~ '^screen'
        " From man screen:
        "   Virtual Terminal -> Control Sequences:
        "     ESC P  (A)  Device Control String
        "                 Outputs a string directly to the host
        "                 terminal without interpretation.
        "     ESC \  (A)  String Terminator
        let &t_SI = "\033P\033]12;rgb:00/CC/FF\007\033\\"
        let &t_EI = "\033P\033]12;rgb:FF/F5/9B\007\033\\"

        :silent !echo -ne "\033P\033]12;rgb:FF/F5/9B\007\033\\"

        augroup Terminal
            autocmd!
            autocmd VimLeave * :silent :!echo -ne "\033P\033]12;rgb:FF/F5/9B\007\033\\"
        augroup END
    endif
endif
