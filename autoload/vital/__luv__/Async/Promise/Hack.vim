
function! s:_vital_depends() abort
  return [
        \   'Async.Promise',
        \ ]
endfunction
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

let to_hack = ['new', 'resolve', 'reject', 'all', 'race']
for funcname in to_hack
  exe printf(join([
        \   'function! s:%s(...) abort',
        \   '  return s:_hack_promise(call(s:Promise.%s, a:000))',
        \   'endfunction',
        \ ], "\n"), funcname, funcname)
endfor


" XXX : If vital supports `extend` feature,
"       below must be replaced to that.
let to_extend = ['is_available', 'is_promise', 'wait', 'noop']
for funcname in to_extend
  exe printf(join([
        \   'function! s:%s(...) abort',
        \   '  return call(Promise.%s, a:000)',
        \   'endfunction',
        \ ], "\n"), funcname, funcname)
endfor


let s:debug = 0
function! s:set_debug(debug)
  let s:debug = a:debug
endfunction

let s:timeout = 5000
function! s:set_timeout(timeout)
  let s:timeout = a:timeout
endfunction

function! s:set_error_handler(err_handler)
  if type(a:err_handler) == v:t_func
    let s:err_handler = a:err_handler
  else
    let s:err_handler = function('s:_default_err_handler')
  endif
endfunction

function! s:get_default_error_handler()
  return function('s:_default_err_handler')
endfunction

function! s:_default_err_handler(ex) abort
  if type(a:ex) == v:t_dict
        \ && has_key(a:ex, 'throwpoint')
        \ && type(a:ex.throwpoint) == v:t_string
    let pat = '\C^\(.*\), line \(\d\+\)$'
    let throwpoint = a:ex.throwpoint
    let line = v:null
    if throwpoint =~# pat
      let groups = matchlist(a:ex.throwpoint, pat)
      let throwpoint = groups[1] . ':'
      let line = 'line ' . groups[2] . ':'
    else
      let throwpoint .=  ':'
    endif
    echohl ErrorMsg
    echomsg 'Error detected while processing ' . throwpoint
    echohl None
    if line isnot v:null
      echomsg line
    endif
    if has_key(a:ex, 'exception') && type(a:ex.exception) == v:t_string
      echohl ErrorMsg
      echomsg '<Promise Uncaught Exception> ' . a:ex.exception
      echohl None
      if len(keys(a:ex)) > 2
        echohl ErrorMsg
        echomsg '<Promise Uncaught> ' . string(a:ex)
        echohl None
      endif
    else
      echohl ErrorMsg
      echomsg '<Promise Uncaught> ' . string(a:ex)
      echohl None
    endif
  else
    echohl ErrorMsg
    echomsg '<Promise Uncaught> ' . string(a:ex)
    echohl None
  endif
endfunction
let s:err_handler = function('s:_default_err_handler')

function! s:_hack_promise(promise) abort
  let Orig_then = a:promise.then

  if s:debug
    let timer_id = timer_start(s:timeout, {-> Orig_then(v:null, s:err_handler)})
  endif
  
  function! a:promise.then(...) abort closure
    let promise = call(Orig_then, a:000)
    if s:debug
      let promise = s:_hack_promise(promise)
    endif
    if exists('timer_id') && get(a:000, 1, v:null) isnot v:null
      call timer_stop(timer_id)
    endif
    return promise
  endfunction
  
  return a:promise
endfunction

