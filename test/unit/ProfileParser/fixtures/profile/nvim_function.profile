SCRIPT  /test/test_function.vim
Sourced 1 time
Total time:   0.000103
 Self time:   0.000079

count  total (s)   self (s)
                            
    1              0.000005 function!
                                  \ F()
                              echomsg
                               \ 'string'
                               \ . 'string'
                              echo "hello"
                            endfunction
                            
    1   0.000043   0.000019 call F()
                            

FUNCTION  F()
    Defined: /test/original/some/../../test_function.vim line 3
Called 1 time
Total time:   0.000023
 Self time:   0.000023

count  total (s)   self (s)
    1              0.000014   echomsg 'string' . 'string'
    1              0.000003   echo "hello"

FUNCTIONS SORTED ON TOTAL TIME
count  total (s)   self (s)  function
    1   0.000023             F()

FUNCTIONS SORTED ON SELF TIME
count  total (s)   self (s)  function
    1              0.000023  F()

