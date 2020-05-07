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

" Timer commands
command! -nargs=0 -bar GuitarTabAutoscroll call guitartab#autoscroll_start(500)
command! -nargs=0 -bar GuitarTabAutoscrollStop call guitartab#autoscroll_stop()
command! -nargs=0 -bar GuitarTabAutoscrollFaster call guitartab#autoscroll_faster(100)
command! -nargs=0 -bar GuitarTabAutoscrollSlower call guitartab#autoscroll_slower(100)

" Timer bindings
nmap + :GuitarTabAutoscrollFaster<CR>
nmap - :GuitarTabAutoscrollSlower<CR>

