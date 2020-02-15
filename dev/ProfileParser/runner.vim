
let is_nvim = has('nvim')
let eof = (is_nvim ? "\n" : '')

let spath = expand('<sfile>:p:h')
let root = resolve(spath . '/../..')
let file = get(argv(), 0)
if file =~# 'test_\(.*\).vim$'
  echo 'profile ' . file . eof
  let file = expand(file)
  let name = matchlist(file, 'test_\(.*\)\.vim$')[1]
  let profile_path = (
       \ root . '/test/unit/ProfileParser/fixtures/profile/'
       \ . (is_nvim ? 'nvim_' : 'vim_')
       \ . name . '.profile')
  if !filereadable(profile_path)
    call mkdir(fnamemodify(profile_path, ':p:h'), 'p')
    exe 'profile start' profile_path
    exe 'profile! file' file
    exe 'sil! so' file
  else
    echo '  - already exists. ( rewrite to "make clean" )' . eof
  endif
  qa!
endif

