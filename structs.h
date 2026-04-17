#ifndef STRUCTS_H
#define STRUCTS_H

#include <stdbool.h>

typedef enum
{
    typeCon,
    typeId,
    typeOpr
} nodeEnum;

typedef enum
{
    typeInt,
    typeFloat,
    typeBool,
    typeChar,
    typeString,
    noType
} valType;

/* constants */
typedef struct valNode
{
    valType type;
    union
    {
        int iValue;
        float fValue;
        bool bValue;
        char cValue;
        char *sValue;
    } value;

} valNode;

/* operators */
typedef struct
{
    int oper;
    int nops;
    struct nodeTypeTag *op[1];
} oprNodeType;

typedef struct
{
    valType type;
    char *id;
    union
    {
        int iValue;
        float fValue;
        bool bValue;
        char cValue;
        char *sValue;
    } value;
    bool isConst;
    bool isInitialized;
    bool isUsed;
} var;

typedef struct varNode
{
    var variable;
    struct varNode *next;
    struct symbolTable *scope;
} varNode;

typedef struct symbolTable
{
    // char *id;
    struct symbolTable *parent;
    varNode *variables;
    struct symbolTable *nextSibling;
    struct symbolTable *firstChild;
    char *starLabel;
    char *endLabel;
} symbolTable;

typedef struct exprResult
{
    bool error;
    valNode value;
    char *place;
} exprResult;

typedef struct quadruple
{
    char *op;
    char *arg1;
    char *arg2;
    char *result;
} quadruple;

varNode *findVariable(symbolTable *table, const char *id);
varNode *addVariable(symbolTable *table, const char *id, valType type);
varNode *addVariableWithValue(symbolTable *table, const char *id, valType type, bool isConst, valNode value);
bool removeVariable(symbolTable *table, const char *id);
void assignValue(varNode *varNode, valNode value, valType type);
bool editValue(symbolTable *table, const char *id, const valNode *newValue);
bool isInCurrentScope(symbolTable *table, const char *id);
void printSymbolTable(symbolTable *table, int level);
valNode varToValNode(varNode *variable);
char *valTypeToString(valType type);
char *varToString(const var *variable);
symbolTable *createSymbolTable(symbolTable *parent);
#endif