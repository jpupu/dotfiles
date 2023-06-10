if exists("b:current_syntax") && b:current_syntax == "aika"
    finish
endif


syn match aikaDate '^=\d\{4}-\d\{2}-\d\{2}'
syn match aikaComment '^#.*$'

syn match aikaEntry '^+\?\d\{4}.*$' contains=aikaTime,aikaProject
syn match aikaTime '+\?\d\{4}' nextgroup=aikaProject skipwhite contained display
syn match aikaProject '[a-z][a-z]*\d\d*\|loma' nextgroup=aikaDesc display contained display
syn match aikaDesc '\w*$'

syn keyword aikaLoma loma

let b:current_syntax = "aika"

hi def link aikaDate Function
hi def link aikaComment Comment

hi def link aikaKeywords Statement
hi def link aikaTime Constant
hi def link aikaProject String

hi def link aikaLoma Function
