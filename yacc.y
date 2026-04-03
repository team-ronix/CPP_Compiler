%{
    #define MAX_SYMBOLS 100
    #define MAX_SYMBOL_LENGTH 100
    #include <stdlib.h> 
    #include <stdarg.h> 
    #include "calc3.h"
    #include "structs.h"
    int symCount = 0;
    /* prototypes */ 
    nodeType *opr(int oper, int nops, ...); 
    nodeType *id(int i); 
    nodeType *con(int value); 
    void freeNode(nodeType *p);
    int ex(nodeType *p); 
    int yylex(void); 
    void yyerror(char *s);
    IdNode* symTable = malloc(sizeof(IdNode)); 
    /*TODO: For loop, switch-case, function*/
%}

%union {
    int iValue; 
    float fValue;
    char cValue;
    char *sValue;
    bool bValue;
    nodeType *nPtr;                
};



/* Literal and identifier tokens with types from %union */
%token <iValue> INTEGER
%token <fValue> FLOATING
%token <cValue> CHARACTER
%token <sValue> STRING_LITERAL
%token <sValue> IDENTIFIER
%token <bValue> BOOLEAN

/* Keywords (no associated value needed) */
%token INT FLOAT BOOL CHAR STRING
%token IF ELSE WHILE FOR SWITCH CASE DO BREAK CONTINUE RETURN

/* Logical operators */
%token OR AND NOT

/* Relational operators */
%token GE LE EQ NE

/* Operator precedence */
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS
%nonassoc IF
%nonassoc ELSE

program: 
  function                { exit(0); } 
  ; 
 
function: 
    function stmt         { ex($2); freeNode($2); } 
  | /* NULL */ 
  ; 
 
stmt: 
    ';'                     { $$ = opr(';', 2, NULL, NULL); } 
  | expr ';'                { $$ = $1; } 
  | PRINT expr ';'          { $$ = opr(PRINT, 1, $2); } 
  | VARIABLE '=' expr ';'   { $$ = opr('=', 2, id($1), $3); } 
  | DO stmt WHILE '(' expr ')' ';' { $$ = opr(DO, 2, $2, $5); }
  | FOR (expr; expr; expr) stmt { $$ = opr(FOR, 4, $2, $4, $6, $8); }
  | WHILE '(' expr ')' stmt { $$ = opr(WHILE, 2, $3, $5); } 
  | IF '(' expr ')' stmt %prec IF { $$ = opr(IF, 2, $3, $5); } 
  
  | IF '(' expr ')' stmt ELSE stmt 
                            { $$ = opr(IF, 3, $3, $5, $7); } 
  | BLOCK       { $$ = $1; } 
  | IDENTIFIER 
    ; 
 
stmt_list: 
    stmt                  { $$ = $1; } 
  | stmt_list stmt        { $$ = opr(';', 2, $1, $2); } 
  ; 
 
expr: 
    INTEGER               { $$ = con($1); } 
  | VARIABLE              { $$ = id($1); } 
  | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); } 
  | expr '+' expr         { $$ = opr('+', 2, $1, $3); } 
  | expr '-' expr         { $$ = opr('-', 2, $1, $3); } 
  | expr '*' expr         { $$ = opr('*', 2, $1, $3); } 
  | expr '/' expr         { $$ = opr('/', 2, $1, $3); } 
  | expr '<' expr         { $$ = opr('<', 2, $1, $3); } 
  | expr '>' expr         { $$ = opr('>', 2, $1, $3); } 
  | expr GE expr          { $$ = opr(GE, 2, $1, $3); } 
  | expr LE expr          { $$ = opr(LE, 2, $1, $3); } 
  | expr NE expr          { $$ = opr(NE, 2, $1, $3); } 
  | expr EQ expr          { $$ = opr(EQ, 2, $1, $3); } 
  | '(' expr ')'          { $$ = $2; } 
  ; 

VARIABLE: 
        INT IDENTIFIER { $$ = $2; }
    | FLOAT IDENTIFIER { $$ = $2; }
    | BOOL IDENTIFIER { $$ = $2; }
    | CHAR IDENTIFIER { $$ = $2; }
    | STRING IDENTIFIER { $$ = $2; }
    | IDENTIFIER { $$ = $1; }
    ;

    BLOCK: 
        '{' stmt_list '}' { $$ = $2; }

%%

nodeType *con(union value, valType type) { 
    nodeType *p; 
    /* allocate node */ 
    if ((p = malloc(sizeof(nodeType))) == NULL) 
    yyerror("out of memory"); 
    /* copy information */ 
    p->type = typeCon; 
    case type: 
        typeInt: p->con.valType = typeInt; p->con.iValue = value.iValue; break; 
        typeFloat: p->con.valType = typeFloat; p->con.fValue = value.fValue; break; 
        typeChar: p->con.valType = typeChar; p->con.cValue = value.cValue; break; 
        typeString: p->con.valType = typeString; p->con.sValue = value.sValue; break; 
        typeBool: p->con.valType = typeBool; p->con.bValue = value.bValue; break;
    return p; 
}
nodeType *id(union value, valType type) { 
    nodeType *p; 
    /* allocate node */ 
    if ((p = malloc(sizeof(nodeType))) == NULL) 
    yyerror("out of memory"); 
    /* copy information */ 
    p->type = typeId; 
    case type: 
        typeInt: p->id.type = typeInt; p->id.value.iValue = value.iValue; break;
        typeFloat: p->id.type = typeFloat; p->id.value.fValue = value.fValue; break;
        typeChar: p->id.type = typeChar; p->id.value.cValue = value.cValue; break;
        typeString: p->id.type = typeString; p->id.value.sValue = value.sValue; break;
        typeBool: p->id.type = typeBool; p->id.value.bValue = value.bValue; break;
    return p; 
}

nodeType *opr(int oper, int nops, ...) { 
    va_list ap; 
    nodeType *p; 
    int i; 
    /* allocate node, extending op array */ 
    if ((p = malloc(sizeof(nodeType) + (nops-1) * sizeof(nodeType *))) == NULL) 
        yyerror("out of memory"); 
    /* copy information */ 
    p->type = typeOpr; 
    p->opr.oper = oper; 
    p->opr.nops = nops; 
    va_start(ap, nops); 
    for (i = 0; i < nops; i++) 
        p->opr.op[i] = va_arg(ap, nodeType*); 
    va_end(ap); 
    return p;
}

void freeNode(nodeType *p) { 
    int i; 
    if (!p) return; 
    if (p->type == typeOpr) { 
    for (i = 0; i < p->opr.nops; i++) 
    freeNode(p->opr.op[i]); 
    } 
    free (p); 
    } 
    void yyerror(char *s) { 
    fprintf(stdout, "%s\n", s); 
    } 
    int main(void) { 
    yyparse(); 
    return 0; 
}