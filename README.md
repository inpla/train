# Train

Translator of the new language of interaction nets. 

- The current version is 0.0.3, released on **15 Oct 2023**. (See [Changelog.md](https://github.com/sintan310/train/blob/main/Changelog.md) for details.)



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
  inc(rr_0)><Z() => rr_0~S(Z());
  >>> inc Z = (S Z);
  inc(rr_0)><Z() => rr_0~S(Z());
  >>> inc (S x) = let w = inc x in (S w);
  inc(rr_0)><S(x) => rr_0~S(w), inc(w)~x;
  >>> inc (S x) =
  ...   let w = (inc x) in
  ...   (S w);
  inc(rr_0)><S(x) => rr_0~S(w), inc(w)~x;
  >>>
  ```
  

  ```
  >>> add Z x = x;
  add(rr_0,x)><Z() => rr_0~x;
  >>> add (S y) x = let w=add y x in (S w);
  add(rr_0,x)><S(y) => rr_0~S(w), add(w,x)~y;
  >>> add (S y) x = add y (S x);
  add(rr_0,x)><S(y) => add(rr_0,S(x))~y;
  >>>
  ```
  ```
  >>> dup Z = Z,Z;
  dup(rr_0,rr_1)><Z => rr_0~Z, rr_1~Z;
  >>> dup (S x) = let w1,w2 = dup x in (S w1), (S w2);
  dup(rr_0,rr_1)><S(x) => rr_0~S(w1), rr_1~S(w2), dup(w1,w2)~x;
  ```
* To quit this system, use `:q` or  `:quit` command:

  ```
  >>> :q
  ```



## Limitation

The current version has some limitations:

- Nested terms are not supported. This will be solved in the next version.
- Attributes are not supported.
- Expressions are not supported, just for rules for now. This will be solved in the later version.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
