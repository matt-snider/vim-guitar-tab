" Vim Guitar Tab
"
" Autoload

let s:chord_regex = '[A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?'

function! s:is_guitar_chord(chord) abort
    return a:chord =~ s:chord_regex
endfunction

function! guitartab#hover_chord() abort
    let col = col('.') - 1
    let line = getline('.')[col:]
    let parts = split(line)
    if len(line) == 0 || len(parts) == 0
        return v:false
    endif

    let chord = parts[0]
    if !s:is_guitar_chord(chord)
        return
    endif

    call guitartab#show_guitar_chord(chord)
endfunction

" Shows the given chord by name
" TODO: implement it - currently just shows G chord
function! guitartab#show_guitar_chord(chord) abort
    let lines = [
                \ "  Chord: " . a:chord,
                \ "  ----------------  ",
                \ "  |  |  |  |  |  |  ",
                \ "  ----------------  ",
                \ "  |  1  |  |  |  |  ",
                \ "  ----------------  ",
                \ "  2  |  |  |  3  4  ",
                \ "  ----------------  ",
                \ "  |  |  |  |  |  |  ",
                \ "  ----------------  ",
                \ ]
    let pos = getpos('.')
    let bufnr = bufnr('%')
    let float_win_id = nvim_open_win(bufnr, v:true, {
    \   'relative': 'cursor',
    \   'anchor': 'NE',
    \   'row': 1,
    \   'col': 1,
    \   'width': 20,
    \   'height': len(lines) + 1,
    \ })

    enew!
    let popup_bufnr = bufnr('%')
    setlocal
        \ buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nonumber
        \ nocursorline wrap nonumber norelativenumber signcolumn=no nofoldenable
        \ nospell nolist nomodeline
    call setline(1, lines)
    setlocal nomodified nomodifiable
endfunction

