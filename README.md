# Train

Translator of the new language of interaction nets. 

- The current version is 0.0.6, released on **18 Oct 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



## Getting Started

* Requirement 
  - gcc (>= 4.0), flex, bison

* Build 
  
  Use `make` command as follows (the symbol `$` means a shell prompt):
  
  ```
  $ make
  ```



## How to Execute

* Train starts in the interactive mode by typing the following command (where the symbol `$` is a shell prompt):
	
	```
	$ ./train
	>>> 
	```


* The symbol `>>>` is a prompt of Train. After the prompt you can write rules of the new language. We need the delimiter `;` at the end of a rule. In future, the delimiter will not be required.

  ```
  >>> inc Z = S Z;
  inc(rr_0) >< Z =>
      rr_0~S(Z);
  >>> inc Z = (S Z);
  inc(rr_0) >< Z =>
      rr_0~S(Z);
  >>> inc (S x) = S (inc x);
  inc(rr_0) >< S(x) =>
      inc(ww_1)~x, rr_0~S(ww_1);
  >>>
  ```
  
  
  ```
  >>> add Z x = x;
  add(rr_0, x) >< Z =>
      rr_0~x;
  >>> add (S x) y = S (add x y);
  add(rr_0, y) >< S(x) =>
      add(ww_1, y)~x, rr_0~S(ww_1);
  >>> add (S x) y = add x (S y);
  add(rr_0, y) >< S(x) =>
      add(rr_0, S(y))~x;
  >>>
  ```
  ```
  >>> dup Z = Z,Z;
  dup(rr_0, rr_1) >< Z =>
      rr_0~Z, rr_1~Z;
  >>> dup (S x) = let w1,w2 = dup x in (S w1), (S w2);
  dup(rr_0, rr_1) >< S(x) =>
      rr_0~S(w1), rr_1~S(w2), dup(w1, w2)~x;
  >>>
  ```
  ```
  >>> dup Z = a,b { Dup(a,b)~Z };
  dup(rr_0, rr_1) >< Z =>
      rr_0~a, rr_1~b,
       Dup(a,b)~Z ;
  >>>
  ```
  ```
  >>> inc Int.x = Int.(x+1);
  inc(rr_0) >< Int(int x) =>
      rr_0~Int(x+1);
  >>> add Int.x y = add2.x y;
  add(rr_0, y) >< Int(int x) =>
      add2(rr_0, x)~y;
  >>> add2.x Int.y = Int.(x+y);
  add2(rr_0, int x) >< Int(int y) =>
      rr_0~Int(x+y);
  ```
  
* To quit this system, use `:q` or  `:quit` command:

  ```
  >>> :q
  ```



### Sample

- Fibonacci number

  ```
  fib Z = Z;
  fib (S x) = fibS x;
  fibS Z = (S Z);
  fibS (S x) = add (fibS x1) (fibS x2) { Dup(x1,x2)~x };
  add Z x = x;
  add (S y) x = S(add x y);
  ```
  
  



## Limitation

The current version has some limitations:

- Nested terms of Let and Bundle are not supported. This will be solved in the next version.
- Expressions are not supported, just for rules for now. This will be solved in the later version.
- Built-in constants such as Cons, Nil are not supported.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
