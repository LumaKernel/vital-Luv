" Source Map Revision 3
" Spec: https://sourcemaps.info/spec.html
" Spec: v3: https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit?usp=sharing
" Ref: https://github.com/mozilla/source-map
" Ref: https://github.com/babel/babel

function! s:_vital_depends() abort
  return [
        \   'Data.Base64.VLQ',
        \   'System.Filepath',
        \]
endfunction
function! s:_vital_loaded(V) abort
  let s:VLQ = a:V.import('Data.Base64.VLQ')
endfunction

let s:R = 'vital: SourceMap: '

" type Loc = Array<number, 2>
"    - 0-indexed, [line, col]
" type SrcInfo = { loc: Loc, source?: string, name?: string }


let s:v3 = { 'version': 3 }
function! s:new() abort
  let self = deepcopy(s:v3)
  return self
endfunction

function! s:from_json(json) abort
  if type(a:json) != v:t_dict | throw s:R.'JSON must be dictionary.' | endif
  if !has_key(a:json, 'version') || a:json.version isnot 3
    throw s:R.'Not supported version is given.'
  endif

  let sourcemap = s:new()
  if has_key(a:json, 'mappings') == has_key(a:json, 'sections')
    throw s:R.'JSON must have one of .mappings or .sections.'
  endif

  if has_key(sourcemap, 'file') && type(sourcemap.file) == v:t_string
    let sourcemap.file = a:json.file
  endif

  if has_key(a:json, 'mappings')
    let sourcemap.mappings = []
    call s:_add_mappings(sourcemap, a:json)
  endif

  if has_key(a:json, 'sections') && type(a:json.sectins) == v:t_list
    if type(a:json.sections) != v:t_list
      throw s:R.'Entry .sections must be list.'
    endif
    let sourcemap.sections = []
    for section in a:json.sections
      if !has_key(section, 'offset') || type(section) != v:t_string
        throw s:R.'Sections must have string .offset.'
      endif
      if !has_key(section.offset, 'line')
            \ || !has_key(section.offset, 'column')
            \ || type(sections.offset.line) != v:t_number
            \ || type(sections.offset.column) != v:t_number
        throw s:R.'Sections .offset must have number .line and .column.'
      endif
      if has_key(section, 'map') == has_key(section, 'url')
        throw s:R.'Sections must have one of .map or .url.'
      endif
      let loc = [sections.offset.line, sections.offset.column]
      if has_key(section, 'map')
        call add(sourcemap.sections, [loc, s:from_json(section)])
      else
        call add(sourcemap.sections, [loc, s:consume_url(section.url)])
      endif
    endfor
  endif
  return sourcemap
endfunction


function! s:_add_mappings(sourcemap, json) abort
  let sourcemap = a:sourcemap

  if has_key(a:json, 'sourceRoot') && type(a:json.sourceRoot) == v:t_string
    let sourcemap.sourceRoot = get(a:json, 'sourceRoot')
  endif
  if has_key(a:json, 'mappings') && type(a:json.mappings) != v:t_string
    throw s:R.'.mappings entry must exist and be string.'
  endif
  if has_key(a:json, 'sources') && type(a:json.sources) == v:t_list
    let sources = map(a:json.sources,
                  \ 'type(v:val) == v:t_string ? v:val : ""')
  else
    throw s:R.'.sources entry must exist and be list.'
  endif
  if has_key(a:json, 'sourcesContent')
    \ && type(a:json.sourcesContent) == v:t_list
    if len(a:json.sources) != len(a:json.sourcesContent)
      throw s:R.'.sources and .sourcesContent must have same length.'
    endif
    let idx = 0
    let sourcemap.sourcesContent = {}
    while idx < len(a:json.sourcesContent)
      let content = a:json.sourcesContent[idx]
      let sourcemap.sourcesContent[a:json.sources[idx]] =
            \ type(content) == v:t_string
            \ ? content
            \ : v:null
      let idx += 1
    endwhile
  endif
  if has_key(a:json, 'names') && type(a:json.names) == v:t_list
    let names = map(a:json.names,
                    \ 'type(v:val) == v:t_string ? v:val : ""')
  else
    throw s:R.'.names entry must exist and be list.'
  endif

  let segments = split(a:json.mappings, ';', 1)
  let out_line = 0
  let src_idx = 0
  let line = 0
  let col = 0
  for segment in segments
    let out_col = 0
    let fields = split(segment, ',')
    for field in fields
      if !s:VLQ.is_valid_VLQ(field)
        throw s:R.'Invalid Base64 in mappings.'
      endif
      let one = s:VLQ.decode(field)
      if len(one) < 1 || len(one) > 5
        throw s:R.'Invalid length of field.'
      endif
      let out_col += one[0]
      let info = v:null
      if len(one) > 1
        let info = {}
        if len(one) < 4 | throw s:R.'Invalid length of field.' | endif
        if src_idx < 0 || src_idx >= len(sources)
          throw s:R.'Field source index is out of range.'
        endif
        let src_idx += one[1]
        let info.source = sources[src_idx]
        let line += one[2]
        let col += one[3]
        let info.loc = [line, col]
      endif
      if len(one) == 5
        if one[4] < 0 || one[4] >= len(names)
          throw s:R.'Field name index is out of range.'
        endif
        let info.name = names[one[4]]
      endif
      call sourcemap.add_mapping([out_line, out_col], info)
    endfor
    let out_line += 1
  endfor
endfunction

