#!/bin/bash

yacc -d yacc.y -Wcounterexamples || { echo "Yacc failed"; exit 1; }

lex lex.l || { echo "Lex failed"; exit 1; }

cc lex.yy.c y.tab.c structs.c handlers/arithmetic.c handlers/comparison.c handlers/utils.c -o bas.exe || { echo "Compilation failed"; exit 1; }

echo "Build successful: ./bas.exe"