# Train

Translator of a functional language to interaction nets. 

- The current version is 0.1.5, released on **4 Dec 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



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

* To quit this system, use `:q` or  `:quit` command:

  ```
  >>> :q
  ```



## Syntax

The expression `e` is defined as follows:

```
e ::= x 
    | C e1,...,en 
    | f e1,...,em
    | let x1,...,xj = f e1,...,em in e1',...,ek'
    | (e1)
    
    where 
     - x,x1, ..., xj are distinct variables,
     - C is a constructor with n-arguments,
     - f is a function with m-arguments,
     - e1,...,ei and e1',...,ei' are expressions.
```

This is a constructor system where, in function applications, pattern matching takes place only on the first argument. A *(m+1)*-arguments function `f` with *n*-arguments constructor `C` is defined as follows:

```
f (C x1,...,xn), y1,...,ym = e1,...,ek;

    where
    - x1,...,xn, y1,...,ym are distinct variables,
    - e1,...,ek are expressions,
    - each variable x1,...,xn, y1,...,ym 
      must occur once in e1,...ek.    
```

- **Constructors and functions:** Strings starting with a capital letter, such as `S`, `Z`, `Cons`, `Nil` are recognised as **constructors**. For **functions**, use strings that start with a lower case letter, such as `foo`, `inc`,  `add`, `dup`.

The following is an example of addition on unary numbers:

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



- **Example**: Duplication of unary numbers:
  
  ```
  >>> dup Z = Z,Z;
  dup(r0, r1) >< Z =>
      r0~Z, r1~Z;
  >>> dup (S x) = let w1,w2 = dup x in (S w1), (S w2);
  dup(r0, r1) >< S(x) =>
      r0~S(w1), r1~S(w2), dup(w1, w2)~x;
  >>>
  ```

#### Extentions:
- **With inpla notation**: We can contain inpla notation by using braces `{` and `}`:
  
  ```
  >>> dup Z = a,b { Dup(a,b)~Z };
  dup(r0, r1) >< Z =>
      r0~a, r1~b,
       Dup(a,b)~Z ;
  >>>
  ```

- **Attributes**: We can attach attributes (integer numbers) to functions and constructors by using dot `.`. In the right hand side, we can also attach arithmetic expressions on attributes:
  
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
  
- **Conditional branches**: `if-then-else` is available on the attributes:
  
  ```
  >>> foo Int.x = if x==1 then Int.x+1 else if x==2 then Int.x+10 else Int.x+100;
  foo(r0) >< Int(int x) =>
      if x==1 then r0~Int(x+1) else if x==2 then r0~Int(x+10) else r0~Int(x+100);
  >>>
  ```



### Sample programs

- Fibonacci number on unary numbers:

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

- GCD on attributes

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
