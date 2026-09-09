lua require'vim._core.ui2'.enable{}
set cmdheight=0
set splitbelow
help state()
call feedkeys(":\<Esc>", 'x')

" cursor is now not on the *state()* help line
if getline('.') !~# '^state'
	echoerr 'fail'
endif
