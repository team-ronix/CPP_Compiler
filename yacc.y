%{
#include "structs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
symbolTable *globalTable = NULL;
valType currentType = noType;
symbolTable *currentScope = NULL;
bool isConstDecl = false;
// TODO: INT->FLOAT, FLOAT->INT, etc. in expr rules
// TODO: default in switch case
%}

%union {
    int iValue;
    float fValue;
    char cValue;
    char *sValue;
    int bValue;

    valNode val;

    struct {
        bool hasValue;
        valNode val;
    } assign;
    


}

%type <assign> ASSIGNMENT
%token <iValue> INTEGER
%token <fValue> FLOATING
%token <cValue> CHARACTER
%token <sValue> STRING_LITERAL
%token <sValue> IDENTIFIER
%token <bValue> BOOLEAN
%type <val> expr

%token INT FLOAT BOOL CHAR STRING
%token IF ELSE WHILE FOR SWITCH CASE DO BREAK CONTINUE RETURN
%token PRINT
%token OR AND NOT
%token GE LE EQ NE
%token INC DEC
%token CONST
%token VOID

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%left AND
%left OR
%right NOT
%nonassoc UMINUS
%nonassoc IF
%nonassoc ELSE

%start program

%%

program:
    top_level_list
;

top_level_list:
      /* empty */
    | top_level_list top_level_item
;

top_level_item:
      stmt
    | FUNCTION
;


stmt_list:
      stmt
    | stmt_list stmt
    ;



TYPE:
    INT {currentType = typeInt;}
    | FLOAT {currentType = typeFloat;}
    | BOOL {currentType = typeBool;}
    | CHAR {currentType = typeChar;}
    | STRING {currentType = typeString;}
    | VOID
    ;

BLOCK_STMT_LIST:
      /* empty */ {
        symbolTable* temp = currentScope->parent;
        // free(currentScope);
        currentScope = temp;
    }
    |stmt BLOCK_STMT_LIST
    ;

BLOCK:
    '{'{
        symbolTable *newScope = (symbolTable *)malloc(sizeof(symbolTable));
        if (newScope == NULL) {
            fprintf(stderr, "Error: Failed to allocate memory for new scope.\n");
            exit(1);
        }
        newScope->parent = currentScope;
        newScope->variables = NULL;
        currentScope = newScope;
    } BLOCK_STMT_LIST {
        symbolTable *temp = currentScope->parent;
        free(currentScope);
        currentScope = temp;
    } '}'
    ;

PARAM_LIST:
    /* empty */
    | TYPE IDENTIFIER DEFAULT_VAL
    | PARAM_LIST ',' TYPE IDENTIFIER DEFAULT_VAL
    ;

FUNCTION:
    TYPE IDENTIFIER '('PARAM_LIST ')' BLOCK
  ;

ARG_LIST:
    /* empty */
    | expr
    | ARG_LIST ',' expr
;

FUNCTION_CALL:
    IDENTIFIER '(' ARG_LIST ')'
;

DEFAULT_VAL:
    '=' expr
    | /* empty */
    ;

FOR_INIT:
    TYPE IDENTIFIER '=' expr
    | IDENTIFIER '=' expr
    | /* empty */
;

expr_opt:
      /* empty */
    |IDENTIFIER INC
    | IDENTIFIER DEC
    | expr
;

ASSIGNMENT:
    /* empty */
    {$$.hasValue = 0;}
    | '=' expr { 
        $$.hasValue = 1;
        $$.val = $2;
     }
;   
    
CHAINED_DECLARATION:
    /* empty */
    | ',' IDENTIFIER ASSIGNMENT CHAINED_DECLARATION {
        {
        if(isInCurrentScope(currentScope, $2)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
            exit(1);
        }
        if($3.hasValue) {
            
            printf("Declaring variable '%s' with initial value.\n", $2);
            valNode val = $3.val;
            if(val.type != currentType) {
                fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $2, currentType, val.type);
                exit(1);
            }
            if(isInCurrentScope(currentScope, $2)) {
                fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
                exit(1);
            }
            addVariableWithValue(currentScope, $2, currentType, isConstDecl, $3.val);
        }
        else {
            if(isConstDecl) {
                fprintf(stderr, "Error: Constant variable '%s' must be initialized.\n", $2);
                exit(1);
            }
            printf("Declaring variable '%s' without initial value.\n", $2);
            addVariable(currentScope, $2, currentType);
        }
    }
    }