" @param {Loc} loc
" @return {{
"   from: Loc | null,
"   to: Loc | null,
"   info: SrcInfo | null,
"   sourceRoot?: string
" }}
function! s:v3.apply(loc) abort
  let max_of_le = v:null
  let min_of_gt = v:null
  let sourceRoot = v:null
  let maps = []
  let map = self
  let offset = [0, 0]
  while 1
    if self.is_mapping_mode()
      for mapping in self.mappings
        let mapping[0] = s:advance_offset(mapping[0], offset)
        if s:_loc_cmp(mapping[0], a:loc) <= 0
          if max_of_le is v:null || s:_loc_cmp(max_of_le[0], mapping[0]) < 0
            let max_of_le = deepcopy(mapping)
            let sourceRoot = get(map, sourceRoot, v:null)
          endif
        else
          if min_of_gt is v:null || s:_loc_cmp(min_of_gt, mapping[0]) > 0
            let min_of_gt = copy(mapping[0])
          endif
        endif
      endfor
    else
      for section in self.sections
        if has_key(section, 'map')
          call add(maps, [section.offset, section.map])
        else
        endif
      endfor
    endif
    if len(maps)
      let [rel_offset, map] = remove(maps, 0)
      let offest = s:advance_offset(offset, rel_offset)

      if min_of_gt is v:null || s:_loc_cmp(min_of_gt, offset) > 0
        let min_of_gt = copy(offset)
      endif
    else
      break
    endif
  endwhile
  let image = {
        \   'from': max_of_le isnot v:null ? max_of_le[0] : v:null,
        \   'to': min_of_gt isnot v:null ? min_of_gt : v:null,
        \   'info': max_of_le isnot v:null ? max_of_le[1] : v:null
        \ }
  if sourceRoot isnot v:null
    let image.sourceRoot = sourceRoot
  endif
  return image
endfunction

function! s:v3.to_json() abort
  let res = { 'version': 3 }
  if has_key(self, 'file') | let res.file = self.file | endif
  if self.is_mapping_mode()
    if has_key(self, 'sourceRoot')
      let res.sourceRoot = self.sourceRoot
    endif
    let mappings = self.mappings
    call sort(mappings, {lhs, rhs -> s:_loc_cmp(lhs[0], rhs[0])})
    call Dump([json_encode(mappings)], '.dev/hoge.json')
    let res.sources = []
    let res.sourcesContent = []
    let res.names = []
    let last = [0, 0, 0, 0, 0]
    let segments = []
    let line = 0
    let itr = 0
    while itr < len(mappings)
      let fields = []
      while itr < len(mappings) && mappings[itr][0][0] == line
        let field = []
        let mapping = mappings[itr]
        call add(field, mapping[0][1] - last[0])
        let last[0] = mapping[0][1]
        if mapping[1] isnot v:null && has_key(mapping[1], 'source')
          let src = mapping[1].source
          let src_idx = index(res.sources, src)
          if src_idx == -1
            let src_idx = len(res.sources)
            call add(res.sources, src)
            call add(res.sourcesContent,
                  \ get(get(self, 'sourcesContent', {}), mapping[1].source, v:null))
          endif
          call add(field, src_idx - last[1])
          call add(field, mapping[1].loc[0] - last[2])
          call add(field, mapping[1].loc[1] - last[3])
          let last[1] = src_idx
          let last[2] = mapping[1].loc[0]
          let last[3] = mapping[1].loc[1]
          if has_key(mapping[1], 'name')
            let name = mapping[1].name
            let name_idx = index(res.names, name)
            if name_idx == -1
              let name_idx = len(res.names)
              call add(res.names, mapping[1].name)
            endif
            call add(field, name_idx - last[4])
            let last[4] = name_idx
          endif
        endif
        call add(fields, s:VLQ.encode(field))
        let itr += 1
      endwhile
      call add(segments, join(fields, ','))
      let last[0] = 0
      let line += 1
    endwhile
    let res.mappings = join(segments, ';')
  else
    let res.sections = []
    for section in self.sections
      let res_sec = { 'offset': section.offset }
      if has_key(section, 'url')
        let res_sec.url = section.url
      else
        let res_sec.map = section.map.to_json()
      endif
      call add(res.section, res_sec)
    endfor
  endif
  return res
endfunction

function! s:v3.is_mapping_mode() abort
  return has_key(self, 'mappings')
endfunction

" @param {string} src
" @param {string | null} content
function! s:v3.set_source_content(src, content) abort
  if !self.is_mapping_mode() | throw s:R.'Using sections mode.' | endif
  let self.sourcesContent[a:src] = a:content
endfunction

" @param {Loc} out Location for generated code
" @param {SrcInfo | null} info
function! s:v3.add_mapping(out, info) abort
  if !self.is_mapping_mode() | throw s:R.'Using sections mode.' | endif
  call add(self.mappings, [a:out, a:info])
endfunction

" @param {Section} section
function! s:v3.add_section(section) abort
  if self.is_mapping_mode() | throw s:R.'Using mappings mode.' | endif
  call add(self.section, a:section)
endfunction

function! s:advance_offset(loc, offset) abort
  if a:loc[0] == 0 | return [a:offset[0], a:offset[1] + a:loc[1]] | endif
  return [a:offset[0] + a:loc[0], a:loc[1]]
endfunction

function! s:_loc_cmp(loc_l, loc_r) abort
  return a:loc_l[0] != a:loc_r[0] ? a:loc_l[0] - a:loc_r[0] : a:loc_l[1] - a:loc_r[1]
endfunction

