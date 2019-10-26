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

