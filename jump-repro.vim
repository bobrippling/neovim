" setup
lua require'vim._core.ui2'.enable{}
set cmdheight=0
set splitbelow
help state()

" repro
call feedkeys(":\<Esc>", 'x')
if getline('.') !~# '^state'
	" cursor is now not on the *state()* help line
	echoerr 'fail'
endif
