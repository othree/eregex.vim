
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
    let Fn_filter = get(b:, 'Fn_eregex_incsearch_filter', get(g:, 'Fn_eregex_incsearch_filter', ''))
    if !empty(Fn_filter) && Fn_filter(cmd['pattern'])
        if exists('s:patternSaved')
            let @/ = s:patternSaved
        endif
        if exists('s:stateSaved')
            call winrestview(s:stateSaved)
        endif
        redraw!
        return
    endif
    if get(b:, 'eregex_incsearch_force_case', get(g:, 'eregex_incsearch_force_case', get(g:, 'eregex_force_case', 0)))
                \ && cmd['modifiers'] != 'i'
        let pattern = E2v(cmd['pattern'], 'I')
    else
        let pattern = E2v(cmd['pattern'])
    endif
    let backward = (cmd['delim'] == '?')

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

        try
            silent! let pos = searchpos(pattern, backward ? 'bcnw' : 'cnwz')
        catch
            let pos = [0, 0]
        endtry
        if pos[0] > 0 && pos[1] > 0
            " 'reverse' the cursor by one char so that the next `:M` action
            " would jump to the nearest position
            "
            " won't work if 'backward search with multiline pattern'
            " but that only cause to jump to 'next' match, seems no other side effects
            if backward
                let pos[1] += 1
            else
                if pos[1] > 1
                    let pos[1] -= 1
                endif
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

" input: M/\cabc
" output: {
"   'method' : 'M',
"   'delim' : '/',
"   'modifiers' : 'i', // empty/i/I
"   'pattern' : 'abc',
" }
"
" input: 1,3S/\Cabc/xyz/g
" output: {
"   'method' : 'S',
"   'delim' : '/',
"   'modifiers' : 'I',
"   'pattern' : 'abc',
" }
function! s:cmdParse(cmdline)
    let bslashToken = nr2char(127)
    let slashToken = nr2char(128)
    let questionToken = nr2char(129)
    let cmdline = substitute(a:cmdline, '\\\\', bslashToken, 'g')
    let cmdline = substitute(cmdline, '\\/', slashToken, 'g')
    let cmdline = substitute(cmdline, '\\?', questionToken, 'g')

    let modes = get(b:, 'eregex_incsearch_modes', get(g:, 'eregex_incsearch_modes', 'MSGV'))
    let delims = get(b:, 'eregex_incsearch_delims', get(g:, 'eregex_incsearch_delims',
                \   get(g:, 'eregex_forward_delim', '/') . get(g:, 'eregex_backward_delim', '?')
                \ ))
    " ^[0-9,\.\$% \t]*([MSGV])[ \t]*([\/\?]).*$
    let method = substitute(cmdline, '^[0-9,\.\$% \t]*\([' . modes . ']\)[ \t]*\([' . delims . ']\).*$', '\1', '')
    let delim  = substitute(cmdline, '^[0-9,\.\$% \t]*\([' . modes . ']\)[ \t]*\([' . delims . ']\).*$', '\2', '')
    if len(method) != 1 || len(delim) != 1
        " {
        "   'module_name' : function(cmdline),
        " }
        for Fn in values(get(g:, 'eregex_incsearch_custom_cmdparser', {}))
            let ret = Fn(a:cmdline)
            if !empty(ret)
                return ret
            endif
        endfor
        return {}
    endif

    let pattern = get(split(cmdline, delim), 1, '')

    if match(pattern, '\\c') >= 0
        let modifiers = 'i'
    elseif match(pattern, '\\C') >= 0
        let modifiers = 'I'
    else
        let modifiers = ''
    endif

    let pattern = substitute(pattern, questionToken, '\\?', 'g')
    let pattern = substitute(pattern, slashToken, '\\/', 'g')
    let pattern = substitute(pattern, bslashToken, '\\\\', 'g')
    return {
                \   'method' : method,
                \   'delim' : delim,
                \   'modifiers' : modifiers,
                \   'pattern' : pattern,
                \ }
endfunction

