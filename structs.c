#include "structs.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
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

void assignValue(varNode *varNode, valNode value, valType type)
{
    switch (type)
    {
    case typeInt:
        varNode->variable.value.iValue = value.value.iValue;
        break;
    case typeFloat:
        varNode->variable.value.fValue = value.value.fValue;
        break;
    case typeBool:
        varNode->variable.value.bValue = value.value.bValue;
        break;
    case typeChar:
        varNode->variable.value.cValue = value.value.cValue;
        break;
    case typeString:
        if (value.value.sValue != NULL)
            varNode->variable.value.sValue = strdup(value.value.sValue);
        else
            varNode->variable.value.sValue = NULL;
        break;
    }
}

varNode *addVariable(symbolTable *table, const char *id, valType type)
{
    if (isInCurrentScope(table, id))
    {
        return NULL;
    }

    varNode *newVar = (varNode *)malloc(sizeof(varNode));
    newVar->variable.id = strdup(id);
    newVar->variable.type = type;
    newVar->next = NULL;
    newVar->variable.isConst = false;
    newVar->variable.isInitialized = false;
    newVar->variable.isUsed = false;

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
    newVar->scope = table;
    return newVar;
}

varNode *addVariableWithValue(symbolTable *table, const char *id, valType type, bool isConst, valNode value)
{
    varNode *newVar = addVariable(table, id, type);
    if (newVar == NULL)
    {
        return NULL;
    }
    newVar->variable.isConst = isConst;
    newVar->variable.isInitialized = true;
    assignValue(newVar, value, type);
    newVar->variable.isInitialized = true;
    newVar->variable.isUsed = false;
    newVar->scope = table;
    return newVar;
}

bool isInCurrentScope(symbolTable *table, const char *id)
{
    varNode *current = table->variables;
    while (current != NULL)
    {
        if (strcmp(current->variable.id, id) == 0)
        {
            return true;
        }
        current = current->next;
    }
    return false;
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
    if (varNode->variable.isConst)
    {
        return false;
    }
    if (varNode->variable.type != newValue->type)
    {
        return false;
    }
    assignValue(varNode, *newValue, varNode->variable.type);
    varNode->variable.isInitialized = true;
    return true;
}

void printSymbolTable(symbolTable *table)
{
    if (table == NULL)
    {
        printf("Symbol table is NULL.\n");
        return;
    }
    printf("Symbol Table:\n");
    varNode *current = table->variables;
    while (current != NULL)
    {
        printf("Variable ID: %s, Type: %d, Is Const: %d, Is Initialized: %d, Is Used: %d\n",
               current->variable.id,
               current->variable.type,
               current->variable.isConst,
               current->variable.isInitialized,
               current->variable.isUsed);
        current = current->next;
    }
}

valNode varToValNode(varNode *variable)
{
    valNode node;
    node.type = variable->variable.type;
    switch (variable->variable.type)
    {
    case typeInt:
        node.value.iValue = variable->variable.value.iValue;
        break;
    case typeFloat:
        node.value.fValue = variable->variable.value.fValue;
        break;
    case typeBool:
        node.value.bValue = variable->variable.value.bValue;
        break;
    case typeChar:
        node.value.cValue = variable->variable.value.cValue;
        break;
    case typeString:
        if (variable->variable.value.sValue != NULL)
            node.value.sValue = strdup(variable->variable.value.sValue);
        else
            node.value.sValue = NULL;
        break;
    default:
        break;
    }
    return node;
}