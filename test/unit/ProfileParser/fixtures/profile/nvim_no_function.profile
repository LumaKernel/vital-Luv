SCRIPT  /test/test_no_function.vim
Sourced 1 time
Total time:   0.000288
 Self time:   0.000288

count  total (s)   self (s)
                            
    3              0.000024 for i in range(2)
                            
    2              0.000003   if i == 1
    1              0.000026     let a = round(0.5)
    1              0.000015     echo a
    1              0.000002   else
    1              0.000026     if x == 1 | let b = len([]) | endif
                                echo b
    1              0.000001   endif
    2              0.000031 endfor
                            

