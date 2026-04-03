typedef enum
{
    typeCon,
    typeId,
    typeOpr
} nodeEnum;

typedef enum valType
{
    typeInt,
    typeFloat,
    typeBool,
    typeChar,
    typeString
};

/* constants */
typedef struct
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

} conNodeType;

/* operators */
typedef struct
{
    int oper;                  /* operator */
    int nops;                  /* number of operands */
    struct nodeTypeTag *op[1]; /* operands, extended at runtime */
} oprNodeType;

typedef struct
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

    bool isConst;
    bool isInitialized;
    idNodeType *next[26];
} idNodeType;

typedef struct
{
    nodeEnum type; /* type of node */
    union
    {
        conNodeType con;
        idNodeType id;
        oprNodeType opr;
    };
} nodeType;
