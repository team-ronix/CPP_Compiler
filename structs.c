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
    // switch (type)
    // {
    // case typeInt:
    //     varNode->variable.value.iValue = value.value.iValue;
    //     break;
    // case typeFloat:
    //     varNode->variable.value.fValue = value.value.fValue;
    //     break;
    // case typeBool:
    //     varNode->variable.value.bValue = value.value.bValue;
    //     break;
    // case typeChar:
    //     varNode->variable.value.cValue = value.value.cValue;
    //     break;
    // case typeString:
    //     if (value.value.sValue != NULL)
    //         varNode->variable.value.sValue = strdup(value.value.sValue);
    //     else
    //         varNode->variable.value.sValue = NULL;
    //     break;
    // }
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
    newVar->paramNext = NULL;
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
        if (varNode->variable.type == typeFloat && newValue->type == typeInt)
        {
            valNode convertedValue;
            convertedValue.type = typeFloat;
            convertedValue.value.fValue = (float)newValue->value.iValue;
            assignValue(varNode, convertedValue, typeFloat);
            varNode->variable.isInitialized = true;
            return true;
        }
        if (varNode->variable.type == typeInt && newValue->type == typeFloat)
        {
            valNode convertedValue;
            convertedValue.type = typeInt;
            convertedValue.value.iValue = (int)newValue->value.fValue;
            assignValue(varNode, convertedValue, typeInt);
            varNode->variable.isInitialized = true;
            return true;
        }
        if (varNode->variable.type == typeBool)
        {
            valNode convertedValue;
            convertedValue.type = typeBool;
            if (newValue->type == typeInt)
                convertedValue.value.bValue = (bool)newValue->value.iValue;
            else if (newValue->type == typeFloat)
                convertedValue.value.bValue = (bool)newValue->value.fValue;
            else if (newValue->type == typeChar)
                convertedValue.value.bValue = (bool)newValue->value.cValue;
            else if (newValue->type == typeString)
                convertedValue.value.bValue = (bool)newValue->value.sValue;

            assignValue(varNode, convertedValue, typeBool);
            varNode->variable.isInitialized = true;
            return true;
        }

        if (varNode->variable.type == typeInt && newValue->type == typeBool)
        {
            valNode convertedValue;
            convertedValue.type = typeInt;
            convertedValue.value.iValue = newValue->value.bValue ? 1 : 0;
            assignValue(varNode, convertedValue, typeInt);
            varNode->variable.isInitialized = true;
            return true;
        }

        return false;
    }
    assignValue(varNode, *newValue, varNode->variable.type);
    varNode->variable.isInitialized = true;
    varNode->variable.isUsed = true;
    return true;
}

void printSymbolTable(symbolTable *table, int level)
{
    if (table == NULL)
    {
        return;
    }
    printf("Symbol Table, level:%d, variables: \n", level);
    varNode *current = table->variables;
    while (current != NULL)
    {
        printf("ID: %s | Type: %s | Const: %d | Init: %d | Used: %d\n",
               current->variable.id,
               valTypeToString(current->variable.type),
               current->variable.isConst,
               current->variable.isInitialized,
               current->variable.isUsed);
        // varToString(&current->variable));
        current = current->next;
    }
    symbolTable *child = table->firstChild;
    while (child != NULL)
    {
        printSymbolTable(child, level + 1);
        child = child->nextSibling;
    }
}

char *valTypeToString(valType type)
{
    switch (type)
    {
    case typeInt:
        return "int";
    case typeFloat:
        return "float";
    case typeBool:
        return "bool";
    case typeChar:
        return "char";
    case typeString:
        return "string";
    default:
        return "unknown";
    }
}

char *varToString(const var *variable)
{
    char buffer[256];
    switch (variable->type)
    {
    case typeInt:
        snprintf(buffer, sizeof(buffer), "%d", variable->value.iValue);
        break;
    case typeFloat:
        snprintf(buffer, sizeof(buffer), "%f", variable->value.fValue);
        break;
    case typeBool:
        snprintf(buffer, sizeof(buffer), "%s", variable->value.bValue ? "true" : "false");
        break;
    case typeChar:
        snprintf(buffer, sizeof(buffer), "%c", variable->value.cValue);
        break;
    case typeString:
        snprintf(buffer, sizeof(buffer), "%s", variable->value.sValue ? variable->value.sValue : "NULL");
        break;
    default:
        snprintf(buffer, sizeof(buffer), "Unknown type");
        break;
    }
    return strdup(buffer);
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

symbolTable *findNearestLoopScope(symbolTable *table)
{
    while (table != NULL)
    {
        if (table->isLoopScope)
        {
            printf("Found loop scope: %s\n", table->id);
            return table;
        }
        table = table->parent;
    }
    return NULL;
}

symbolTable *createSymbolTable(symbolTable *parent)
{
    static int counter = 0;
    char id[50];
    sprintf(id, "S_%d", counter++);

    symbolTable *newTable = (symbolTable *)malloc(sizeof(symbolTable));
    if (newTable == NULL)
    {
        return NULL;
    }
    newTable->id = strdup(id);
    newTable->parent = parent;
    newTable->variables = NULL;
    newTable->nextSibling = NULL;
    newTable->firstChild = NULL;
    newTable->isLoopScope = false;

    if (parent != NULL)
    {
        if (parent->firstChild == NULL)
        {
            parent->firstChild = newTable;
        }
        else
        {
            symbolTable *current = parent->firstChild;
            while (current->nextSibling != NULL)
            {
                current = current->nextSibling;
            }
            current->nextSibling = newTable;
        }
    }
    return newTable;
}

function *findFunction(symbolTable *table, const char *id)
{
    while (table != NULL)
    {
        functionNode *current = table->functions;
        while (current != NULL)
        {
            if (strcmp(current->func.id, id) == 0)
            {
                return &current->func;
            }
            current = current->next;
        }
        table = table->parent;
    }
    return NULL;
}

function *addFunction(symbolTable *table, const char *id, valType returnType)
{
    if (findFunction(table, id) != NULL)
    {
        return NULL;
    }

    functionNode *newFuncNode = (functionNode *)malloc(sizeof(functionNode));
    newFuncNode->func.id = strdup(id);
    newFuncNode->func.returnType = returnType;
    newFuncNode->func.parameters = NULL;
    newFuncNode->next = NULL;

    if (table->functions == NULL)
    {
        table->functions = newFuncNode;
    }
    else
    {
        functionNode *current = table->functions;
        while (current->next != NULL)
        {
            current = current->next;
        }
        current->next = newFuncNode;
    }
    return &newFuncNode->func;
}

bool addParameterToFunction(function *func, varNode *param)
{
    if (func == NULL || param == NULL)
    {
        return false;
    }
    param->paramNext = NULL;
    if (func->parameters == NULL)
    {
        func->parameters = param;
    }
    else
    {
        varNode *current = func->parameters;
        while (current->paramNext != NULL)
        {
            current = current->paramNext;
        }
        current->paramNext = param;
    }
    return true;
}