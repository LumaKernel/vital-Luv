
function! s:_vital_depends() abort
  return [
        \   'Async.Promise',
        \ ]
endfunction
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:new(...)
  return s:_hack_promise(call(s:Promise.new, a:000))
endfunction

function! s:resolve(...)
  return s:_hack_promise(call(s:Promise.resolve, a:000))
endfunction

function! s:reject(...)
  return s:_hack_promise(call(s:Promise.reject, a:000))
endfunction

function! s:all(...)
  return s:_hack_promise(call(s:Promise.all, a:000))
endfunction

function! s:race(...)
  return s:_hack_promise(call(s:Promise.race, a:000))
endfunction


" XXX : If vital supports `extend` feature,
"       below must be replaced to that.
function! s:is_available(...) abort
  return call(Promise.is_available, a:000)
endfunction

function! s:is_promise(...) abort
  return call(Promise.is_promise, a:000)
endfunction

function! s:wait(...) abort
  return call(Promise.wait, a:000)
endfunction

function! s:noop(...) abort
  return call(Promise.wait, a:000)
endfunction


let s:debug = 0
function! s:set_debug(debug)
  let s:debug = a:debug
endfunction

let s:timeout = 5000
function! s:set_timeout(timeout)
  let s:timeout = a:timeout
endfunction

function! s:set_error_handler(err_handler)
  if err_handler is v:t_func
    let s:err_handler = a:err_handler
  else
    let s:err_handler = function('s:_default_err_handler')
  endif
endfunction

function! s:get_default_error_handler()
  return function('s:_default_err_handler')
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
    else
      let throwpoint .=  ':'
    endif
    echohl ErrorMsg
    echomsg 'Error detected while processing ' . throwpoint
    echohl None
    if line isnot v:null
      echomsg line
    endif
    if has_key(a:ex, 'exception')
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
  if s:debug
    let timer_id = timer_start(s:timeout, {-> a:promise.catch(s:err_handler)})
  endif
  
  let Orig_then = a:promise.then
  function! a:promise.then(...) abort closure
    let promise = call(Orig_then, a:000)
    if s:debug && get(a:000, 0, v:null) isnot v:null
      let promise = s:_hack_promise(promise)
    endif
    if exists('timer_id') && get(a:000, 1, v:null) isnot v:null
      call timer_stop(timer_id)
    endif
    return promise
  endfunction
  
  return a:promise
endfunction

