" Vim Guitar Tab
"
" Autoload

let s:chord_regex = '[A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?'

function! s:is_guitar_chord(text) abort
    return a:text =~ s:chord_regex
endfunction

function! guitartab#kbd_enter() abort
    let col = col('.') - 1
    let line = getline('.')[col:]
    let parts = split(line)
    if len(line) == 0 || len(parts) == 0 || !s:is_guitar_chord(parts[0])
        return "\<CR>"
    endif

    " Move up one ('k') and then call hover_chord()
    return "\<ESC>k :call guitartab#hover_chord()\<CR>"
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
function! guitartab#show_guitar_chord(chord_name) abort
    let diagram = s:chord_diagram(a:chord_name)
    let pos = getpos('.')
    let bufnr = bufnr('%')
    let float_win_id = nvim_open_win(bufnr, v:true, {
    \   'relative': 'cursor',
    \   'anchor': 'NW',
    \   'row': 1,
    \   'col': 0,
    \   'width': 24,
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


function! s:chord_diagram(chord_name) abort
    let chord_data = guitartab#chords#lookup(a:chord_name)

    " Find the max and min bounds of the chord diagram
    " so we can show just a subset of the fretboard.
    let min_fret = 30
    let max_fret = 0
    for string in chord_data
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

    " Calculate the fret position of the diagram and
    " then relativize the chord to that position
    " Note: we copy so that we don't overwrite
    let fret_position = max([0, max_fret - 4])
    for string in chord_data
        if guitartab#chords#is_open_or_muted(string)
            continue
        endif

        let string.fret -= fret_position
    endfor

    " Convert our diagram to a textual representation
    let lines = []
    let fret_line = repeat('-', 16)
    let diagram = s:Diagram(chord_data, max([max_fret - min_fret, 4]))
    let idx = 0
    for row in diagram
        let line = join(row, "  ")

        " Add line of diagram
        call add(lines, s:pad(line, 3, 3))

        " Add fret line - set fret positio on the first one
        if idx == 0
            let l = fret_position . " " . fret_line
            call add(lines, s:pad(l, 1, 0))
        else
            call add(lines, s:pad(fret_line, 3, 3))
        endif

        let idx += 1
    endfor

    " Add the chord label + a new line separator
    let chord_label = a:chord_name . " Chord"
    call insert(lines, "", 0)
    call insert(lines, s:pad(chord_label, 3, 0), 0)

    return lines
endfunction


" Pads both sides of a string with `left` and `right` spaces
function! s:pad(line, left, right)
    return repeat(" ", a:left) . a:line . repeat(" ", a:right)
endfunction


" Builds a new textual grid representation of a chord as a 2-D list.
"
" The 6 elements of the first row show the guitar string's state
" using the indicators 'x' (muted), 'o' (open), or `v:null` (fretted).
"
" Each subsequent row contains 6 elements representing the fretting
" of the guitar string at that position. This is represented with
" a number indicating which finger is used (1, 2, 3, 4), or `v:null`
" to represent that the guitar string is not-fretted at that position.
"
" [
"   // string state (open, closed, fretted)
"   [s0_state, s1_state, ... s4_state, s5_state]
"   // frets
"   [f0_s0, f0_s1, ... f0_s5, f0_s6]
"   [f1_s0, f1_s1, ... f1_s5, f1_s6]
"   [f2_s0, f2_s1, ... f2_s5, f2_s6]
"   [f3_s0, f3_s1, ... f3_s5, f3_s6]
"   // ...
" ]
function! s:Diagram(chord_data, num_frets)
    let diagram = []

    " Initialize first row to guitar string state
    call add(diagram, repeat([' '], 6))

    " Initialize string positions '|'
    for _ in range(a:num_frets)
        call add(diagram, repeat(['|'], 6))
    endfor

    " Go through string-by-string and build diagram
    let string_idx = 0
    for string in a:chord_data
        if guitartab#chords#is_muted(string)
            let diagram[0][string_idx] = "x"
        elseif guitartab#chords#is_open(string)
            let diagram[0][string_idx] = "o"
        else
            " Ensure it doesn't go out of index
            if (string.fret - 1) > a:num_frets
                echoerr "Chord does not fit on diagram with " . a:num_frets . " frets!"
                return
            endif

            let diagram[string.fret][string_idx] = string.finger
        endif
        let string_idx += 1
    endfor

    return diagram
endfunction

