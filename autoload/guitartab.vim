" Vim Guitar Tab
"
" Autoload

let s:chord_regex = '\<[A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?\>'
let s:chord_line_regex = '^\(\s\|\(' . s:chord_regex . '\)\)\+$'

" The handler for Enter/<CR> so we can override the behaviour.
" Checks if there is a chord at cursor and shows it, otherwise
" returns a normal <CR>.
"
" Note: this returns expressions and should therefore be used
" with a <expr> binding
function! guitartab#kbd_enter() abort
    let chord_name = s:extract_chord_at_cursor()
    if chord_name is v:null
        return "\<CR>"
    endif

    " Move up one ('k') and show the chord
    return "\<ESC>k :call guitartab#show_chord('" . chord_name . "')\<CR>"
endfunction


" Like `kbd_enter()` but doesn't return an expression
function! guitartab#hover_chord() abort
    let chord_name = s:extract_chord_at_cursor()
    if chord_name is v:null
        return
    endif
    call guitartab#show_chord(chord_name)
endfunction


" Shows the given chord by name
" TODO: implement it - currently just shows G chord
function! guitartab#show_chord(chord_name) abort
    let diagram = s:chord_diagram(a:chord_name)
    if diagram is v:null
        return
    endif

    let pos = getpos('.')
    let bufnr = bufnr('%')
    let float_win_id = nvim_open_win(bufnr, v:true, {
    \   'relative': 'cursor',
    \   'anchor': 'NW',
    \   'row': 1,
    \   'col': 0,
    \   'width': 25,
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
    set previewwindow

    " Jump back to main window
    wincmd j

    " Close on movement
    augroup plugin-guitartab-close-hover
        let close_cmd = printf('<SID>close_window(%s)', float_win_id)

        execute 'autocmd CursorMoved,CursorMovedI,InsertEnter <buffer> call ' . close_cmd
        " execute 'autocmd BufEnter * call ' . call_on_bufenter
    augroup END
endfunction



"----------------"
" Helper Methods "
"----------------"

" Check if the given text is a guitar chord
function! s:is_guitar_chord(text) abort
    return a:text =~ s:chord_regex
endfunction

" Check if the given line is a guitar chord line which is
" composed of guitar chords, whitespace and nothing else
function! s:is_guitar_chord_line(line) abort
    return a:line =~ s:chord_line_regex
endfunction


" Get the chord at the current cursor position, otherwise `v:null`
function! s:extract_chord_at_cursor() abort
    let line = getline('.')
    let parts = split(line[col('.') - 1:])
    if len(line) == 0 || len(parts) == 0 || !s:is_guitar_chord(parts[0]) || !s:is_guitar_chord_line(line)
        return v:null
    endif
    return parts[0]
endfunction


let s:circled_numbers = ['❶','❷', '❸', '❹']

function! s:chord_diagram(chord_name) abort
    let chord = guitartab#chords#lookup(a:chord_name)
    if chord is v:null
        echoerr "Chord not in database: " . a:chord_name
        return v:null
    endif

    " Find the max and min bounds of the chord diagram
    " so we can show just a subset of the fretboard.
    let min_fret = 30
    let max_fret = 0
    for string in chord
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
    for string in chord
        if guitartab#chords#is_open_or_muted(string)
            continue
        endif

        let string.fret -= fret_position
    endfor

    " Convert our diagram to a textual representation
    let lines = []
    let fret_line = repeat('-', 16)
    let diagram = s:Diagram(chord, max([max_fret - min_fret, 4]))
    let idx = 0
    for row in diagram
        " Map to fancy circled numbers
        let row = map(row, {_, v -> type(v) == v:t_number ? s:circled_numbers[v-1] : v})
        let line = join(row, "  ")

        " Add line of diagram
        " Add fret indicator if not at top of fretboard
        if idx == 1 && fret_position != 0
            let line = line. " " . fret_position . "fr"
            call add(lines, s:pad(line, 4, 0))
        else
            call add(lines, s:pad(line, 4, 3))
        endif
        call add(lines, s:pad(fret_line, 4, 3))

        let idx += 1
    endfor

    " Add the chord label + a new line separator
    let chord_label = a:chord_name . " Chord"
    call insert(lines, "", 0)
    call insert(lines, s:pad(chord_label, 4, 0), 0)

    return lines
endfunction


function! s:close_window(winid) abort
    autocmd! plugin-guitartab-close-hover
    call nvim_win_close(a:winid, v:false)
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

