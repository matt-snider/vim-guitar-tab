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
function! guitartab#show_chord(chord_name) abort
    let diagram = s:chord_diagram(a:chord_name)
    if diagram is v:null
        return
    endif

    let max_width = max(map(deepcopy(diagram), {_, x -> strchars(x)}))
    let pos = getpos('.')
    let bufnr = bufnr('%')
    let float_win_id = nvim_open_win(bufnr, v:true, {
    \   'relative': 'cursor',
    \   'anchor': 'NW',
    \   'row': 1,
    \   'col': 0,
    \   'width': max_width,
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

    " Calculate the fret position of the diagram
    " Note: for bar chords, move up to <first finger pos - 1>
    let fret_position = max([0, max_fret - 4])
    if guitartab#chords#is_bar_chord(chord)
        let fret_position = max([fret_position, min_fret - 1])
    endif

    " Find any barred sections for this chord and decide whether to show
    " the fret position indicator at the nut. We don't need it if there is
    " a bar chord at the first shown fret, which indicates it more clearly.
    let barred_sections = guitartab#chords#get_barred_sections(chord)
    let show_fret_at_nut = fret_position > 0 && len(filter(barred_sections, {_, v -> v.end == 5 && v.fret == fret_position + 1})) == 0

    " Convert our diagram to a textual representation
    let lines = []
    let fret_line = repeat('-', 16)
    let diagram = s:Diagram(chord, max([max_fret - min_fret, 4]), fret_position)
    let row_idx = 0
    for row in diagram
        let line = ""
        let col_idx = 0

        while col_idx < 6
            let symbol = row[col_idx]

            " Only pad left if after the first string
            let padl = col_idx > 0 ? 1 : 0
            let padr = 1

            " Check if this is a fretted string or not
            " Handle bar chord and single fretted string differently
            if type(symbol) == v:t_number
                let row_barred_sections = filter(barred_sections,
                        \ {_, v -> v.fret == (fret_position + row_idx) && v.start == col_idx})

                if len(row_barred_sections) > 0
                    let barred = row_barred_sections[0]
                    let barred_len = 1 + barred.end - barred.start

                    " Add bar chord line and add fret indicator if needed
                    " NOTE: no padding for bar chord
                    let line .= s:make_bar(barred_len, s:circled_numbers[barred.finger - 1])
                    if barred.end == 5 && !show_fret_at_nut
                        let line .= " " . barred.fret . "fr"
                    endif

                    let col_idx += barred_len
                else
                    let line .= s:pad(s:circled_numbers[symbol-1], padl, padr)
                    let col_idx += 1
                endif
            else
                let line .= s:pad(symbol, padl, padr)
                let col_idx += 1
            endif
        endwhile

        " Add the line. Reduce left pad if we have a full bar chord on the first fret.
        let l_padl = 4
        let l_padr = 3
        let is_full_bar = len(barred_sections)
            \ && barred_sections[0].fret == (fret_position + 1)
            \ && barred_sections[0].start == 0
            \ && barred_sections[0].end == 5
        if is_full_bar
            let l_padl = 3
        endif
        call add(lines, s:pad(line, l_padl, l_padr))

        " Show fret position at nut if needed
        " Adjust padding as needed
        let fret_line_copy = deepcopy(fret_line)
        let fl_padl = 4
        let fl_padr = 3
        if row_idx == 0 && show_fret_at_nut
            let fret_line_copy = fret_position . "fr " . fret_line
            let fl_padl = 0
        endif
        call add(lines, s:pad(fret_line_copy, fl_padl, fl_padr))

        let row_idx += 1
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
function! s:Diagram(chord_data, num_frets, fret_position)
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

            " Relativize the chord to the fret_position
            let fret = string.fret - a:fret_position
            let diagram[fret][string_idx] = string.finger
        endif
        let string_idx += 1
    endfor

    return diagram
endfunction

" This method uses unicode characters to make
" a indicator for barred strings.
" It will be done across `num_strings` with `spaces`
" between each string
"
" e.g. ━┿━━┿━━❶━━┿━━┿━
function! s:make_bar(num_strings, finger_symbol)
    let sep = repeat(['━'], 2)
    let result = []
    for _ in range(a:num_strings)
        call extend(result, ['┿'] + sep)
    endfor

    " We add a bar to the beginning, but the end already has
    " 2 of them so we remove one
    let result = ['━'] + result[:-2]

    " Create the resulting string and then find the
    " midpoint to add the finger indicator. We don't
    " want to put it over a string though
    let mid = float2nr(round(len(result) / 2))
    if result[mid] != '┿'
        let result[mid] = a:finger_symbol
    else
        let result[mid-1] = a:finger_symbol
    endif
    return join(result, '')
endfunction

