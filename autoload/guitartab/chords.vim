" Vim Guitar Tab
"
" Chord Database
"
" Note: chords are represented as a list of objects where each element
" represent a string. A property for the fret and finger is used to
" identify how the string should be pressed. An unfretted, or open string,
" is represented by "s:F(0, 0)". A muted string is represented by "v:null".
"
" Every chord can have multiple versions.

let s:chords = {}

function! guitartab#chords#lookup(chord_name)
    if !has_key(s:chords, a:chord_name)
        return v:null
    endif

    return s:chords[a:chord_name][0]
endfunction


function! guitartab#chords#is_muted(string)
    return a:string is v:null
endfunction


function! guitartab#chords#is_open(string)
    return !guitartab#chords#is_muted(a:string) && a:string.fret == 0 && a:string.finger == 0
endfunction


function! guitartab#chords#is_open_or_muted(string)
    return a:string is v:null || guitartab#chords#is_open(a:string)
endfunction


" Gets the sections of a guitar chord that are barred with a single
" finger (usually finger 1).
"
" This returns a list of Dicts in the following format:
"
" { "finger": <int representing which finger is used (1 based),
"   "fret"  : <int representing which fret is used (0 based),
"   "start" : <int representing starting string (0 based)>,
"   "end"   : <int representing ending string (0 based)> }
"
" Barred sections occur when either:
"
" (1) the strings are trivially barred - that is consective strings
" have the same finger and fret (e.g. x02220)
" (2) one or more strings are surrounded on both (left & right) sides
" with a string that have the same (e.g. x13321)
function! guitartab#chords#get_barred_sections(chord)
    " Maps from finger to min/max string values
    let idx = 0
    let finger_ranges = {}

    " Loop through and find barred ranges
    for string in a:chord
        if !guitartab#chords#is_open_or_muted(string)
            " Initialize the range if it doesn't exist and update it
            if !has_key(finger_ranges, string.finger)
                let finger_ranges[string.finger] = {
                    \ "finger": string.finger,
                    \ "fret": string.fret,
                    \ "start": idx,
                    \ "end": idx,
                    \ }
            endif

            let curr_range = finger_ranges[string.finger]
            let curr_range.end = idx
        endif

        let idx += 1
    endfor

    " Convert it to a list, removing any where the start and end are the same
    return filter(values(finger_ranges), {_, fr -> fr.start != fr.end})
endfunction


function! guitartab#chords#is_bar_chord(chord)
    let barred_sections = guitartab#chords#get_barred_sections(a:chord)
    return len(barred_sections) > 0
endfunction


" Chord helper - 'F' for finger placed at position/fret x
function! s:F(finger, fret)
    return {"fret": a:fret, "finger": a:finger}
endfunction

let s:open = s:F(0, 0)


" A chord
let s:chords["A"] = [
    \ [v:null, s:open, s:F(1, 2), s:F(2, 2), s:F(3, 2), s:open],
    \ ]

let s:chords["Am"] = [
    \ [v:null, s:open, s:F(2, 2), s:F(3, 2), s:F(1, 1), s:open],
    \ ]


" B chords
let s:chords["B"] = [
    \ [v:null, s:F(1, 2), s:F(2, 4), s:F(3, 4), s:F(4, 4), s:F(1, 2)],
    \ ]

let s:chords["Bm"] = [
    \ [v:null, s:F(1, 2), s:F(3, 4), s:F(4, 4), s:F(2, 3), s:F(1, 2)],
    \ ]


" C chords
let s:chords["C"] = [
    \ [v:null, s:F(3, 3), s:F(2, 2), s:open, s:F(1, 1), s:open],
    \ ]

let s:chords["Cm"] = [
    \ [v:null, s:F(1, 3), s:F(3, 5), s:F(4, 5), s:F(2, 4), s:F(1, 3)],
    \ ]


" D chords
let s:chords["D"] = [
    \ [v:null, v:null, s:open, s:F(1, 2), s:F(3, 3), s:F(2, 2)],
    \ ]

let s:chords["Dm"] = [
    \ [v:null, v:null, s:open, s:F(2, 2), s:F(3, 3), s:F(1, 1)],
    \ ]


" E chords
let s:chords["E"] = [
    \ [s:open, s:F(2, 2), s:F(3, 2), s:F(1, 1), s:open, s:open],
    \ ]

let s:chords["Em"] = [
    \ [s:open, s:F(2, 2), s:F(3, 2), s:open, s:open, s:open],
    \ ]


" F chords
let s:chords["F"] = [
    \ [s:F(1, 1), s:F(3, 3), s:F(4, 3), s:F(2, 2), s:F(1, 1), s:F(1, 1)],
    \ ]

let s:chords["Fm"] = [
    \ [s:F(1, 1), s:F(3, 3), s:F(4, 3), s:F(1, 1), s:F(1, 1), s:F(1, 1)],
    \ ]


" G chords
let s:chords["G"] = [
    \ [s:F(2, 3), s:F(1, 2), s:open, s:open, s:F(3, 3), s:F(4, 3)],
    \ ]

let s:chords["Gm"] = [
    \ [s:F(2, 3), s:F(1, 1), s:open, s:open, s:F(3, 3), s:F(4, 3)],
    \ ]

