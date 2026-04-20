#include "arithmetic.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char *tempResult(void);
extern void emit(const char *op, const char *arg1, const char *arg2, const char *result);

exprResult arithmeticOperations(valNode *left, valNode *right, const char *op)
{
    valNode resultNode;
    exprResult res;
    res.error = false;

    if (left->type != typeInt && left->type != typeFloat && left->type != typeChar)
    {
        res.error = true;
        fprintf(stderr, "Error: Unsupported type %d for left operand in '%s'.\n", left->type, op);
        res.place = NULL;
        return res;
    }
    if (right->type != typeInt && right->type != typeFloat && right->type != typeChar)
    {
        res.error = true;
        fprintf(stderr, "Error: Unsupported type %d for right operand in '%s'.\n", right->type, op);
        res.place = NULL;
        return res;
    }

    bool leftIsFloat = (left->type == typeFloat);
    bool rightIsFloat = (right->type == typeFloat);

    float lFloat = leftIsFloat ? left->value.fValue : left->type == typeChar ? (float)(int)left->value.cValue
                                                                             : (float)left->value.iValue;

    float rFloat = rightIsFloat ? right->value.fValue : right->type == typeChar ? (float)(int)right->value.cValue
                                                                                : (float)right->value.iValue;

    int lInt = leftIsFloat ? (int)left->value.fValue : left->type == typeChar ? (int)left->value.cValue
                                                                              : left->value.iValue;

    int rInt = rightIsFloat ? (int)right->value.fValue : right->type == typeChar ? (int)right->value.cValue
                                                                                 : right->value.iValue;

    if (strcmp(op, "/") == 0)
    {
        if ((leftIsFloat || rightIsFloat) ? (rFloat == 0.0f) : (rInt == 0))
        {
            res.error = true;
            fprintf(stderr, "Error: Division by zero.\n");
            res.place = NULL;
            return res;
        }
    }

    bool eitherFloat = leftIsFloat || rightIsFloat;

    if (eitherFloat)
    {
        resultNode.type = typeFloat;
        if (strcmp(op, "+") == 0)
            resultNode.value.fValue = lFloat + rFloat;
        else if (strcmp(op, "-") == 0)
            resultNode.value.fValue = lFloat - rFloat;
        else if (strcmp(op, "*") == 0)
            resultNode.value.fValue = lFloat * rFloat;
        else if (strcmp(op, "/") == 0)
            resultNode.value.fValue = lFloat / rFloat;
        else
        {
            res.error = true;
            fprintf(stderr, "Error: Unknown operator '%s'.\n", op);
            res.place = NULL;
            return res;
        }
    }
    else
    {
        resultNode.type = typeInt;
        if (strcmp(op, "+") == 0)
            resultNode.value.iValue = lInt + rInt;
        else if (strcmp(op, "-") == 0)
            resultNode.value.iValue = lInt - rInt;
        else if (strcmp(op, "*") == 0)
            resultNode.value.iValue = lInt * rInt;
        else if (strcmp(op, "/") == 0)
            resultNode.value.iValue = lInt / rInt;
        else
        {
            res.error = true;
            fprintf(stderr, "Error: Unknown operator '%s'.\n", op);
            res.place = NULL;
            return res;
        }
    }

    res.value = resultNode;
    res.place = strdup(tempResult());
    return res;
}

void handleIncDec(symbolTable *scope, const char *id, const char *op)
{
    varNode *var = findVariable(scope, id);
    if (!var)
    {
        // fprintf(stderr, "Error: Variable '%s' not declared.\n", id);
        ERRORF("Variable '%s' not declared.", id);
        return;
    }
    if (var->variable.isConst)
    {
        // fprintf(stderr, "Error: Cannot %s constant variable '%s'.\n",
        //         strcmp(op, "INC") == 0 ? "increment" : "decrement", id);
        ERRORF("Cannot %s constant variable '%s'.", strcmp(op, "INC") == 0 ? "increment" : "decrement", id);
        return;
    }
    valNode one;
    one.type = typeInt;
    one.value.iValue = 1;
    emit(op, NULL, NULL, var->variable.id);
    if (!editValue(scope, id, &one))
    {
        fprintf(stderr, "Error: Failed to %s variable '%s'.\n",
                strcmp(op, "INC") == 0 ? "increment" : "decrement", id);
    }
}
