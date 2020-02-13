" Base64 VLQ used in Source Map Revision 3
" Ref: https://en.wikipedia.org/wiki/Variable-length_quantity

" @param {[number-like]} numbers
" @return {Base64String}
function! s:encode(numbers) abort
  let buf = []
  for num in a:numbers
    let byte = 0
    " XXX : assume that type is {number}
    if num < 0
      let num = -num
      let byte += 1  " byte |= 0b000001
    endif
    let byte += (num % 16) * 2  " (num & 0b001111) << 1

    let num = num / 16  " num >>= 4
    while num > 0
      let byte += 32  " byte |= 0b100000
      call add(buf, byte)
      let byte = num % 32  " byte = num & 0b011111
      let num = num / 32  " num >>= 5
    endwhile
    call add(buf, byte)
  endfor
  return join(map(buf, 's:rfc4648_encode_table[v:val]'), '')
endfunction

" @param {Base64String} str
" @return {[number-like]}
function! s:decode(str) abort
  let bytes = map(split(a:str, '\zs'), 's:rfc4648_decode_map[v:val]')
  let buf = []
  let itr = 0
  while itr < len(bytes)
    let byte = bytes[itr]
    let sign = byte % 2
    " XXX : assume that it can be expressiable in number

    let num = (byte / 2) % 16  " (byte >> 1) & 0b001111
    let bias = 16  " bias = 1 << 4
    while byte / 32  " byte & 0b100000
      let itr += 1
      let byte = bytes[itr]
      let num += (byte % 32) * bias  " byte & 0b011111
      let bias = bias * 32  " bias <<= 5
    endwhile
    if sign | let num = -num | endif
    call add(buf, num)
    let itr += 1
  endwhile
  return buf
endfunction

let s:is_padding = 0
let s:padding_symbol = ''
let s:is_padding_symbol = { -> 0}

let s:rfc4648_encode_table = [
      \ 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
      \ 'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
      \ 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
      \ 'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/']

let s:rfc4648_decode_map = {}
for i in range(len(s:rfc4648_encode_table))
  let s:rfc4648_decode_map[s:rfc4648_encode_table[i]] = i
endfor

