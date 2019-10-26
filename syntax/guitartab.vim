" Vim Guitar Tab
"
" Syntax file

if exists("b:current_syntax")
  finish
endif
let b:current_syntax = "guitartab"

syntax keyword GuitarTabSection
    \ Intro Verse Chorus Riff

syn keyword GuitarTabMetadata
    \ Artist Band Title Tuning

syntax match GuitarChord
    \ contained
    \ "\<[A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?\>"

" The chord line is a line of either guitar chords or whitespace (nothing else!)
" This prevents GuitarChord being highlighted in other places, like the lyrics
" e.g. "A B C easy as 1 2 3" would normally cause 'A' 'B' and 'C' to be highlighted
syntax match GuitarChordLine
    \ "^\(\([A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?\)\|\s\)\+$"
    \ contains=GuitarChord


hi def link GuitarTabMetadata Comment
hi def link GuitarTabSection Comment
hi def link GuitarChord Statement

