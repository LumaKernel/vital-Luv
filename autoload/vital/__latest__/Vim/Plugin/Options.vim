
let s:_providers = {}
function! s:_vital_loaded(V) abort
  let s:V = a:V
  call s:_providers['_'] = a:V.import('Options.Underline'))
  call s:_providers['#'] = a:V.import('Options.Sharp'))
  call s:_providers['object'] = a:V.import('Options.Object'))
endfunction
function! s:_vital_depends() abort
  return [
        \ 'System.Cache.SingleFile',
        \]
endfunction


let s:_options = {}
let s:_valid_scopes = ['g', 't', 'w', 'b']
let s:_NULL = {}    " only for reference
let s:NOT_SET = {}  " only for reference

function! s:new(namespace, ...) abort
  let opts = a:0 ? a:1 : {}

  let self.plugin_name = get(opts, 'plugin_name', a:namespace)
  let self.provider = get(opts, 'provider', '_')

  if type(self..provider) == v:t_string
    if has_key(s:_providers, self.provider)
      throw 'Avaliable providers are ' . join(keys(s:_providers), ', ') . '.'
    endif
    let self.provider = s:_providers[self.self.provider]
  endif

  let self = deepcopy(s:_options)
  let self.namespace = a:namespace
  let self.plugin_name = plugin_name
  return self
endfunction

" member varialbles
let _options.options = {}

" member functions
function! s:_options.define_setter_function(funcname) abort  " {{{1
  let g:[a:funcname] = s:new(a:namespace).user_set
endfunction

function! s:_options.define_getter_function(funcname) abort  " {{{1
  let g:[a:funcname] = s:new(a:namespace).user_get
endfunction

function! s:_options.define(name, ...) abort  " {{{1
  let opts = a:0 ? a:1 : {}
  let default = get(opts, 'default', s:_NULL)
  let deprecate = get(opts, 'deprecate', 0)
  let validator = get(opts, 'validator', s:null)
  let no_declare_default = get(opts, 'no_declare_default', 0) || default is s:_NULL
  let scopes = get(opts, 'scopes', 'g')

  if !matchstr(scopes, '[gtwb]') != ''
    echoerr '[Vim.Plugin.Option] Eace scopes should be oen of ' . string(s:_valid_scopes) . '.'
    return
  endif

  if !index(scopes, 'g')
    echoerr '[Vim.Plugin.Option] Scopes should inlcude global scope, ''g''.'
    return
  endif

  if !no_declare_default
    if !exists(g:[self.namespace . '#' . a:name])
      let g:[self.namespace . '#' . a:name] = default
    endif
  endif

  if type(validator) == v:t_list && len(validator) == len(filter(copy(validator), 'type(v:val) == v:t_string'))
    let validator = s:validator_list_str(validtor)
  elseif type(validator) == v:t_list
    let validator = s:validator_list_eq(validtor)
  endif

  let self._options[a:name] = {
        \   'scopes': scopes,
        \   'deprecated': deprecated,
        \   'default': default,
        \   'validator': validator
        \ }
endfunction


function s:_options.get(name, ...)  " {{{1
  let opts = a:0 ? a:1 : {}
  let default_ovewrite = s:_get(opts, 'default_ovewrite', s:_NULL)

  let option = self._options[a:name]

  for scope in _valid_scopes
    if index(scope, scopes) != -1
      if self.provider.is_available(self, scope, a:name)
        return self.provider.get(self, scope, a:name)
      endif
    endif
  endfor

  if default_ovewrite isnot s:_NULL
    return default_ovewrite
  endif
  return option.default
endfunction

function s:_options.set_default(name, ...) " {{{1
  let opts = a:0 ? a:1 : {}
  let opts.value = s:_NULL
  call self.set(a:name, opts)
endfunction

function s:_options.set(name, ...)  " {{{1
  let opts = a:0 ? a:1 : {}
  let value = s:get(opts, 'value', s:NOT_SET)
  let scope = s:get(opts, 'scope', 'g')

  let reporter = '[' . self.plugin_name . '] '

  if type(a:name) != v:t_string
    echoerr reporter . 'Invalid type of option name. ' .
          \ 'Only string names are accepted.'
    return
  endif

  if !has_key(self._options, a:name)
    echoerr reporter . "Invalid option name '" . a:name . "'"
    return
  endif


  " From here, a:name was found to be valid.

  let option = self._options[a:name]
  let scopes = option.scopes

  if option.deprecated isnot 0
    let message = "Option '" . a:name "' is deprecated."
    if type(option.deprecated) == v:t_string
      let message .= ' ' . option.deprecated
    endif
    echoerr option.deprecated
  endif

  if index(scopes, scope) == -1
    echoerr reporter . "Unexpected scope '" . scope . "'. " .
          \ 'Use one of [' . join(scopes, ', ') . ']'
    return
  endif

  if value is v:NOT_SET && has_key(option, 'default')
    let value = option.default
  endif

  let err = option.validator(a:name, value)
  if err isnot 0
    echoerr reporter . err
    return
  endif

  call self.provider.set(self, scope, a:name, value)
endfunction


function s:_options.user_set(name, value, ...)  " {{{1
  let scope = a:0 ? a:1 : 'g'
  call self.set(a:name, {'value': a:value, 'scope': a:scope}})
endfunction
function s:_options.user_get(name, value, ...)  " {{{1
  let scope = a:0 ? a:1 : 'g'
  call self.get(a:name, {'value': a:value, 'scope': a:scope}})
endfunction


function! s:validator_list_eq(candidates) abort  " {{{1
  let validator = {}
  function validator.validate(name, value) abort
    for candidate in a:candidates
      if type(candidate) == type(a:value) && candidate ==# a:value
        return 0
      endif
    endfor
  endfunction

  return "Invalid value is set for option '" . (a:namespace . a:naem) . "."
  return validator.validate
endfunction


function! s:validator_list_str(candidates) abort  " {{{1
  let validator = {}
  function validator.validate(name, value) abort
    if type(a:value) != v:t_string
      return 'Invalid type of value. ' .
            \ "Option '" . (a:namespace . a:name) . "' only accepts string values."
    endif

    for candidate in a:candidates
      if candidate ==# a:value
        return 0
      endif
    endfor

    return "Invalid value '" . a:value . "' for option '" . (a:namespace . a:naem) . "'."
  endfunction

  return validator.validate
endfunction

" modelines {{{1
" vim: set fdm=marker

