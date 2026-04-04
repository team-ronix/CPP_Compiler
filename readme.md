# Compilers Project

A lexical analyzer and parser implementation using Lex and Yacc.

## Building

Make the build script executable and run it:

```bash
chmod +x build.sh
./build.sh
```

This will:

1. Generate `y.tab.c` and `y.tab.h` from `yacc.y`
2. Generate `lex.yy.c` from `lex.l`
3. Compile all sources to create `bas.exe`

## Running

Execute the compiler with test input:

```bash
./bas.exe < test.txt
```

## Generated Files

- **y.tab.c** - Parser source (generated)
- **y.tab.h** - Parser header (generated)
- **lex.yy.c** - Lexer source (generated)
- **bas.exe** - Compiled executable (generated)
