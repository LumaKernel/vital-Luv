
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')

  " Just xtend Async.Promise
  for key in keys(s:Promise)
    if !has_key(s:, key)
      let s:[key] = s:Promise[key]
    endif
  endfor
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Async.Promise',
        \]
endfunction

function! s:new(resolver, ...)
  let timeout = a:0 ? a:1 : 5000
  let promise = s:Promise.new(resolver)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
endfunction

function! s:set_debug(debug)
  let s:debug = a:debug
endfunction
let s:debug = 0

function! s:set_error_handler(err_handler)
  if err_handler is v:t_func
    let s:err_handler = a:err_handler
  else
    let s:err_handler = function('s:_default_err_handler')
  endif
endfunction

function! s:_default_err_handler(ex) abort
  if type(a:ex) == v:t_dict && has_key(a:ex, 'throwpoint')
    let pat = '\C^\(.*\), line \(\d\+\)$'
    let throwpoint = a:ex.throwpoint
    let line = v:null
    if throwpoint =~# pat
      let groups = matchlist(a:ex.throwpoint, pat)
      let throwpoint = groups[1] . ':'
      let line = 'line ' . groups[2] . ':'
    endif
    echohl ErrorMsg
    echom 'Error detected while processing ' . throwpoint
    echohl None
    if line isnot v:null
      echom line
    endif
    if has_key(a:ex, 'exception')
      echohl ErrorMsg
      echom "<Promise Uncaught Exception> " . a:ex.exception
      if len(keys(a:ex)) > 2
        echom "<Promise Uncaught> " . string(a:ex)
      endif
      echohl None
    else
      echom "<Promise Uncaught> " . string(a:ex)
    endif
  else
    echohl ErrorMsg
    echom '<Promise Uncaught>' . string(a:ex)
    echohl None
  endif
endfunction

let s:err_handler = function('s:_default_err_handler')

