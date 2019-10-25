" Vim Guitar Tab
"
" Syntax file

if exists("b:current_syntax")
  finish
endif
let b:current_syntax = "guitartab"

syn keyword guitarTabSection Intro Verse Chorus Riff
syn keyword guitarTabMetadata Artist Band Title Tuning
syntax match guitarChord "\<[A-G][b#]\?\(\(sus\|maj\|min\|aug\|dim\|m\)\d\?\)\?\(/[A-G][b#]\?\)\?\>"


hi def link guitarTabMetadata Comment
hi def link guitarTabSection Comment
hi def link guitarChord Statement

