# Train

Translator of the new language of interaction nets. 

- The current version is 0.1.3, released on **20 Nov 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



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
  inc(r0) >< Z =>
      r0~S(Z);
  >>> inc Z = (S Z);
  inc(r0) >< Z =>
      r0~S(Z);
  >>> inc (S x) = S(inc x);
  inc(r0) >< S(x) =>
      inc(w0)~x, r0~S(w0);
  >>>
  ```
  
  
  ```
  >>> add Z,x = x;
  add(r0, x) >< Z =>
      r0~x;
  >>> add (S x),y = S (add x,y);
  add(r0, y) >< S(x) =>
      add(w0, y)~x, r0~S(w0);
  >>> add (S x),y = add x,(S y);
  add(r0, y) >< S(x) =>
      add(r0, S(y))~x;
  >>>
  ```
  ```
  >>> dup Z = Z,Z;
  dup(r0, r1) >< Z =>
      r0~Z, r1~Z;
  >>> dup (S x) = let w1,w2 = dup x in (S w1), (S w2);
  dup(r0, r1) >< S(x) =>
      r0~S(w1), r1~S(w2), dup(w1, w2)~x;
  >>>
  ```
  ```
  >>> dup Z = a,b { Dup(a,b)~Z };
  dup(r0, r1) >< Z =>
      r0~a, r1~b,
       Dup(a,b)~Z ;
  >>>
  ```
  ```
  >>> inc Int.x = Int.(x+1);
  inc(r0) >< Int(int x) =>
      r0~Int(x+1);
  >>> add (Int.x), y = add2.x y;
  add(r0, y) >< Int(int x) =>
      add2(r0, x)~y;
  >>> add2.x Int.y = Int.(x+y);
  add2(r0, int x) >< Int(int y) =>
      r0~Int(x+y);
  ```
  ```
  >>> foo Int.x = if x==1 then Int.x+1 else if x==2 then Int.x+10 else Int.x+100;
  foo(r0) >< Int(int x) =>
      if x==1 then r0~Int(x+1) else if x==2 then r0~Int(x+10) else r0~Int(x+100);
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

- Built-in constants such as Cons, Nil are not supported.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
