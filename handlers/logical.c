#include "logical.h"
#include <string.h>

extern char *tempResult(void);

static int isNumericLike(valType type)
{
    return type == typeInt || type == typeFloat || type == typeChar;
}

static int toBoolValue(const valNode *node)
{
    if (node->type == typeInt)
    {
        return node->value.iValue != 0;
    }
    if (node->type == typeFloat)
    {
        return node->value.fValue != 0.0f;
    }
    return ((int)node->value.cValue) != 0;
}

exprResult logicalNotOperation(valNode *operand)
{
    exprResult res;
    res.error = false;

    if (!isNumericLike(operand->type))
    {
        res.error = true;
        ERRORF("Unary 'NOT' operator requires numeric operand.");
        res.place = NULL;
        return res;
    }

    res.value.type = typeBool;
    res.value.value.bValue = !toBoolValue(operand);
    res.place = strdup(tempResult());
    return res;
}

exprResult logicalBinaryOperation(valNode *left, valNode *right, const char *op)
{
    exprResult res;
    res.error = false;

    if (!isNumericLike(left->type))
    {
        res.error = true;
        ERRORF("Left operand of '%s' must be numeric.", op);
        res.place = NULL;
        return res;
    }

    if (!isNumericLike(right->type))
    {
        res.error = true;
        ERRORF("Right operand of '%s' must be numeric.", op);
        res.place = NULL;
        return res;
    }

    res.value.type = typeBool;

    if (strcmp(op, "AND") == 0)
    {
        res.value.value.bValue = toBoolValue(left) && toBoolValue(right);
    }
    else if (strcmp(op, "OR") == 0)
    {
        res.value.value.bValue = toBoolValue(left) || toBoolValue(right);
    }
    else
    {
        res.error = true;
        ERRORF("Unknown logical operator '%s'.", op);
        res.place = NULL;
        return res;
    }

    res.place = strdup(tempResult());
    return res;
}
