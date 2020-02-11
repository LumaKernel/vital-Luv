
function! s:_vital_depends() abort
  return [
        \   'Async.Promise',
        \ ]
endfunction
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:new(resolver, ...)
  let timeout = a:0 ? a:1 : 5000
  let promise = s:Promise.new(a:resolver)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
endfunction

function! s:resolve(...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : 5000
  let promise = s:Promise.resolve(value)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
endfunction

function! s:reject(...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : 5000
  let promise = s:Promise.reject(value)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
endfunction

function! s:all(promises, ...)
  let timeout = a:0 ? a:1 : 5000
  let promise = s:Promise.all(a:promises)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
endfunction


" XXX : If vital supports `extend` feature,
"       below must be replaced to that.
function! s:race(promises, ...)
  let value = a:0 ? a:1 : v:null
  let timeout = a:0 > 1 ? a:2 : 5000
  let promise = s:Promise.race(a:promises)
  if s:debug
    call timer_start(timeout, {-> promise.catch(s:err_handler)})
  endif
  return promise
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
