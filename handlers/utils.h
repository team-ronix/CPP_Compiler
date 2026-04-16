#ifndef UTILS_H
#define UTILS_H

#include "../structs.h"

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
