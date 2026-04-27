#ifndef UTILS_H
#define UTILS_H

#include "../structs.h"
#include <stddef.h>
#include <stdio.h>

#define STACK_INITIAL_CAPACITY 16

typedef struct
{
    void **data;
    int top;
    int capacity;
} Stack;

void stackInit(Stack *s);

void stackFree(Stack *s);

int stackPush(Stack *s, void *element);

void *stackPop(Stack *s);

void *stackPeek(const Stack *s);

int stackIsEmpty(const Stack *s);

int stackSize(const Stack *s);

bool canConvert(valType from, valType to);

valNode convertValue(valNode val, valType targetType);

int initDiagnostics(const char *errorFilePath);
void closeDiagnostics(void);
void errorMessage(const char *message);
void warningMessage(const char *message, bool printLineNumber);

#define ERRORF(...)                                              \
    do                                                           \
    {                                                            \
        char errorBuffer[512];                                   \
        snprintf(errorBuffer, sizeof(errorBuffer), __VA_ARGS__); \
        errorMessage(errorBuffer);                               \
    } while (0)

#define WARNF(...)                                                   \
    do                                                               \
    {                                                                \
        char warningBuffer[512];                                     \
        snprintf(warningBuffer, sizeof(warningBuffer), __VA_ARGS__); \
        warningMessage(warningBuffer, true);                         \
    } while (0)

#endif
