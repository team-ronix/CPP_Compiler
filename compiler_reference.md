# Project Overview

This project is a small compiler front end for a C/C++-like language built with Lex and Yacc. It performs lexical analysis, parsing, semantic checks such as declaration/type validation, scope tracking, and emits intermediate representation as quadruples.

The compiler currently supports:
- Primitive types: int, float, bool, char, string, void
- Variable and const declarations
- Arithmetic, comparison, and logical expressions
- If / else
- While, do-while, and for loops
- Switch / case / default
- Function declarations, parameters, returns, and calls
- Quadruple generation to an output file
- Diagnostics written to an errors file

Known current limitations include unsupported arrays, pointers, and compound assignment operators such as `+=` and `/=`.

# Tools and Technologies Used

- C: core implementation language
- Lex/Flex: lexical analysis in [lex.l](lex.l)
- Yacc/Bison: parser generation in [yacc.y](yacc.y)
- Bash: build and test scripts such as [build.sh](build.sh)
- Cygwin Bash: intended runtime/build shell environment
- `cc`: C compilation step used by the build script

# Assignment Validity Check

Assignments are currently restricted by grammar shape rather than by a separate lvalue validation pass.

Implemented behavior:
- Valid assignment forms are only parsed when the left-hand side is an `IDENTIFIER`
- Increment and decrement also only accept an `IDENTIFIER`

Current consequence:
- Cases like `x = 5;` are accepted
- Cases like `(a + b) = 5;` or `7 = x;` are not parsed as valid assignments and should fail with a syntax/parsing error
- There is not currently a dedicated semantic error with the exact wording: "The left-hand side of an assignment must be valid"

# Tokens

## Literal and Identifier Tokens

| Token | Description |
| --- | --- |
| `INTEGER` | Integer literal such as `42` |
| `FLOATING` | Floating-point literal such as `3.14` |
| `CHARACTER` | Character literal such as `'a'` or escaped char literals |
| `STRING_LITERAL` | String literal such as `"hello"` |
| `IDENTIFIER` | User-defined name for variables and functions |
| `BOOLEAN` | Boolean literal `true` or `false` |

## Type Keywords

| Token | Description |
| --- | --- |
| `INT` | `int` type keyword |
| `FLOAT` | `float` type keyword |
| `BOOL` | `bool` type keyword |
| `CHAR` | `char` type keyword |
| `STRING` | `string` type keyword |
| `VOID` | `void` type keyword |
| `CONST` | Constant declaration modifier |

## Control Flow Keywords

| Token | Description |
| --- | --- |
| `IF` | Starts an if statement |
| `ELSE` | Else branch for an if statement |
| `WHILE` | Starts a while loop |
| `FOR` | Starts a for loop |
| `DO` | Starts a do-while loop |
| `SWITCH` | Starts a switch statement |
| `CASE` | A case branch inside switch |
| `DEFAULT` | Default branch inside switch |
| `BREAK` | Breaks out of a loop or switch |
| `CONTINUE` | Continues to next loop iteration |
| `RETURN` | Returns a value from a function |
| `PRINT` | Print statement keyword |

## Logical and Comparison Tokens

| Token | Description |
| --- | --- |
| `OR` | Logical OR operator `||` |
| `AND` | Logical AND operator `&&` |
| `NOT` | Logical NOT operator `!` |
| `GE` | Greater than or equal operator `>=` |
| `LE` | Less than or equal operator `<=` |
| `EQ` | Equality operator `==` |
| `NE` | Not-equal operator `!=` |
| `INC` | Increment operator `++` |
| `DEC` | Decrement operator `--` |

## Single-Character Tokens

These are returned directly as character tokens by the lexer.

| Token | Description |
| --- | --- |
| `+` | Addition operator |
| `-` | Subtraction or unary minus |
| `*` | Multiplication operator |
| `/` | Division operator |
| `%` | Modulo symbol token |
| `=` | Assignment operator |
| `<` | Less-than operator |
| `>` | Greater-than operator |
| `(` `)` | Parentheses |
| `{` `}` | Braces / block delimiters |
| `:` | Used in switch-case labels |
| `;` | Statement terminator |
| `,` | Separator for arguments and declarations |
| `.` | Dot token |

# Quadruples

The compiler emits quadruples in the form:

`(OP, ARG1, ARG2, RESULT)`

## Declaration and Assignment

| Quadruple | Description |
| --- | --- |
| `(DECL, value, -, var)` | Declare a variable, optionally with an initial value |
| `(CONST, value, -, var)` | Declare and initialize a constant |
| `(ASSIGN, src, -, dest)` | Assign `src` to `dest` |
| `(PARAM, defaultValue, -, param)` | Register a function parameter |
| `(ARG, value, -, -)` | Push an argument for a function call |

## Function Control

| Quadruple | Description |
| --- | --- |
| `(FUNC_START, -, -, f)` | Start function `f` |
| `(FUNC_END, -, -, f)` | End function `f` |
| `(CALL, f, -, t)` | Call function `f`; store result in `t` if non-void |
| `(RETURN, value, -, -)` | Return a value from the current function |

## Arithmetic

| Quadruple | Description |
| --- | --- |
| `(ADD, v1, v2, t)` | `t = v1 + v2` |
| `(SUB, v1, v2, t)` | `t = v1 - v2` |
| `(MUL, v1, v2, t)` | `t = v1 * v2` |
| `(DIV, v1, v2, t)` | `t = v1 / v2` |
| `(INC, -, -, v)` | Increment variable `v` |
| `(DEC, -, -, v)` | Decrement variable `v` |

## Comparison and Logic

| Quadruple | Description |
| --- | --- |
| `(LT, v1, v2, t)` | `t = (v1 < v2)` |
| `(GT, v1, v2, t)` | `t = (v1 > v2)` |
| `(GE, v1, v2, t)` | `t = (v1 >= v2)` |
| `(LE, v1, v2, t)` | `t = (v1 <= v2)` |
| `(EQ, v1, v2, t)` | `t = (v1 == v2)` |
| `(NE, v1, v2, t)` | `t = (v1 != v2)` |
| `(AND, v1, v2, t)` | `t = (v1 && v2)` |
| `(OR, v1, v2, t)` | `t = (v1 || v2)` |
| `(NOT, v, -, t)` | `t = !v` |

## Branching and Labels

| Quadruple | Description |
| --- | --- |
| `(LABEL, -, -, L)` | Define label `L` |
| `(JMP, -, -, L)` | Unconditional jump to label `L` |
| `(IF_FALSE, cond, -, L)` | Jump to `L` if `cond` evaluates to false |
| `(JMP_BREAK, -, -, L)` | Jump to loop or switch end label |
| `(JMP_CONTINUE, -, -, L)` | Jump to loop continue label |

## Other Operations

| Quadruple | Description |
| --- | --- |
| `(PRINT, value, -, -)` | Print a value |

# Notes

- Variable names stored in quadruples may be scope-mangled internally, for example with a scope suffix.
- Temporary results are generated with names like `t_0`, `t_1`, and so on.
- Labels are generated internally for branches, loops, and switch handling.
