# Change log
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

