# Change log

### v0.1.2 (released on 14 Nov 2023)
#### New features

- **Bundle arities**: When functions return *n*-bundles, the number *n* is recorded with the function symbol. The number is used when the function is applied. For example, the following `dup` returns a 2-bundle, and it is delt with a function that returns a 2-bundle: 

  ```
  >>> dup Z = Z,Z;
  dup(r0, r1) >< Z =>
      r0~Z, r1~Z;
  >>> main = dup Z;
  dup(r0, r1)~Z;
  r0, r1;
  ```



#### Polished

- **Fresh names**: Fresh names are required for the translation, but these had not been checked for the freshness. For this reason, some complicated suffixes had been prepared. These now are checked and the suffixes becomes simpler.

  




### v0.1.1 (released on 12 Nov 2023)
#### Polished

- **Separator between arguments**: The separator between arguments is changed from space into '`,`'  as the formal definition is updated so. From this version, `add x y` is written as `add x,y`.

  


### v0.1.0 (released on 11 Nov 2023)

#### New Features

- **Main expression**: The main expression is supported. For now it can be written in Haskel and OCaml styles. It could be changed in future how it can fit to this language design.

  ```
  -- Haskell style
  main = add (S Z) (S(S Z));
  ```

  ```
  -- OCaml style
  let () = add (S Z) (S(S Z));
  ```


#### Bux fixes
- **Parsing**: Some deeply nested terms  were not correctly parased. Now it is fixed.



### v0.0.7 (released on 18 Oct 2023)

#### New Features

- **If-then-else sentences**: If-then-else senteces have been supported, where the conditional expression are expressions on attributes. Nested ones are also allowed:

  ```
  >>> foo Int.x = if x==1 then Int.x+1 else if x==2 then Int.x+10 else Int.x+100;
  foo(rr_0) >< Int(int x) =>
      if x==1 then rr_0~Int(x+1) else if x==2 then rr_0~Int(x+10) else rr_0~Int(x+100);
  >>>
  ```



### v0.0.6 (released on 18 Oct 2023)

#### New Features

- **Nested terms**: Nested terms have been supported. So, we can write some definitions simply:

  ```
  >>> add (S x) y = S (add x y);
  add(rr_0, y) >< S(x) =>
    add(ww_1, y)~x, rr_0~S(ww_1);
  >>>
  ```
  It was expressed with `let`:
  ```
  >>> add (S x) y = let w = add x y in S (w);
  add(rr_0, y) >< S(x) =>
    rr_0~S(w), add(w, y)~x;
  >>>
  ```



### v0.0.5-1 (released on 17 Oct 2023)

#### Bug fixes

- **Applications with attributes**: delt with the attributes as application parameters. Now, it is fixed.

  ```
  >>> add Int.x y = add2.x y;
  add(rr_0, y) >< Int(int x) =>
      add2(rr_0, x)~y;
  >>>
  ```



### v0.0.5 (released on 16 Oct 2023)

#### New Features

- **Non-functional part**: The non-functional part is supported. Use braces `{` `}` for that:

  ```
  >>> dup Z = a,b { Dup(a,b)~Z };
  dup(rr_0, rr_1) >< Z =>
      rr_0~a, rr_1~b,
       Dup(a,b)~Z ;
  >>>
  ```

  



### v0.0.4 (released on 16 Oct 2023)

#### New Features

- **Introduce of attributes**: Attributes have been introduced now. Expressions on attributes are also supported.




### v0.0.3 (released on 15 Oct 2023)

#### Polished

- **Syntax Definition**: It has been neatly modified to support further extensions.



### v0.0.2 (released on 12 Oct 2023)

#### New Features

- **Bundles**: are specified as return values. For example, we can define `dup` for `Z` and `S` as follows:

  ```
  >>> dup Z = Z,Z;
  dup(rr_0,rr_1)><Z => rr_0~Z, rr_1~Z;
  >>> dup (S x) = let w1,w2 = dup x in (S w1), (S w2);
  dup(rr_0,rr_1)><S(x) => rr_0~S(w1), rr_1~S(w2), dup(w1,w2)~x;
  ```




### v0.0.1 (released on 11 Oct 2023)

#### Polished
- **The suffix of fresh names**: The suffix is defined in `src/config.h`, so change it to suit your needs:

  ```
  // The suffix of fresh names
  #define SUFFIX_FRESH_NAMES "rr_"
  ```

  


### v0.0.0 (released on 10 Oct 2023)
#### New release
- This translates rules written in functional programming style language into descriptions of Inpla.

- Now it has some limitations:
  -	 Nested terms are not supported. This will be solved in the next version.
  -	 Attributes are not supported.
  -	 Expressions are not supported, just for rules for now. This will be solved in the later version

- A bug has been reported:

  - Strings started from `_` are not accepted in Inpla, though the `_` is used to make fresh names in Train. This could be solved in the next version soon.

