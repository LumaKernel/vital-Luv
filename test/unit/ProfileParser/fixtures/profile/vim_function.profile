SCRIPT  /test/test_function.vim
Sourced 1 time
Total time:   0.000149
 Self time:   0.000142

count  total (s)   self (s)
                            
    1              0.000003 function! F()
                              echomsg 'string'
                            endfunction
                            
    1   0.000050   0.000043 call F()
                            

FUNCTION  F()
    Defined: /test/original/some/../../test_function.vim:2
Called 1 time
Total time:   0.000008
 Self time:   0.000008

count  total (s)   self (s)
    1              0.000005   echomsg 'string'

FUNCTIONS SORTED ON TOTAL TIME
count  total (s)   self (s)  function
    1   0.000008             F()

FUNCTIONS SORTED ON SELF TIME
count  total (s)   self (s)  function
    1              0.000008  F()

