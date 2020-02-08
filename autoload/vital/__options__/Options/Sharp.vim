
function! s:unset(options, scope, name) abort
  let scope_dicts = {'g': g:, 't': t:, 'w': w:, 'b': b:}
  silent! unlet scope_dicts[a:scope][a:options.namespace . '#' . a:name]
endfunction

function! s:set(options, scope, name, value) abort
  let scope_dicts = {'g': g:, 't': t:, 'w': w:, 'b': b:}
  let scope_dicts[a:scope][a:options.namespace . '#' . a:name] = a:value
endfunction

function! s:get(options, scope, name) abort
  let scope_dicts = {'g': g:, 't': t:, 'w': w:, 'b': b:}
  return scope_dicts[a:scope][a:options.namespace . '#' . a:name]
endfunction

function! s:is_available(options, scope, name) abort
  let scope_dicts = {'g': g:, 't': t:, 'w': w:, 'b': b:}
  return has_key(scope_dicts[a:scope], a:options.namespace . '#' . a:name)
endfunction

