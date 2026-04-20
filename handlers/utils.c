#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int lineNumber;

static FILE *diagnosticsFile = NULL;

int initDiagnostics(const char *errorFilePath)
{
    if (diagnosticsFile != NULL)
    {
        fclose(diagnosticsFile);
        diagnosticsFile = NULL;
    }

    diagnosticsFile = fopen(errorFilePath, "w");
    return diagnosticsFile != NULL;
}

void closeDiagnostics(void)
{
    if (diagnosticsFile != NULL)
    {
        fclose(diagnosticsFile);
        diagnosticsFile = NULL;
    }
}

void errorMessage(const char *message)
{
    if (diagnosticsFile == NULL)
    {
        fprintf(stderr, "Error: diagnostics file is not open\n");
        return;
    }
    fprintf(diagnosticsFile, "Error: %s at line %d\n", message, lineNumber);
    fflush(diagnosticsFile);
}

void warningMessage(const char *message, bool printLineNumber)
{
    if (diagnosticsFile == NULL)
    {
        fprintf(stderr, "Warning: diagnostics file is not open\n");
        return;
    }
    if (printLineNumber)
    {
        fprintf(diagnosticsFile, "Warning: %s at line %d\n", message, lineNumber);
    }
    else
    {
        fprintf(diagnosticsFile, "Warning: %s\n", message);
    }
    fflush(diagnosticsFile);
}

void stackInit(Stack *s)
{
    s->data = malloc(STACK_INITIAL_CAPACITY * sizeof(void *));
    s->top = -1;
    s->capacity = s->data ? STACK_INITIAL_CAPACITY : 0;
}

void stackFree(Stack *s)
{
    free(s->data);
    s->data = NULL;
    s->top = -1;
    s->capacity = 0;
}

int stackPush(Stack *s, void *element)
{
    if (s->top + 1 >= s->capacity)
    {
        int newCap = s->capacity * 2;
        void **newData = realloc(s->data, newCap * sizeof(void *));
        if (!newData)
            return 0;
        s->data = newData;
        s->capacity = newCap;
    }
    s->data[++s->top] = element;
    return 1;
}

void *stackPop(Stack *s)
{
    if (s->top < 0)
        return NULL;
    return s->data[s->top--];
}

void *stackPeek(const Stack *s)
{
    if (s->top < 0)
        return NULL;
    return s->data[s->top];
}

int stackIsEmpty(const Stack *s)
{
    return s->top < 0;
}

int stackSize(const Stack *s)
{
    return s->top + 1;
}

bool canConvert(valType from, valType to)
{
    if (from == to)
        return true;

    switch (from)
    {
    case typeInt:
        return (to == typeFloat || to == typeBool || to == typeChar);
    case typeFloat:
        return (to == typeInt || to == typeBool);
    case typeChar:
        return (to == typeInt || to == typeFloat || to == typeBool);
    case typeBool:
        return (to == typeInt || to == typeFloat);
    default:
        return false;
    }
}

valNode convertValue(valNode val, valType targetType)
{
    valNode result;
    result.type = targetType;

    switch (targetType)
    {
    case typeInt:
        if (val.type == typeFloat)
            result.value.iValue = (int)val.value.fValue;
        else if (val.type == typeChar)
            result.value.iValue = (int)val.value.cValue;
        else if (val.type == typeBool)
            result.value.iValue = val.value.bValue ? 1 : 0;
        else
            result.value.iValue = val.value.iValue;
        break;

    case typeFloat:
        if (val.type == typeInt)
            result.value.fValue = (float)val.value.iValue;
        else if (val.type == typeChar)
            result.value.fValue = (float)(int)val.value.cValue;
        else if (val.type == typeBool)
            result.value.fValue = val.value.bValue ? 1.0f : 0.0f;
        else
            result.value.fValue = val.value.fValue;
        break;

    case typeBool:
        if (val.type == typeInt)
            result.value.bValue = (val.value.iValue != 0);
        else if (val.type == typeFloat)
            result.value.bValue = (val.value.fValue != 0.0f);
        else if (val.type == typeChar)
            result.value.bValue = (val.value.cValue != '\0');
        else
            result.value.bValue = val.value.bValue;
        break;

    case typeChar:
        if (val.type == typeInt)
            result.value.cValue = (char)val.value.iValue;
        else
            result.value.cValue = val.value.cValue;
        break;

    default:
        ERRORF("Cannot convert to target type %d.", targetType);
        result = val;
        break;
    }

    return result;
}
