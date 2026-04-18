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
    typeVoid,
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
    struct varNode *paramNext;
    struct symbolTable *scope;
} varNode;

typedef struct function
{
    char *id;
    valType returnType;
    varNode *parameters;
    struct symbolTable *scope;
} function;

typedef struct functionNode
{
    function func;
    struct functionNode *next;
} functionNode;

typedef struct argNode
{
    valNode val;
    char *place;
    struct argNode *next;
} argNode;

typedef struct symbolTable
{
    char *id;
    struct symbolTable *parent;
    varNode *variables;
    struct symbolTable *nextSibling;
    struct symbolTable *firstChild;
    bool isLoopScope;
    char *starLabel;
    char *endLabel;
    functionNode *functions;
    bool isFunctionScope;
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
symbolTable *findNearestLoopScope(symbolTable *table);
valNode varToValNode(varNode *variable);
char *valTypeToString(valType type);
char *varToString(const var *variable);
symbolTable *createSymbolTable(symbolTable *parent);

typedef struct
{
    char *elseLabel;
    char *endLabel;
} IfLabelStorage;

typedef struct
{
    char *switchExpr;
    char *matchedVar;
} SwitchStorage;

function *findFunction(symbolTable *table, const char *id);
function *addFunction(symbolTable *table, const char *id, valType returnType);
bool addParameterToFunction(function *func, varNode *param);
#endif