
if has('nvim')
  echo 1
else
  echo 1
endif

let s:_providers = {}
function! s:_vital_loaded(V) abort
  let s:L = a:V.import('Data.List')

  let s:_providers['_'] = a:V.import('Options.Underline')
  let s:_providers['#'] = a:V.import('Options.Sharp')
  let s:_providers['object'] = a:V.import('Options.Object')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Data.List',
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


function! s:new(namespace, ...) abort  " {{{
  let opts = a:0 ? a:1 : {}

  let self = deepcopy(s:_options)
  let self.plugin_name = get(opts, 'plugin_name', a:namespace)
  let self.provider = get(opts, 'provider', '_')

  if type(self.provider) == v:t_string
    if !has_key(s:_providers, self.provider)
      echoerr '[Options] Avaliable providers are ' . join(map(keys(s:_providers), '"''" . v:val . "''"'), ', ') . '.'
    endif
    let self.provider = s:_providers[self.provider]
  endif

  let self.namespace = a:namespace
  return self
endfunction  " }}}

" member varialbles
let s:_options.options = {}
let s:_options.names = []

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
  let Validator = get(opts, 'validator', s:_NULL)
  let select = get(opts, 'select', s:_NULL)
  let no_define_default = get(opts, 'no_define_default', 0) || Default is s:_NULL
  let scopes = reverse(split(get(opts, 'scopes', 'g'), '\zs'))
  let type = get(opts, 'type', s:_NULL)
  let formatted_type = get(opts, 'formatted_type', s:_NULL)
  let doc = get(opts, 'doc', s:_NULL)

  if matchstr(join(scopes, ''), '[^gtwb]') !=# ''
    echoerr "[Options] Each scopes should be oen of '" . string(s:_valid_scopes) . "'."
  endif

  if len(scopes) == 0
    echoerr '[Options] Scopes cannot be empty'
  endif

  if select isnot s:_NULL && type(select) != v:t_list
    echoerr "[Options] 'select' must be list."
  endif

  if Validator isnot s:_NULL && type(Validator) != v:t_func
    echoerr "[Options] 'validator' must be function."
  endif

  if !no_define_default
    call self.provider.set(self, 'g', a:name, Default)
  endif

  if has_key(self.options, a:name)
    echoerr "[Options] Option '" . a:name . "' duplicates."
  endif

  if type isnot s:_NULL
    let type = s:_type_to_list(type)
    if formatted_type is s:_NULL
      let formatted_type = s:_format_type(type)
    endif
  endif

  call add(self.names, a:name)
  let self.options[a:name] = {
        \   'name': a:name,
        \   'scopes': scopes,
        \   'deprecated': deprecated,
        \   'default': Default,
        \   'validator': Validator,
        \   'select': select,
        \   'type': type,
        \   'formatted_type': formatted_type,
        \   'doc': doc,
        \ }

  if Default isnot s:_NULL
    call self.set(a:name, { 'value': Default, '_only_test': 1 })
  endif
endfunction


function s:_options.is_set(name)  " {{{1
  return self.get(a:name, {'_ignore_unset': 1}) isnot s:_NULL
endfunction

function s:_options.get(name, ...)  " {{{1
  let opts = a:0 ? a:1 : {}
  let default_overwrite = get(opts, 'default_overwrite', s:_NULL)

  let _ignore_unset = get(opts, '_ignore_unset', 0)

  let reporter = '[' . self.plugin_name . '] '

  if !has_key(self.options, a:name)
    echoerr reporter . "Unknown option name '" . a:name . "'"
  endif

  let option = self.options[a:name]
  let scopes = option.scopes

  for scope in scopes
    if self.provider.is_available(self, scope, a:name)
      return self.provider.get(self, scope, a:name)
    endif
  endfor

  if default_overwrite isnot s:_NULL
    return default_overwrite
  endif
  if option.default is s:_NULL && !_ignore_unset
    echoerr '[Options] Failed to get. The option has no default and is not set value.'
  endif
  return option.default
endfunction

function s:_options.unset(name, ...) " {{{1
  let opts = a:0 ? copy(a:1) : {}
  let opts.value = s:_UNSET
  call self.set(a:name, opts)
endfunction

function s:_options.set_default(name, ...) " {{{1
  let opts = a:0 ? copy(a:1) : {}
  let opts.value = s:_NULL
  call self.set(a:name, opts)
endfunction

