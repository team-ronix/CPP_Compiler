#ifndef LOGICAL_H
#define LOGICAL_H

#include "../structs.h"
#include "utils.h"

exprResult logicalNotOperation(valNode *operand);
exprResult logicalBinaryOperation(valNode *left, valNode *right, const char *op);

#endif
