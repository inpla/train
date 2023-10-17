# Train

Translator of the new language of interaction nets. 

- The current version is 0.0.5-1, released on **16 Oct 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



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
  >>> inc (S x) = let w = inc x in (S w);
  inc(rr_0) >< S(x) =>
      rr_0~S(w), inc(w)~x;
  >>>
  ```
  
  
  ```
  >>> add Z x = x;
  add(rr_0, x) >< Z =>
      rr_0~x;
  >>> add (S y) x = let w=add y x in (S w);
  add(rr_0, x) >< S(y) =>
      rr_0~S(w), add(w, x)~y;
  >>> add (S y) x = add y (S x);
  add(rr_0, x) >< S(y) =>
      add(rr_0, S(x))~y;
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
  fibS (S x) = 
    let w1=(fibS x1) in 
    let w2=(fibS x2) in 
    add w1 w2 
    { Dup(x1,x2)~x };
  
  add Z x = x;
  add (S y) x = let w=(add x y) in S w;
  ```

  



## Limitation

The current version has some limitations:

- Nested terms are not supported. This will be solved in the next version.
- Expressions are not supported, just for rules for now. This will be solved in the later version.
- Built-in constants such as Cons, Nil are not supported.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
