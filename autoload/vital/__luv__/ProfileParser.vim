" Vim Profile Parser
" License: Unlicensed

let s:section_types = [
      \   [ '^FUNCTIONS SORTED ON\>', 's:_parse_function_list_section'],
      \   [ '^FUNCTION\>', 's:_parse_function_section'],
      \   [ '^SCRIPT\>', 's:_parse_script_section'],
      \ ]
let s:float_pat = '\%(\d\+\%(\.\d\+\)\?\)'  " like  0.0  0  , safe for str2float()

function! s:parse(lines) abort
  let next = 0
  let buf = []
  let sections = []
  for line in a:lines
    let section_type = filter(map(deepcopy(s:section_types), {i,e -> [line =~# e[0], e[1]]}), {i,e -> e[0]})
    if len(section_type)
      if next isnot 0
        call add(sections, call(next, [buf]))
      endif
      let next = section_type[0][1]
      let buf = []
    endif
    call add(buf, line)
  endfor
  if next isnot 0
    call add(sections, call(next, [buf]))
  endif
  return sections
endfunction

function! s:_parse_script_section(lines) abort
  let res = { 'type': 'script' }
  let itr = 0
  while itr < len(a:lines)
    let line = a:lines[itr]
    let pat = '^SCRIPT\>\s\+\(.*\)'
    if line =~# pat
      let res.path = expand(matchlist(line, pat)[1])
    endif

    let pat = '^Sourced\s\+\(\d\+\)'
    if line =~? pat && !has_key(res, 'count')
      let res.count = str2nr(matchlist(line, pat)[1])
    endif
    let pat = '^\s*Total time:\s\+\(' . s:float_pat . '\)'
    if line =~? pat && !has_key(res, 'total_time')
      let res.total_time = str2float(matchlist(line, pat)[1])
    endif
    let pat = '^\s*Self time:\s\+\(' . s:float_pat . '\)'
    if line =~? pat && !has_key(res, 'self_time')
      let res.self_time = str2float(matchlist(line, pat)[1])
    endif
    let pat = '^count\>'
    if line =~? pat && !has_key(res, 'lines')
      let res.lines = []
      let itr += 1
      while itr < len(a:lines) && a:lines[itr] != ''
        call add(res.lines, s:_parse_line(a:lines[itr], 'content', 1))
        let itr += 1 
      endwhile
    else
      let itr += 1
    endif
  endwhile
  let res.lines = get(res, 'lines', [])
  let res.count = get(res, 'count', 0)
  return res
endfunction

function! s:_parse_function_section(lines) abort
  let res = { 'type': 'function' }
  
  let itr = 0
  while itr < len(a:lines)
    let line = a:lines[itr]
    let pat = '^FUNCTION\>\s\+\(.*\)'
    if line =~# pat && !has_key(res, 'name')
      let res.name = matchlist(line, pat)[1]
      let pat = '\s\+Defined: \(.*\):\(\d\+\)'
      if itr + 1 < len(a:lines) && a:lines[itr + 1] =~? pat
        let groups = matchlist(a:lines[itr + 1], pat)
        let res.defined = {
              \   'path' : expand(groups[1]),
              \   'line' : str2nr(groups[2]),
              \ }
        let itr += 2
        continue
      endif
    endif

    let pat = '^Sourced\s\+\(\d\+\)'
    if line =~? pat && !has_key(res, 'count')
      let res.count = str2nr(matchlist(line, pat)[1])
    endif
    let pat = '^\s*Total time:\s\+\(' . s:float_pat . '\)'
    if line =~? pat && !has_key(res, 'total_time')
      let res.total_time = str2float(matchlist(line, pat)[1])
    endif
    let pat = '^\s*Self time:\s\+\(' . s:float_pat . '\)'
    if line =~? pat && !has_key(res, 'self_time')
      let res.self_time = str2float(matchlist(line, pat)[1])
    endif
    let pat = '^count\>'
    if line =~? pat && !has_key(res, 'lines')
      let res.lines = []
      let itr += 1
      while itr < len(a:lines) && a:lines[itr] != ''
        call add(res.lines, s:_parse_line(a:lines[itr], 'content', 1))
        let itr += 1 
      endwhile
    else
      let itr += 1
    endif
  endwhile
  let res.lines = get(res, 'lines', [])
  let res.count = get(res, 'count', 0)
  return res
endfunction

function! s:_parse_function_list_section(lines) abort
  let res = { 'type': 'function_list' }
  
  let itr = 0
  let res.functions = []
  while itr < len(a:lines)
    let line = a:lines[itr]
    let pat = '^FUNCTIONS SORTED ON\>\s\+\(.*\)'
    if line =~# pat && !has_key(res, 'what')
      let res.what = matchlist(line, pat)[1]
    endif

    let pat = '^count\>'
    if line =~? pat
      let itr += 1
      while itr < len(a:lines) && a:lines[itr] != ''
        let res.functions = []
        call add(res.functions, s:_parse_line(a:lines[itr], 'name', 2))
        let itr += 1 
      endwhile
    else
      let itr += 1
    endif
  endwhile
  let res.functions = get(res, 'functions', [])
  return res
endfunction

function! s:_parse_line(line, last_key, space_num) abort
  let pat = ' \{-\}'
        \ . '\%( \{,4\}\(\d\+\)\| \{5\}\)' . '  '
        \ . '\%( \{,8\}\(' . s:float_pat . '\)\| \{9\}\)' . '   '
        \ . '\%( \{,7\}\(' . s:float_pat . '\)\| \{8\}\)'
        \     . ' \{' . a:space_num . '\}'
        \ . '\(.*\)'
  let res = {}
  let res[a:last_key] = ''
  if a:line =~# pat
    let groups = matchlist(a:line, pat)
    if groups[1][0] !=# ''
      let res.count = str2nr(groups[1])
    endif
    if groups[2][0] !=# ''
      let res.total_time = str2float(groups[2])
    endif
    if groups[3][0] !=# ''
      let res.self_time = str2float(groups[3])
    endif
    let res[a:last_key] = groups[4]
  endif
  return res
endfunction

