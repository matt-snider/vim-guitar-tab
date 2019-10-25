" Vim Guitar Tab
"
" plugin

if exists('g:loaded_guitar_tab')
    finish
endif
let g:loaded_guitar_tab = 1

command! -nargs=0 -bar GuitarTabChordHover call guitartab#hover_chord()

" Map enter to open chord diagram if present
noremap <expr><buffer> <CR> guitartab#kbd_enter()

