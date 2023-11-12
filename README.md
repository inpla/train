# Train

Translator of the new language of interaction nets. 

- The current version is 0.1.1, released on **12 Nov 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



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
  >>> add Z,x = x;
  add(rr_0, x) >< Z =>
      rr_0~x;
  >>> add (S x),y = S (add x,y);
  add(rr_0, y) >< S(x) =>
      add(ww_1, y)~x, rr_0~S(ww_1);
  >>> add (S x),y = add x,(S y);
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
  >>> add (Int.x), y = add2.x y;
  add(rr_0, y) >< Int(int x) =>
      add2(rr_0, x)~y;
  >>> add2.x Int.y = Int.(x+y);
  add2(rr_0, int x) >< Int(int y) =>
      rr_0~Int(x+y);
  ```
  ```
  >>> foo Int.x = if x==1 then Int.x+1 else if x==2 then Int.x+10 else Int.x+100;
  foo(rr_0) >< Int(int x) =>
      if x==1 then rr_0~Int(x+1) else if x==2 then rr_0~Int(x+10) else rr_0~Int(x+100);
  >>>
  ```
  
* To quit this system, use `:q` or  `:quit` command:

  ```
  >>> :q
  ```



### Sample

- Fibonacci number

  ```
  -- definitions
  fib Z = Z;
  fib (S x) = fibS x;
  fibS Z = (S Z);
  fibS (S x) = add (fib x1), (fibS x2) { Dup(x1,x2)~x };
  add Z,x = x;
  add (S y),x = S(add x,y);
  
  -- main
  main = fib (S(S(S(S(S(S Z)))))); -- should be 8 because 0 1 1 2 3 5 8
  ```

- GCD

  ```
  (* Sample in Python
   def gcd(a, b):
     if b==0: return a 
     else: return gcd(b, a%b)
  *)
  
  gcd Pair.(a,b) = 
    if b==0 then Int.a 
    else gcd Pair.(b, a%b);
  
  
  -- main
  main = gcd Pair.(14,21);  -- should be 7.
  ```
  
  



## Limitation

The current version has some limitations:

- The number of bundles of functions must be one for now. In future, these numbers are recorded with function symbols, and correctly decided.

- Built-in constants such as Cons, Nil are not supported.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
