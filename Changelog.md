# Change log
### v0.0.5-1 (released on 16 Oct 2023)

#### Bugfixes

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

