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
    return s:chords[a:chord_name][0]
endfunction


function! guitartab#chords#is_open(string)
    return a:string isnot v:null && a:string.fret == 0 && a:string.finger == 0
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


" B chord
let s:chords["B"] = [
    \ [v:null, s:F(1, 2), s:F(3, 4), s:F(3, 4), s:F(3, 4), s:F(1, 2)],
    \ ]


" C chord
let s:chords["C"] = [
    \ [v:null, s:F(3, 3), s:F(2, 2), s:open, s:F(1, 1), s:open],
    \ ]


" D chord
let s:chords["D"] = [
    \ [v:null, v:null, s:open, s:F(2, 2), s:F(3, 3), s:F(1, 2)],
    \ ]


" E chord
let s:chords["E"] = [
    \ [s:open, s:F(2, 2), s:F(3, 2), s:F(1, 1), s:open, s:open],
    \ ]


" F chord
let s:chords["F"] = [
    \ [s:F(1, 1), s:F(3, 3), s:F(2, 3), s:F(2, 2), s:F(1, 1), s:F(1, 1)],
    \ ]


" G chord
let s:chords["G"] = [
    \ [s:F(2, 3), s:F(1, 2), s:open, s:open, s:F(3, 3), s:F(4, 3)],
    \ ]

