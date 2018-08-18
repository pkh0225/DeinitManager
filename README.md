# DeinitManager
🚧 Check Memory Leak (Swift)

##  메모리 해제 확인이 직관적으로 확인이 가능합니다.
Navigation Push 후 Pop을 하면 Pop 후 약 1.5초정도 터치를 막혀져 있어서 클릭이 않됩니다. 

그때 메모리 해제 되지 않는 view 와 Controller가 있다면 이름을 화면에 보여 집니다. 

그러나 정상 해제가 되면 OK 가 나옵니다.


![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/screen.png)
![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/ok.png)
![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/fail.png)

## Core Functions

```
        /*
         self 가 weak 처리 되지 않아 self deinit이 호출되지 않는 문제 코드
         */
        testClosure = {
            print(self)
        }
        
        /*
         정상 코드
         아래 코드 주석 풀어서 확인
         */
//        testClosure = { [weak self] in
//            guard let `self` = self else { return }
//            print(self)
//        }
```
