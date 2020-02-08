
let s:_providers = {}
function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:_providers['_'] = a:V.import('Options.Underline')
  let s:_providers['#'] = a:V.import('Options.Sharp')
  let s:_providers['object'] = a:V.import('Options.Object')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Options.Underline',
        \ 'Options.Sharp',
        \ 'Options.Object',
        \]
endfunction


let s:_options = {}
let s:_valid_scopes = ['g', 't', 'w', 'b']
let s:_NULL = {}  " only for reference
let s:_UNSET = {} " only for reference

let s:_typenames = ['number', 'string', 'func', 'list', 'dict', 'float', 'bool', 'none', 'job', 'channel', 'blob']
let s:_num2type = {}
for s:_name in s:_typenames
  if exists('v:t_' . s:_name)
    let s:_num2type[v:['t_' . s:_name]] = s:_name
  endif
endfor


function! s:new(namespace, ...) abort
  let opts = a:0 ? a:1 : {}

  let self = deepcopy(s:_options)
  let self.plugin_name = get(opts, 'plugin_name', a:namespace)
  let self.provider = get(opts, 'provider', '_')

  if type(self.provider) == v:t_string
    if !has_key(s:_providers, self.provider)
      throw '[Options] Avaliable providers are ' . join(map(keys(s:_providers), {_, val-> "'" . val . "'"}), ', ') . '.'
    endif
    let self.provider = s:_providers[self.provider]
  endif

  let self.namespace = a:namespace
  return self
endfunction

" member varialbles
let s:_options.options = {}

" member functions
function! s:_options.define_user_setter(funcname) abort  " {{{1
  let funcname = a:funcname =~# '^g:' ? matchlist(a:funcname, '^g:\(.*\)')[1] : a:funcname
  let g:[funcname] = self.user_set
endfunction

function! s:_options.define_user_getter(funcname) abort  " {{{1
  let funcname = a:funcname =~# '^g:' ? matchlist(a:funcname, '^g:\(.*\)')[1] : a:funcname
  let g:[funcname] = self.user_get
endfunction

function! s:_options.define(name, ...) abort  " {{{1
  let opts = a:0 ? a:1 : {}
  let Default = get(opts, 'default', s:_NULL)
  let deprecated = get(opts, 'deprecated', 0)
  let Validator = get(opts, 'validator', v:null)
  let no_declare_default = get(opts, 'no_declare_default', 0) || Default is s:_NULL
  let scopes = split(get(opts, 'scopes', 'g'), '\zs')

  if matchstr(join(scopes, ''), '[^gtwb]') !=# ''
    echoerr "[Options] Each scopes should be oen of '" . string(s:_valid_scopes) . "'."
    return
  endif

  if index(scopes, 'g') == -1
    echoerr "[Options] Scopes should inlcude global scope, 'g'."
    return
  endif

  let scopes = s:_normalize_scopes(scopes)

  if !no_declare_default
    call self.provider.set(self, 'g', a:name, Default)
  endif

  if type(Validator) == v:t_list && len(Validator) == len(filter(copy(Validator), 'type(v:val) == v:t_string'))
    let Validator = s:validator_list_str(Validator)
  elseif type(Validator) == v:t_list
    let Validator = s:validator_list_eq(Validator)
  endif

  let self.options[a:name] = {
        \   'scopes': scopes,
        \   'deprecated': deprecated,
        \   'default': Default,
        \   'validator': Validator
        \ }
endfunction


function s:_options.is_set(name)  " {{{1
  return self.get(a:name) isnot v:_NULL
endfunction

function s:_options.get(name, ...)  " {{{1
  let opts = a:0 ? a:1 : {}
  let default_ovewrite = get(opts, 'default_ovewrite', s:_NULL)

  let option = self.options[a:name]
  let scopes = option.scopes

  for scope in s:_valid_scopes
    if index(scopes, scope) != -1
      if self.provider.is_available(self, scope, a:name)
        return self.provider.get(self, scope, a:name)
      endif
    endif
  endfor

  if default_ovewrite isnot s:_NULL
    return default_ovewrite
  endif
  if options.default is s:_NULL
    echoerr '[Options] Failed to get. The option has no default and not is not set value.'
    return
  endif
  return option.default
