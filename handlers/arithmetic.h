#ifndef ARITHMETIC_H
#define ARITHMETIC_H

#include "../structs.h"

exprResult arithmeticOperations(valNode *left, valNode *right, const char *op);

/* Handle post-increment / post-decrement for a named variable.
   op must be "INC" or "DEC".
   Validates that the variable exists and is not const, emits the quad,
   and updates the value in the symbol table. */
void handleIncDec(symbolTable *scope, const char *id, const char *op);

#endif
