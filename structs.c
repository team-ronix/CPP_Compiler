#include "structs.h"
#include <stdlib.h>
#include <string.h>

varNode *findVariable(symbolTable *table, const char *id)
{
    while (table != NULL)
    {
        varNode *current = table->variables;
        while (current != NULL)
        {
            if (strcmp(current->variable.id, id) == 0)
            {
                return current;
            }
            current = current->next;
        }
        table = table->parent;
    }
    return NULL;
}

varNode *addVariable(symbolTable *table, const char *id, const char *type)
{
    varNode *newVar = (varNode *)malloc(sizeof(varNode));
    newVar->variable.id = strdup(id);
    newVar->variable.type = strdup(type);
    newVar->next = table->variables;
    if (table->variables == NULL)
    {
        table->variables = newVar;
    }
    else
    {
        varNode *current = table->variables;
        while (current->next != NULL)
        {
            current = current->next;
        }
        current->next = newVar;
    }
    return newVar;
}

bool isVariableDeclared(symbolTable *table, const char *id)
{
    return findVariable(table, id) != NULL;
}

bool removeVariable(symbolTable *table, const char *id)
{
    varNode *current = table->variables;
    varNode *prev = NULL;
    while (current != NULL)
    {
        if (strcmp(current->variable.id, id) == 0)
        {
            if (prev == NULL)
            {
                table->variables = current->next;
            }
            else
            {
                prev->next = current->next;
            }
            free(current->variable.id);
            free(current->variable.type);
            free(current);
            return true;
        }
        prev = current;
        current = current->next;
    }
    return false;
}

bool editValue(symbolTable *table, const char *id, const valNode *newValue)
{
    varNode *varNode = findVariable(table, id);
    if (varNode == NULL)
    {
        return false;
    }
    if (varNode->variable.type != newValue->valType)
    {
        return false;
    }
    switch (newValue->valType)
    {
    case typeInt:
        varNode->variable.value.iValue = newValue->value.iValue;
        break;
    case typeFloat:
        varNode->variable.value.fValue = newValue->value.fValue;
        break;
    case typeBool:
        varNode->variable.value.bValue = newValue->value.bValue;
        break;
    case typeChar:
        varNode->variable.value.cValue = newValue->value.cValue;
        break;
    case typeString:
        free(varNode->variable.value.sValue);
        varNode->variable.value.sValue = strdup(newValue->value.sValue);
        break;
    default:
        return false;
    }
    return true;
}