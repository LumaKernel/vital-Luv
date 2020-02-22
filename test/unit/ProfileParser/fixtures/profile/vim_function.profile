SCRIPT  /test/test_function.vim
Sourced 1 time
Total time:   0.000129
 Self time:   0.000101

count  total (s)   self (s)
                            
    1              0.000007 function!
                                  \ F()
                              echomsg
                               \ 'string'
                               \ . 'string'
                              echo "hello"
                            endfunction
                            
    1   0.000040   0.000012 call F()
                            

FUNCTION  F()
    Defined: /test/original/some/../../test_function.vim:2
Called 1 time
Total time:   0.000029
 Self time:   0.000029

count  total (s)   self (s)
    1              0.000005   echomsg 'string' . 'string'
    1              0.000002   echo "hello"

FUNCTIONS SORTED ON TOTAL TIME
count  total (s)   self (s)  function
    1   0.000029             F()

FUNCTIONS SORTED ON SELF TIME
count  total (s)   self (s)  function
    1              0.000029  F()

