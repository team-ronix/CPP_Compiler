#ifndef UTILS_H
#define UTILS_H

#include "../structs.h"
#include <stddef.h>

#define STACK_INITIAL_CAPACITY 16

typedef struct {
    void   **data;     /* array of void* elements            */
    int      top;      /* index of the next free slot (-1 = empty) */
    int      capacity; /* current allocated capacity          */
} Stack;

/* Initialise an already-allocated Stack struct. */
void  stackInit(Stack *s);

/* Free the internal array (does NOT free the elements themselves). */
void  stackFree(Stack *s);

/* Push an element. Returns 1 on success, 0 on allocation failure. */
int   stackPush(Stack *s, void *element);

/* Pop and return the top element. Returns NULL if the stack is empty. */
void *stackPop(Stack *s);

/* Peek at the top element without removing it. Returns NULL if empty. */
void *stackPeek(const Stack *s);

/* Returns 1 if the stack is empty, 0 otherwise. */
int   stackIsEmpty(const Stack *s);

/* Returns the number of elements currently on the stack. */
int   stackSize(const Stack *s);

/* Result of a type-convertibility check */
typedef struct {
    bool canConvert;
} canConvertResult;

/*
 * Implicit conversion rules for the compiled language:
 *   int   -> float  (widening)
 *   int   -> bool   (nonzero = true)
 *   int   -> char   (truncation)
 *   float -> int    (truncation)
 *   float -> bool   (nonzero = true)
 *   char  -> int    (widening)
 *   char  -> float  (widening)
 *   char  -> bool   (nonzero = true)
 *   bool  -> int    (0 / 1)
 *   bool  -> float  (0.0 / 1.0)
 */
canConvertResult canConvert(valType from, valType to);

/* Convert a valNode to the target type. Assumes canConvert returned true. */
valNode convertValue(valNode val, valType targetType);

#endif
