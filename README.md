# Train

Translator of the new language of interaction nets.



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
  inc(_r0)><Z() => _r0~S(Z());
  >>> inc Z = (S Z);
  inc(_r0)><Z() => _r0~S(Z());
  >>> inc (S x) = let w = inc x in (S w);
  inc(_r0)><S(x) => _r0~S(w), inc(w)~x;
  >>> 		
  ```
  ```
  >>> add Z x = x;
  add(_r0,x)><Z() => _r0~x;
  >>> add (S y) x = let w=add y x in (S w);
  add(_r0,x)><S(y) => _r0~S(w), add(w,x)~y;
  >>> add (S y) x = add y (S x);
  add(_r0,x)><S(y) => add(_r0,S(x))~y;
  >>>
  ```

* To quit this system, use `:quit` command:

  ```
  >>> :quit
  ```



## Limitation

The current version has some limitations:

- Nested terms are not supported. This will be solved in the next version.
- Any attributes are not supported.
- Expressions are not supported, just for rules for now. This will be solved in the later version.



## License

Copyright (c) 2023 [Shinya Sato](http://satolab.com/) 
