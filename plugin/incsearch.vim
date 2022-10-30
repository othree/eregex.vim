
if !get(g:, 'eregex_incsearch_enable', 1)
            \ || !exists('##CmdlineChanged')
            \ || !exists('##CmdlineLeave')
            \ || !has('timers')
    finish
endif

augroup eregex_incsearch_augroup
    autocmd!
    autocmd CmdlineChanged * call s:delayUpdate()
    autocmd CmdlineLeave * call s:onLeave()
augroup END

if !has('nvim')
    if get(g:, 'eregex_incsearch_abort_fix', 1)
        function! _eregex_incsearch_abort_cr()
            let g:eregex_incsearch_abort = 0
            return "\<cr>"
        endfunction
        cnoremap <expr> <cr> _eregex_incsearch_abort_cr()
    endif
endif

" it's buggy if update immediately on #CmdlineChanged,
" especially for keymap such as
"     nnoremap xxx :S/<c-r><c-w>
function! s:delayUpdate()
    if get(s:, 'delayUpdateId', -1) == -1
        let s:delayUpdateId = timer_start(10, function('s:delayUpdateAction'))
    endif
endfunction
function! s:delayUpdateCancel()
    if get(s:, 'delayUpdateId', -1) != -1
        call timer_stop(s:delayUpdateId)
        let s:delayUpdateId = -1
    endif
endfunction
function! s:delayUpdateAction(...)
    let s:delayUpdateId = -1
    call s:onUpdate()
endfunction

function! s:onUpdate()
    if getcmdtype() != ':'
                \ || !get(b:, 'eregex_incsearch', get(g:, 'eregex_incsearch', &incsearch))
        return
    endif
    let cmd = s:cmdParse(getcmdline())
    if empty(cmd)
        return
    endif
    let pattern = E2v(cmd['pattern'])

    if !exists('s:hlsearchSaved')
        let s:hlsearchSaved = &hlsearch
    endif
    if !exists('s:patternSaved')
        let s:patternSaved = @/
        if !has('nvim')
            let g:eregex_incsearch_abort = 1
        endif
    endif
    if !exists('s:stateSaved')
        let s:stateSaved = winsaveview()
    endif

    set nohlsearch

    if !empty(pattern)
        let @/ = pattern

        let pos = searchpos(pattern, 'cnw')
        if pos[0] > 0 && pos[1] > 0
            if pos[1] > 1
                let pos[1] -= 1
            endif
            let curpos = getpos('.')
            let curpos[1] = pos[0]
            let curpos[2] = pos[1]
            call setpos('.', curpos)
        else
            call winrestview(s:stateSaved)
        endif
    else
        call winrestview(s:stateSaved)
    endif

    if s:hlsearchSaved && !empty(pattern)
        set hlsearch
    else
        set nohlsearch
    endif
    redraw
endfunction

function! s:onLeave()
    call s:delayUpdateCancel()

    if exists('s:hlsearchSaved')
        let hlsearchSaved = s:hlsearchSaved
        unlet s:hlsearchSaved
    endif
    if exists('s:patternSaved')
        let patternSaved = s:patternSaved
        unlet s:patternSaved
    endif
    if exists('s:stateSaved')
        let stateSaved = s:stateSaved
        unlet s:stateSaved
    endif

    if exists('hlsearchSaved')
        if hlsearchSaved
            set hlsearch
        else
            set nohlsearch
        endif
    endif

    if has('nvim')
        let abort = get(v:event, 'abort', 0)
    else
        let abort = get(g:, 'eregex_incsearch_abort', 0)
    endif
    if !abort
        return
    endif

    if exists('patternSaved')
        let @/ = patternSaved
    endif
    if exists('stateSaved')
        call winrestview(stateSaved)
    endif

    redraw!
endfunction

" input: M/abc
" output: {
"   'method' : 'M'
"   'pattern' : 'abc'
" }
"
" input: 1,3S/abc/xyz/g
" output: {
"   'method' : 'S',
"   'pattern' : 'abc',
" }
function! s:cmdParse(cmdline)
    let token = nr2char(127)
    let items = split(substitute(a:cmdline, '\\/', token, 'g'), '/', 1)
    if len(items) < 2
        return {}
    endif
    let modes = get(b:, 'eregex_incsearch_modes', get(g:, 'eregex_incsearch_modes', 'MSGV'))
    " ^[0-9,\.\$%]*([MSGV])\/.*$
    let method = substitute(items[0], '^[0-9,\.\$%]*\([' . modes . ']\)\/.*$', '\1', '')
    if empty(method)
        return {}
    endif
    return {
                \   'method' : method,
                \   'pattern' : substitute(get(items, 1, ''), token, '\\/', 'g'),
                \ }
endfunction

