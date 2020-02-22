SCRIPT  /test/test_no_function.vim
Sourced 1 time
Total time:   0.000160
 Self time:   0.000160

count  total (s)   self (s)
                            
    3              0.000011 for i in range(2)
                            
    2              0.000003   if i == 1
    1              0.000002     let a = round(0.5)
    1              0.000017     echo a
    1              0.000002   else
    1              0.000013     if x == 1 | let b = len([]) | endif
                                echo b
    1              0.000001   endif
    2              0.000007 endfor
                            

