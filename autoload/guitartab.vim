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
    let chord_data = guitartab#chords#lookup(a:chord)
    let diagram = s:chord_diagram(chord_data)
    let pos = getpos('.')
    let bufnr = bufnr('%')
    let float_win_id = nvim_open_win(bufnr, v:true, {
    \   'relative': 'cursor',
    \   'anchor': 'NE',
    \   'row': 1,
    \   'col': 1,
    \   'width': 20,
    \   'height': len(diagram) + 1,
    \ })

    enew!
    let popup_bufnr = bufnr('%')
    setlocal
        \ buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nonumber
        \ nocursorline wrap nonumber norelativenumber signcolumn=no nofoldenable
        \ nospell nolist nomodeline
    call setline(1, diagram)
    setlocal nomodified nomodifiable
endfunction


function! s:chord_diagram(chord_data) abort
    let min_fret = 30
    let max_fret = 0
    for string in a:chord_data
        if guitartab#chords#is_open_or_muted(string)
            continue
        endif

        if string.fret > max_fret
            let max_fret = string.fret
        endif
        if string.fret < min_fret
            let min_fret = string.fret
        endif
    endfor

    " The nut position or bottom of diagram
    let nut_pos = max([0, max_fret - 4])

    " Since we have our chord diagrams organized string by string
    " but the diagram is best created fret-by-fret down the board,
    " we need to restructure our `a:chord_data`.
    " This creates a grid of 6 strings by 4 frets:
    " [ [s0, s1, s2, s3, s4, s5]
    "   [s0, s1, s2, s3, s4, s5]
    "   [s0, s1, s2, s3, s4, s5]
    "   [s0, s1, s2, s3, s4, s5]]
    let diagram = s:Diagram()

    let string_idx = 0
    for string in a:chord_data
        if !guitartab#chords#is_open_or_muted(string)
            let fret_idx = string.fret - nut_pos - 1
            let diagram[fret_idx][string_idx] = string.finger
        endif
        let string_idx += 1
    endfor

    return s:convert_diagram_to_text(diagram)
endfunction


function! s:convert_diagram_to_text(diagram)
    " The line representing a fret
    let fret_line = repeat("-", 16)

    " Convert to text
    let lines = []
    for row in a:diagram
        let line = ""
        for val in row
            if val is v:null
                let line .= "|"
            else
                let line .= val
            endif
            let line .= "  "
        endfor

        " Add fret line, and then line
        call add(lines, fret_line)
        call add(lines, line)
    endfor

    " Add the last fret line
    call add(lines, fret_line)

    return lines
endfunction

" Builds a 2D List representing a chord diagram
" We create it fret-by-fret (or row-by-row) and
" there are 4 frets.
function! s:Diagram()
    let diagram = []
    for _ in range(4)
        call add(diagram, repeat([v:null], 6))
    endfor
    return diagram
endfunction