endfunction

function s:_options.unset(name, ...) " {{{1
  let opts = a:0 ? a:1 : {}
  let opts.value = s:_UNSET
  call self.set(a:name, opts)
endfunction

function s:_options.set_default(name, ...) " {{{1
  let opts = a:0 ? a:1 : {}
  let opts.value = s:_NULL
  call self.set(a:name, opts)
endfunction

function s:_options.set(name, ...)  " {{{1
  let opts = a:0 ? a:1 : {}
  let value = get(opts, 'value', s:_NULL)
  let scope = get(opts, 'scope', 'g')
  let reporter = '[' . self.plugin_name . '] '
  let optname = "'" . self.namespace . '/' . a:name . "'"

  if type(scope) != v:t_string
    echoerr reporter . 'Invalid type of scope. ' .
          \ 'Only string is accepted.'
    return
  endif

  if type(a:name) != v:t_string
    echoerr reporter . 'Invalid type of option name. ' .
          \ 'Only string names are accepted.'
    return
  endif

  if !has_key(self.options, a:name)
    echoerr reporter . "Invalid option name '" . a:name . "'"
    return
  endif

  " From here, a:name was found to be valid.

  let option = self.options[a:name]
  let scopes = option.scopes

  if scope ==# 'ALL'
    let scope_to_set = scopes
  else
    let scope_to_set = split(scope, '\zs')
  endif


  if option.deprecated isnot 0
    let message = "Option '" . a:name . "' is deprecated."
    if type(option.deprecated) == v:t_string
      let message .= ' ' . option.deprecated
    endif
    echohl WarningMsg
    echomsg reporter . message
    echohl None
  endif

  for scope1 in scope_to_set
    if index(scopes, scope1) == -1
      echoerr reporter . "Invalid scope specification '" . scope . "'. " .
            \ 'Use ones of [' . join(scopes, ', ') . ']'
      return
    endif
  endfor

  if value is s:_NULL
    if option.default isnot s:_NULL
      let value = option.default
    else
      let value = s:_UNSET
    endif
  endif

  if type(option.validator) == v:t_func
    let err = option.validator(optname, value)
    if err isnot 0
      echoerr reporter . err
      return
    endif
  endif

  for scope1 in scope_to_set
    if value is s:_UNSET
      call self.provider.unset(self, scope1, a:name)
    else
      call self.provider.set(self, scope1, a:name, value)
    endif
  endfor
endfunction


function s:_options.user_set(name, value, ...)  " {{{1
  let scope = a:0 ? a:1 : 'g'
  call self.set(a:name, {'value': a:value, 'scope': scope})
endfunction
function s:_options.user_unset(name, ...)  " {{{1
  let scope = a:0 ? a:1 : 'g'
  call self.set(a:name, {'value': s:_UNSET, 'scope': scope})
endfunction
function s:_options.user_get(name)  " {{{1
  return self.get(a:name)
endfunction


function! s:validator_list_eq(candidates) abort  " {{{1
  let validator = {}
  function validator.validate(name, value) abort closure
    for candidate in a:candidates
      if type(candidate) == type(a:value) && candidate ==# a:value
        return 0
      endif
    endfor
    return 'Invalid value is set for option ' . a:name . '.'
  endfunction

  return validator.validate
endfunction


function! s:validator_list_str(candidates) abort  " {{{1
  let validator = {}
  function validator.validate(name, value) abort closure
    if type(a:value) != v:t_string
      return 'Invalid type of value. ' .
            \ "Option '" . a:name . "' only accepts string values."
    endif

    for candidate in a:candidates
      if candidate ==# a:value
        return 0
      endif
    endfor

    return "Invalid value '" . a:value . "' for option " . a:name . '.'
  endfunction

  return validator.validate
endfunction

function! s:_normalize_scopes(scopes) abort
  let normalized = []
  for scope in s:_valid_scopes
    if index(a:scopes, scope) != -1
      call add(normalized, scope)
    endif
  endfor
  return normalized
endfunction

" modelines {{{1
" vim: set fdm=marker