function s:_options.set(name, ...) abort  " {{{1
  let opts = a:0 ? a:1 : {}
  let value = get(opts, 'value', s:_NULL)
  let scope = get(opts, 'scope', s:_NULL)
  let reporter = '[' . self.plugin_name . '] '

  let _only_test = get(opts, '_only_test', 0)

  if type(scope) != v:t_string && scope isnot s:_NULL
    echoerr reporter . 'Invalid type of scope. ' .
          \ 'Only string is accepted.'
  endif

  if type(a:name) != v:t_string
    echoerr reporter . 'Invalid type of option name. ' .
          \ 'Only string names are accepted.'
  endif

  if !has_key(self.options, a:name)
    echoerr reporter . "Unknown option name '" . a:name . "'"
  endif

  " From here, a:name was found to be valid.

  let reporter = '[' . self.plugin_name . '/' . a:name . '] '

  let option = self.options[a:name]
  let scopes = option.scopes

  if scope is s:_NULL
    let scope = scopes[-1]
  endif

  if scope ==# 'ALL'
    let scope_to_set = scopes
  else
    let scope_to_set = split(scope, '\zs')
  endif

  if option.deprecated isnot 0 && !_only_test
    let message = "Option '" . a:name . "' is deprecated."
    if type(option.deprecated) == v:t_string
      let message .= ' ' . option.deprecated
    endif
    echohl WarningMsg
    echomsg reporter . message
    echohl None
  endif

  if value is s:_NULL
    if option.default isnot s:_NULL
      let value = option.default
    else
      let value = s:_UNSET
    endif
  endif

  " Here, value is not s:_NULL.

  for scope1 in scope_to_set
    if index(scopes, scope1) == -1
      echoerr reporter . "Invalid scope specification '" . scope . "'. " .
            \ 'Use ones of [' . join(scopes, ', ') . ']'
    endif
  endfor

  if value isnot s:_UNSET
    " -- option value checks from here

    if option.type isnot s:_NULL
      if index(option.type, get(s:_num2type, type(value), 0)) == -1
        echoerr reporter . 'Invalid type of value. ' .
              \ "Type must be '" . option.formatted_type . "'."
      endif
    endif

    if option.select isnot s:_NULL
      let found = 0
      for candidate in option.select
        if type(value) == type(candidate) && value ==# candidate
          let found = 1 | break
        endif
      endfor
      if !found
        echoerr reporter . 'Invalid value ' . string(value) . '. ' .
              \ 'Selections are ' . string(option.select) . ' .'
      endif
    endif

    if option.validator isnot s:_NULL
      let err = option.validator(value)
      if err isnot 0
        echoerr reporter . err
      endif
    endif
  endif

  if _only_test | return | endif


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
function s:_options.generate_document()  " {{{1
  " FIXME : Not supporting multibyte
  let res = []
  for name in self.names
    let option = self.options[name]
    let tag = '*' . self.provider.name(self, name) . '*'
    call add(res, repeat("\t", min([10 - ((strlen(tag)+7)/8), 5])) . tag)
    call add(res, self.provider.format(self, reverse(copy(option.scopes)), name))
    if option.deprecated isnot 0
      let message = 'DEPRECATED'
      if type(option.deprecated) == v:t_string
        let message .= ' : ' . option.deprecated
      endif
      call add(res, "\t" . message)
    endif
    if option.default isnot s:_NULL
      call add(res, "\t" . 'Default : `' . string(option.default) . '`')
    endif
    if option.type isnot s:_NULL
      call add(res, "\t" . 'Type : ' . option.formatted_type)
    endif
    if option.select isnot s:_NULL
      call add(res, "\t" . 'Selections : `' . string(option.select) . '`')
    endif
    if option.doc isnot s:_NULL
      call add(res, '')
      for para in option.doc
        for line in s:_format_paragraph(para, 72)
          call add(res, "\t" . line)
        endfor
      endfor
    endif
    call add(res, '')
  endfor
  return res
endfunction
" function! s:format_paragraph(para, width) {{{1
let s:_break_chars =
      \ ['.', ',', ' ', '-\%(\w\)\=']
      \ + map(["'", '"', '|', '\*', '`'], 'v:val . ''\%(\s\)\=''')
function! s:_format_paragraph(para, width) abort
  let lines = []
  let para = a:para
  while para !=# ''
    " width +- 7  --> found break marks, break
    let cont = 0
    for i in [0] + s:L.flatten(map(range(7), '[v:val, -v:val]'))
      if index(s:_break_chars, para[a:width + i - 1]) != -1
        call add(lines, para[: a:width + i - 1])
        " remove trailing space
        if lines[-1] =~# '\s$'
          let lines[-1] = lines[-1][: strlen(lines[-1]) - 2]
        endif
        let para = para[a:width + i :]
        let cont = 1 | break
      endif
    endfor
    if cont | continue | endif

    " -->  breaks

    if para[a:width - 1] =~# '\w'
      call add(lines, para[: a:width - 2] . '-')
      let para = para[a:width - 1:]
    else
      call add(lines, para[: a:width - 1])
      let para = para[a:width:]
    endif
  endwhile
  return lines
endfunction


" }}}

" Internal functions
function! s:_type_to_list(type_like) abort  " {{{1
  if type(a:type_like) == v:t_string
    let stripped = substitute(a:type_like, '\_s\+', '', 'g')
    return split(stripped, '|')
  elseif type(a:type_like) == v:t_number
    if !has_key(s:_num2type, a:type_like)
      echoerr '[Options] Invalid type number.'
    endif
    return [s:_num2type[a:type_like]]
  elseif type(a:type_like) == v:t_list
    return map(copy(a:type_like), 's:_type_to_list(v:val)[0]')
  else
    echoerr '[Options] Invalid type specification.'
  endif
endfunction

function! s:_format_type(type) abort  " {{{1
  return join(a:type, ' | ')
endfunction


" modelines {{{1
" vim: set fdm=marker

