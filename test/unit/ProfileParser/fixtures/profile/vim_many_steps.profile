SCRIPT  /test/test_many_steps.vim
Sourced 1 time
Total time:   4.487671
 Self time:   4.487671

count  total (s)   self (s)
    1              0.000004 let x = 0
1000001              0.991788 for i in range(1000000)  " 1e6
1000000              1.132484   let x += 1
1000001              0.819056 endfor
    1              0.000015 echo x
                            

