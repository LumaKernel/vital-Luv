
function! s:_vital_depends() abort
  return [
        \   'Async.Promise',
        \ ]
endfunction
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:new(resolver, ...)
  let timeout = a:0 ? a:1 : s:timeout
  let promise = s:Promise.new(a:resolver)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return s:_hack_then(promise)
endfunction

function! s:resolve(...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : s:timeout
  let promise = s:Promise.resolve(value)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return s:_hack_then(promise)
endfunction

function! s:reject(...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : s:timeout
  let promise = s:Promise.reject(value)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return s:_hack_then(promise)
endfunction

function! s:all(promises, ...)
  let timeout = a:0 ? a:1 : s:timeout
  let promise = s:Promise.all(a:promises)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return s:_hack_then(promise)
endfunction


" XXX : If vital supports `extend` feature,
"       below must be replaced to that.
function! s:race(promises, ...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : s:timeout
  let promise = s:Promise.race(a:promises)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return s:_hack_then(promise)
endfunction

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

let s:timeout = 5000
function! s:set_timeout(timeout)
  let s:timeout = a:timeout
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
      echomsg "<Promise Uncaught Exception> " . a:ex.exception
      echohl None
      if len(keys(a:ex)) > 2
        echohl ErrorMsg
        echomsg "<Promise Uncaught> " . string(a:ex)
        echohl None
      endif
    else
      echohl ErrorMsg
      echomsg "<Promise Uncaught> " . string(a:ex)
      echohl None
    endif
  else
    echohl ErrorMsg
    echomsg '<Promise Uncaught>' . string(a:ex)
    echohl None
  endif
endfunction

let s:err_handler = function('s:_default_err_handler')

function! s:_hack_then(promise) abort
  " let orig = a:promise.then
  " function! a:promise.then(...) abort closure
  "   if s:debug
  "     call timer_start(s:timeout, {-> a:promise.catch(s:err_handler)})
  "   endif
  "   return s:_hack_then(call(orig, a:000))
  " endfunction
  return promise
endfunction

