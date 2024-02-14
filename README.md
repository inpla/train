# Train

Translator of a functional language to interaction nets. 

- The current version is 0.2.1 (dev), released on **14 Feb 2024**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



## Getting Started

* Requirement 
  - gcc (>= 4.0), flex, bison

* Build 
  
  Use `make` command as follows (the symbol `$` means a shell prompt):
  
  ```
  $ make
  ```



## How to Execute
### Interactive mode

* Train starts in the interactive mode by typing the following command (where the symbol `$` is a shell prompt):
	
	```
	$ ./train
	>>> 
	```


* The symbol `>>>` is a prompt from Train. After the prompt you can write rules of the new language. We need the delimiter `;` at the end of a rule.

  ```
  >>> inc(Z) = S(Z);
  inc(r0) >< Z =>
      r0~S(Z);
  >>> inc(Z) = S(Z);
  inc(r0) >< Z =>
      r0~S(Z);
  >>> inc(S(x)) = S(inc x);
  inc(r0) >< S(x) =>
      inc(w0)~x, r0~S(w0);
  >>>
  ```

* To quit this system, use `:q` or  `:quit` command:

  ```
  >>> :q
  ```



#### Batch mode

- Train also has the batch mode in which a file is evaluated. This is available when invoked with an execution option `-f`  *filename*. There are some sample files in the `sample` folder. Here is one of these:

##### Fibonacci number

- Sample file: `sample/standard/fibonacci.txt`

  ```
  -- definitions
  fib Z = Z;
  fib S(x) = fibS x;
  fibS Z = S(Z);
  fibS S(x) = add(fib x1, fibS x2) { Dup(x1,x2)~x };
  add (Z,x) = x;
  add (S(y),x) = S(add(x,y));
  
  -- main
  main = fib S(S(S(S(S(S(Z))))));
  ```

  - Execution:

    ```
    $ ./train -f sample/standard/fibonacci.txt
    fib(r0) >< Z =>
        r0~Z;
    fib(r0) >< S(x) =>
        fibS(r0)~x;
    fibS(r0) >< Z =>
        r0~S(Z);
    fibS(r0) >< S(x) =>
        fibS(w0)~x2, fib(w1)~x1, add(r0, w0)~w1,
         Dup(x1,x2)~x ;
    add(r0, x) >< Z =>
        r0~x;
    add(r0, x) >< S(y) =>
        add(w0, y)~x, r0~S(w0);
    fib(main)~S(S(S(S(S(S(Z))))));
    main;
    $
    ```

    If you have [Inpla](https://github.com/inpla/inpla/), which is an interaction nets evaluator, this result is executed as follows:

    ```
    $ ./train -f sample/standard/fibonacci.txt | <path_to_inpla>/inpla
    Inpla 0.11.0 : Interaction nets as a programming language [built: 13 May 2023]
    (91 interactions, 0.00 sec)
    S(S(S(S(S(S(S(S(Z))))))))
    ```




## Syntax

- **Expressions**: An expression `e` is defined by the following syntax where `elist` is a list of expressions and `xlist` is a list of variables:

  ```
  <expression> ::= x 
                 | C <elist>
                 | f <elist>
                 | let <xlist> = <elist> in <elist>
                 | (e)
  
  <elist> ::= e
            | (e1,...,en)
  <xlist> ::= x
            | (x1,...,xm)
  
      where 
       - x, x1,...,xm are distinct variables,
       - e, e1,...,en are expressions.
       - C is a constructor symbol,
       - f is a function symbol.
  ```

- **Function definitions**: This is a constructor system where, in function applications, pattern matching only takes place on the first argument. The matching depth is one. The definition of a function `f` of *(n+1)*-arguments for a constructor C is written according to the following `funcdef` syntax:

  ```
  <funcdef> ::= f (C xlist, y1,...,yn) = elist;
  
      where
      - y1,...,yn are distinct variables,
      - xlist is a list of variables,
      - elist is a list of expressions,
      - C is a constructor symbol,
      - each variable in xlist and y1,...,yn
        must occur once in elist.
  ```

- **Symbols of constructors and functions:**
  - Strings beginning with a capital letter, such as `S`, `Z`, `Cons`, `Nil` are recognised as **constructors**. 
  - For **functions**, use strings that begin with a lowercase letter, such as `foo`, `inc`,  `add`, `dup`.


- **Main program**: The main program is written in the following way:

  ```
  main = elist;
  
      where elist is a list of expressions.
  ```


The following is an example of addition on unary numbers. The given function definitions are translated into interaction nets descriptions, where these follow [Inpla](https://github.com/inpla/inpla/) syntax:

  ```
  >>> add(Z,x) = x;
  add(r0, x) >< Z =>
      r0~x;
  >>> add(S(x),y) = S(add(x,y));
  add(r0, y) >< S(x) =>
      add(w0, y)~x, r0~S(w0);
  >>> add(S(x),y) = add(x,S(y));
  add(r0, y) >< S(x) =>
      add(r0, S(y))~x;
  >>> main = add(S(S(Z)), S(S(S(Z))));
  add(main, S(S(S(Z))))~S(S(Z));
  main;
  >>>
  ```


  For example, the following is a program of the addition (where `--` is a comment)

  ```
  -- rules
  add(Z,x) = x;
  add(S(x),y) = S(add(x,y));
  
  -- main
  main = add(S(S(S(Z))), S(Z));
  ```


#### Extensions:
- **With inpla notation** (duplication of unary numbers): We can include [Inpla](https://github.com/inpla/inpla/) notation by using braces `{` and `}`:
  
  ```
  >>> dup Z = (a,b) { Dup(a,b)~Z };
  dup(r0, r1) >< Z =>
      r0~a, r1~b,
       Dup(a,b)~Z ;
  >>>
  ```
  Of course, this example can be written without the extension:  
  ```
  >>> dup Z = (Z,Z);
  dup(r0, r1) >< Z =>
      r0~Z, r1~Z;
  >>> dup S(x) = let (w1,w2) = dup x in (S(w1), S(w2));
  dup(r0, r1) >< S(x) =>
      r0~S(w1), r1~S(w2), dup(w1, w2)~x;
  >>>
  ```

- **Attributes**: We can attach attributes (integers) to functions and constructors by using dot `.`. On the right hand side, we can also attach arithmetic expressions on attributes:
  
  ```
  >>> inc Int.x = Int.(x+1);
  inc(r0) >< Int(int x) =>
      r0~Int(x+1);
  >>> add (Int.x, y) = add2.x y;
  add(r0, y) >< Int(int x) =>
      add2(r0, x)~y;
  >>> add2.x Int.y = Int.(x+y);
  add2(r0, int x) >< Int(int y) =>
      r0~Int(x+y);
  ```
  
- **Conditional branches**: `if-then-else` is available on the attributes when defining functions:
  
  ```
  <funcdef> ::= f (C xlist, y1,...,yn) = elist;
              | <if-then-else>;
  <if-then-else> ::= if <expression on attributes> then <elist> else <elist>;
  ```
  
  The following is an example:
  
  ```
  >>> foo Int.x = if x==1 then Int.x+1 else if x==2 then Int.x+10 else Int.x+100;
  foo(r0) >< Int(int x) =>
      if x==1 then r0~Int(x+1) else if x==2 then r0~Int(x+10) else r0~Int(x+100);
  >>>
  ```



### Sample programs

- Append lists:

  ```
  -- definitions
  append ([], ys) = ys;
  append (x:xs,ys) = x:(append (xs,ys));
  
  -- main
  main = append([A,B,C], [D,E,F]);
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
  
  

## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
