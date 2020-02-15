SCRIPT  /test/test_function.vim
Sourced 1 time
Total time:   0.000094
 Self time:   0.000081

count  total (s)   self (s)
                            
    1              0.000005 function! F()
                              echomsg 'string'
                            endfunction
                            
    1   0.000023   0.000010 call F()
                            

FUNCTION  F()
    Defined: /test/original/some/../test_function.vim line 2
Called 1 time
Total time:   0.000013
 Self time:   0.000013

count  total (s)   self (s)
    1              0.000005   echomsg 'string'

FUNCTIONS SORTED ON TOTAL TIME
count  total (s)   self (s)  function
    1   0.000013             F()

FUNCTIONS SORTED ON SELF TIME
count  total (s)   self (s)  function
    1              0.000013  F()