;

expr:
    IDENTIFIER { 
        varNode *var = findVariable(currentScope, $1);
        if (var == NULL) {
            fprintf(stderr, "Error: Variable '%s' not declared.\n", $1);
            exit(1);
        }
        var->variable.isUsed = true;
        $$ = varToValNode(var);
    }
    | INTEGER    {
        valNode node;
        node.type = typeInt;
        node.value.iValue = $1;
        $$ = node;
    }
    | FLOATING   {
        valNode node;
        node.type = typeFloat;
        node.value.fValue = $1;
        $$ = node;
    }
    | BOOLEAN    {
        valNode node;
        node.type = typeBool;
        node.value.bValue = $1;
        $$ = node;
    }
    | CHARACTER  {
        valNode node;
        node.type = typeChar;
        node.value.cValue = $1;
        $$ = node;
    }
    | STRING_LITERAL {
        valNode node;
        node.type = typeString;
        node.value.sValue = strdup($1);
        $$ = node;
    }
    | '-' expr %prec UMINUS {}
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | expr '<' expr
    | expr '>' expr
    | expr GE expr
    | expr LE expr
    | expr NE expr
    | expr EQ expr
    | '(' expr ')' {}
    | NOT expr {}
    | expr AND expr
    | expr OR expr
    ;

CONST_TYPE:
    CONST {isConstDecl = true;}
    ;

stmt:
      ';'
    | expr ';'
    | PRINT '(' expr ')' ';'
    | TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
        if(isInCurrentScope(currentScope, $2)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
            exit(1);
        }
        if($3.hasValue) {
            printf("Declaring variable '%s' with initial value.\n", $2);
            valNode val = $3.val;
            if(val.type != currentType) {
                fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $2, currentType, val.type);
                exit(1);
            }
            addVariableWithValue(currentScope, $2, currentType, false, $3.val);      
        }
        else {
            printf("Declaring variable '%s' without initial value.\n", $2);
            addVariable(currentScope, $2, currentType);
        }
        currentType = noType;
    }
    | CONST_TYPE TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
        if(isInCurrentScope(currentScope, $3)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $3, currentType);
            exit(1);
        }
        if(!$4.hasValue) {
            fprintf(stderr, "Error: Constant variable '%s' must be initialized.\n", $3);
            exit(1);
        }
        printf("Declaring constant variable '%s' with initial value.\n", $3);
        valNode val = $4.val;
        if(val.type != currentType) {
            fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $3, currentType, val.type);
            exit(1);
        }
        addVariableWithValue(currentScope, $3, currentType, true, $4.val); 
        isConstDecl = false;
        currentType = noType;  
    }
    | IDENTIFIER '=' expr ';'
    | FUNCTION_CALL ';'
    | IDENTIFIER INC ';'
    | IDENTIFIER DEC ';'
    | BREAK ';'
    | CONTINUE ';'
    | RETURN expr ';'
    | DO stmt WHILE '(' expr ')' ';'
    | FOR '(' FOR_INIT ';' expr ';' expr_opt ')' stmt
    | WHILE '(' expr ')' stmt
    | IF '(' expr ')' stmt %prec IF
    | IF '(' expr ')' stmt ELSE stmt
    | SWITCH '(' expr ')' '{' CASE_LIST '}'
    | BLOCK
    ;

CASE_LIST:
        CASE expr ':' stmt_list CASE_LIST
    | /* empty */
    ;
    


%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
}

int main(void) {
    globalTable = (symbolTable *)malloc(sizeof(symbolTable));
    if (globalTable == NULL) {
        fprintf(stderr, "Error: Failed to allocate global symbol table.\n");
        return 1;
    }
    globalTable->parent = NULL;
    globalTable->variables = NULL;
    currentScope = globalTable;
    return yyparse();
}