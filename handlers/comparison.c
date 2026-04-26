#include "comparison.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char *tempResult(void);

exprResult comparisonOperations(valNode *left, valNode *right, const char *op)
{
    valNode resultNode;
    exprResult res;
    res.error = false;

    if (left->type != typeInt && left->type != typeFloat && left->type != typeChar)
    {
        res.error = true;
        ERRORF("Unsupported type %d for left operand in '%s'.", left->type, op);
        res.place = NULL;
        return res;
    }
    if (right->type != typeInt && right->type != typeFloat && right->type != typeChar)
    {
        res.error = true;
        ERRORF("Unsupported type %d for right operand in '%s'.", right->type, op);
        res.place = NULL;
        return res;
    }

    double lDouble = (left->type == typeFloat) ? left->value.fValue : (left->type == typeChar) ? (double)(int)left->value.cValue
                                                                                               : (double)left->value.iValue;

    double rDouble = (right->type == typeFloat) ? right->value.fValue : (right->type == typeChar) ? (double)(int)right->value.cValue
                                                                                                  : (double)right->value.iValue;

    resultNode.type = typeBool;

    if (strcmp(op, "==") == 0)
        resultNode.value.iValue = (lDouble == rDouble);
    else if (strcmp(op, "!=") == 0)
        resultNode.value.iValue = (lDouble != rDouble);
    else if (strcmp(op, "<") == 0)
        resultNode.value.iValue = (lDouble < rDouble);
    else if (strcmp(op, ">") == 0)
        resultNode.value.iValue = (lDouble > rDouble);
    else if (strcmp(op, "<=") == 0)
        resultNode.value.iValue = (lDouble <= rDouble);
    else if (strcmp(op, ">=") == 0)
        resultNode.value.iValue = (lDouble >= rDouble);
    else
    {
        res.error = true;
        fprintf(stderr, "Error: Unknown comparison operator '%s'.\n", op);
        res.place = NULL;
        return res;
    }

    res.value = resultNode;
    res.place = strdup(tempResult());
    return res;
}
