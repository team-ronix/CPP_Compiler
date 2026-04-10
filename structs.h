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
    typeString
} valType;

/* constants */
typedef struct valNode
{
    valType valType;
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
} var;

typedef struct varNode
{
    var variable;
    struct varNode *next;
} varNode;

typedef struct symbolTable
{
    // char *id;
    struct symbolTable *parent;
    varNode *variables;
} symbolTable;

varNode *findVariable(symbolTable *table, const char *id);
varNode *addVariable(symbolTable *table, const char *id, const char *type);
bool isVariableDeclared(symbolTable *table, const char *id);
bool removeVariable(symbolTable *table, const char *id);
