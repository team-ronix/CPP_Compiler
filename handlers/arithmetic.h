#ifndef ARITHMETIC_H
#define ARITHMETIC_H

#include "../structs.h"
#include "utils.h"

exprResult arithmeticOperations(valNode *left, valNode *right, const char *op);

void handleCompoundAssign(symbolTable *scope, const char *id, const char *rightPlace, const valNode *right, const char *op, const char *quadOp);

void handleIncDec(symbolTable *scope, const char *id, const char *op);

#endif
