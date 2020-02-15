SCRIPT  /test/test_many_steps.vim
Sourced 1 time
Total time:   5.855752
 Self time:   5.855752

count  total (s)   self (s)
    1              0.000018 let x = 0
1000001              1.255137 for i in range(1000000)  " 1e6
1000000              1.359367   let x += 1
1000001              1.037135 endfor
    1              0.000023 echo x
                            

