
let is_nvim = has('nvim')

let spath = expand('<sfile>:p:h')
let root = resolve(spath . '/../..')
let file = get(argv(), 0)
if file =~# 'test_\(.*\).vim$'
  echo 'profile ' . file . (is_nvim ? "\n" : '')
  let file = expand(file)
  let name = matchlist(file, 'test_\(.*\)\.vim$')[1]
  exe 'profile start' (
       \ root . '/test/unit/ProfileParser/fixtures/'
       \ . (is_nvim ? 'nvim_' : 'vim_')
       \ . name . '.profile')
  exe 'profile! file' file
  exe 'sil! so' file
  qa!
endif

