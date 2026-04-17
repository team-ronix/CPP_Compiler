%{
#include "structs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "handlers/arithmetic.h"
#include "handlers/comparison.h"
#include "handlers/utils.h"
void yyerror(const char *s);
int yylex(void);
char *tempResult(void);
char *createLabel(void);
void enterScope(void);
void exitScope(void);
void emit(const char *op, const char *arg1, const char *arg2, const char *result);
extern int lineNumber;
symbolTable *globalTable = NULL;
valType currentType = noType;
symbolTable *currentScope = NULL;
bool isConstDecl = false;
int resultCounter = 0;
int labelsCounter = 0;
const char *resultQuadFile = "quads.txt";
FILE *quadFile = NULL;
char* startLabel = NULL;
char* endLabel = NULL;
Stack loopStack;



// TODO: INT->FLOAT, FLOAT->INT, etc. in expr rules
// TODO: default in switch case
// TODO: int + int;?????
// TODO: emit for or and not
%}

%union {
    int iValue;
    float fValue;
    char cValue;
    char *sValue;
    int bValue;

    struct {
        valNode val;
        char *place;
    } exprNode;

    struct {
        bool hasValue;
        valNode val;
        char *place;
    } assign;
    


}

%type <assign> ASSIGNMENT
%token <iValue> INTEGER
%token <fValue> FLOATING
%token <cValue> CHARACTER
%token <sValue> STRING_LITERAL
%token <sValue> IDENTIFIER
%token <bValue> BOOLEAN
%type <exprNode> expr
%token INT FLOAT BOOL CHAR STRING
%token IF ELSE FOR WHILE SWITCH CASE DO BREAK CONTINUE RETURN DEFAULT
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
        // symbolTable* temp = currentScope->parent;
        // free(currentScope);
        // currentScope = temp;
    }
    |stmt BLOCK_STMT_LIST
    ;

BLOCK:
    '{' BLOCK_STMT_LIST '}'
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
        $$.val = $2.val;
        $$.place = $2.place;
     }
;   
    
CHAINED_DECLARATION:
    /* empty */
    | ',' IDENTIFIER ASSIGNMENT CHAINED_DECLARATION {
        {
        if(isInCurrentScope(currentScope, $2)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
            // exit(1);
        }
        if($3.hasValue) {
            
            // printf("Declaring variable '%s' with initial value.\n", $2);
            valNode val = $3.val;
            if(val.type != currentType) {
                fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $2, currentType, val.type);
                // exit(1);
            }
            if(isInCurrentScope(currentScope, $2)) {
                fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
                // exit(1);
            }
            emit("DECL", $3.place, NULL, $2);
            addVariableWithValue(currentScope, $2, currentType, isConstDecl, $3.val);
        }
        else {
            if(isConstDecl) {
                fprintf(stderr, "Error: Constant variable '%s' must be initialized.\n", $2);
                // exit(1);
            }
            // printf("Declaring variable '%s' without initial value.\n", $2);
            emit("DECL", NULL, NULL, $2);
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
            // // exit(1);
        }
        if (!var->variable.isInitialized) {
            fprintf(stderr, "Error: Variable '%s' is used before initialization.\n", $1);
            // // exit(1);
        }
        var->variable.isUsed = true;
        char buffer[20];
        sprintf(buffer, "%s", $1);
        $$.place = strdup(buffer);
        $$.val = varToValNode(var);
    }
    | INTEGER    {
        valNode node;
        node.type = typeInt;
        node.value.iValue = $1;
        char buffer[20];
        sprintf(buffer, "%d", $1);
        $$.place = strdup(buffer);
        $$.val = node;
    }
    | FLOATING   {
        valNode node;
        node.type = typeFloat;
        node.value.fValue = $1;
        char buffer[20];
        sprintf(buffer, "%f", $1);
        $$.place = strdup(buffer);
        $$.val = node;
    }
    | BOOLEAN    {
        valNode node;
        node.type = typeBool;
        node.value.bValue = $1;
        char buffer[6];
        sprintf(buffer, "%s", $1 ? "true" : "false");
        $$.place = strdup(buffer);
        $$.val = node;
    }
    | CHARACTER  {
        valNode node;
        node.type = typeChar;
        node.value.cValue = $1;
        char buffer[4];
        sprintf(buffer, "'%c'", $1);
        $$.place = strdup(buffer);
        $$.val = node;
    }
    | STRING_LITERAL {
        valNode node;
        node.type = typeString;

        char *str = $1;
        node.value.sValue = strdup(str);
        char clipped[256];

        if (strlen(str) > 253) {
            strncpy(clipped, str, 253);
            clipped[251] = '.';
            clipped[252] = '.';
            clipped[253] = '.';
            clipped[254] = '\0';
            str = clipped;
        }

        char buffer[256];
        sprintf(buffer, "\"%s\"", str);
        $$.place = strdup(buffer);
        $$.val = node;
    }
    | '-' expr %prec UMINUS {
        if ($2.val.type != typeInt && $2.val.type != typeFloat && $2.val.type != typeChar) {
            fprintf(stderr, "Error: Unary '-' operator requires numeric operand.\n");
        } else {
            valNode resultNode;
            resultNode.type = $2.val.type;
            if ($2.val.type == typeInt) {
                resultNode.value.iValue = -$2.val.value.iValue;
            } else if ($2.val.type == typeFloat) {
                resultNode.value.fValue = -$2.val.value.fValue;
            } else if ($2.val.type == typeChar) {
                resultNode.type = typeInt; // Promote char to int for negation
                resultNode.value.iValue = -(int)$2.val.value.cValue;
            }
            char buffer[20];
            sprintf(buffer, "-%s", $2.place);
            $$.place = strdup(buffer);
            $$.val = resultNode;
        }
    }
    | expr '+' expr {
        exprResult res = arithmeticOperations(&$1.val, &$3.val, "+");
        if(!res.error) {
            emit("ADD", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr '-' expr
    {
        exprResult res = arithmeticOperations(&$1.val, &$3.val, "-");
        if(!res.error) {
            emit("SUB", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr '*' expr {
        exprResult res = arithmeticOperations(&$1.val, &$3.val, "*");
        if(!res.error) {
            emit("MUL", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr '/' expr {
        exprResult res = arithmeticOperations(&$1.val, &$3.val, "/");
        if(!res.error) {
            emit("DIV", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr '<' expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, "<");
        if(!res.error) {
            emit("LT", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr '>' expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, ">");
        if(!res.error) {
            emit("GT", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr GE expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, ">=");
        if(!res.error) {
            emit("GE", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr LE expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, "<=");
        if(!res.error) {
            emit("LE", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr NE expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, "!=");
        if(!res.error) {
            emit("NE", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr EQ expr {
        exprResult res = comparisonOperations(&$1.val, &$3.val, "==");
        if(!res.error) {
            emit("EQ", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | '(' expr ')' {
        $$.place = $2.place;
        $$.val = $2.val;
    }
    | NOT expr {
        if ($2.val.type != typeInt && $2.val.type != typeFloat && $2.val.type != typeChar) {
            fprintf(stderr, "Error: Unary 'NOT' operator requires numeric operand.\n");
        } else {
            valNode resultNode;
            resultNode.type = typeBool;
            if ($2.val.type == typeInt) {
                resultNode.value.bValue = !($2.val.value.iValue);
            } else if ($2.val.type == typeFloat) {
                resultNode.value.bValue = !($2.val.value.fValue);
            } else if ($2.val.type == typeChar) {
                resultNode.value.bValue = !((int)$2.val.value.cValue);
            }
            char buffer[20];
            sprintf(buffer, "NOT %s", $2.place);
            $$.place = strdup(buffer);
            $$.val = resultNode;
        }
    }
    | expr AND expr {
        if ($1.val.type != typeInt && $1.val.type != typeFloat && $1.val.type != typeChar) {
            fprintf(stderr, "Error: Left operand of 'AND' must be numeric.\n");
        } else if ($3.val.type != typeInt && $3.val.type != typeFloat && $3.val.type != typeChar) {
            fprintf(stderr, "Error: Right operand of 'AND' must be numeric.\n");
        } else {
            valNode resultNode;
            resultNode.type = typeBool;
            bool leftVal = ($1.val.type == typeInt) ? $1.val.value.iValue :
                           ($1.val.type == typeFloat) ? $1.val.value.fValue :
                                                        (int)$1.val.value.cValue;

            bool rightVal = ($3.val.type == typeInt) ? $3.val.value.iValue :
                            ($3.val.type == typeFloat) ? $3.val.value.fValue :
                                                         (int)$3.val.value.cValue;

            resultNode.value.bValue = leftVal && rightVal;
            char buffer[50];
            sprintf(buffer, "%s AND %s", $1.place, $3.place);
            $$.place = strdup(buffer);
            $$.val = resultNode;
        }
    }
    | expr OR expr {
        if ($1.val.type != typeInt && $1.val.type != typeFloat && $1.val.type != typeChar) {
            fprintf(stderr, "Error: Left operand of 'OR' must be numeric.\n");
        } else if ($3.val.type != typeInt && $3.val.type != typeFloat && $3.val.type != typeChar) {
            fprintf(stderr, "Error: Right operand of 'OR' must be numeric.\n");
        } else {
            valNode resultNode;
            resultNode.type = typeBool;
            bool leftVal = ($1.val.type == typeInt) ? $1.val.value.iValue :
                           ($1.val.type == typeFloat) ? $1.val.value.fValue :
                                                        (int)$1.val.value.cValue;

            bool rightVal = ($3.val.type == typeInt) ? $3.val.value.iValue :
                            ($3.val.type == typeFloat) ? $3.val.value.fValue :
                                                         (int)$3.val.value.cValue;

            resultNode.value.bValue = leftVal || rightVal;
            char buffer[50];
            sprintf(buffer, "%s OR %s", $1.place, $3.place);
            $$.place = strdup(buffer);
            $$.val = resultNode;
        }
    }
    ;

CONST_TYPE:
    CONST {isConstDecl = true;}
    ;

if_prefix:
    IF '(' expr ')' {
        enterScope();
        char *endIfLabel = createLabel();
        currentScope->endLabel = endIfLabel;

        enterScope();
        char *startOfElseLabel = createLabel();
        currentScope->endLabel = startOfElseLabel;
        emit("IF_FALSE", $3.place, NULL, startOfElseLabel);
    }
    ;

stmt:
      ';' {}
    | expr ';' {}
    | PRINT '(' expr ')' ';' {}
    | TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
        bool hasError = false;
        if(isInCurrentScope(currentScope, $2)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $2);
            hasError = true;
        }
        
        if($3.hasValue) {
            valNode val = $3.val;
            if(val.type != currentType) {
                // check if we can do implicit conversion from int to float or char to int, etc.
                canConvertResult convRes = canConvert(val.type, currentType);
                if(convRes.canConvert) {
                    val = convertValue(val, currentType);
                } else {
                    fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $2, currentType, val.type);
                    hasError = true;
                }
            }
            if(!hasError) {
                // printf("Declaring variable '%s' with initial value.\n", $2);
                emit("DECL", $3.place, NULL, $2);
                addVariableWithValue(currentScope, $2, currentType, false, $3.val);      
            }
        }
        else {
            // printf("Declaring variable '%s' without initial value.\n", $2);
            emit("DECL", NULL, NULL, $2);
            addVariable(currentScope, $2, currentType);
        }
        currentType = noType;
    }
    | CONST_TYPE TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
        valNode val = $4.val;
        bool hasError = false;

        if(isInCurrentScope(currentScope, $3)) {
            fprintf(stderr, "Error: Variable '%s' already declared in this scope.\n", $3, currentType);
            // exit(1);
            hasError = true;
        }
        if(!$4.hasValue) {
            fprintf(stderr, "Error: Constant variable '%s' must be initialized line number %d.\n", $3, lineNumber);
            // exit(1);
            hasError = true;
        }
        if(val.type != currentType) {
            fprintf(stderr, "Error: Type mismatch for variable '%s'. Expected type %d but got type %d.\n", $3, currentType, val.type);
            hasError = true;
        }
        if (!hasError) {
            printf("Declaring constant variable '%s' with initial value.\n", $3);
            addVariableWithValue(currentScope, $3, currentType, true, $4.val); 
            emit("CONST", $4.place, NULL, $3);
            isConstDecl = false;
            currentType = noType;
        }  
    }
    | IDENTIFIER '=' expr ';' {
        varNode *var = findVariable(currentScope, $1);
        if(!var) {
            fprintf(stderr, "Error: Variable '%s' you can't assign value to variable not declared before \n", $1, currentType);
            // exit(1);
        } else {
            if(!editValue(currentScope, $1, &$3.val)) {
                fprintf(stderr, "Error: Failed to assign value to variable '%s'.\n", $1);
                // exit(1);
            }else {
                emit("=", $3.place, NULL, $1);
            }
        }
    }
    | FUNCTION_CALL ';' {}
    | IDENTIFIER INC ';' {
        handleIncDec(currentScope, $1, "INC");
    }
    | IDENTIFIER DEC ';' {
        handleIncDec(currentScope, $1, "DEC");
    }
    | BREAK ';' {
        // TODO check for switch case as well
        symbolTable *loopScope = findNearestLoopScope(currentScope);
        if (loopScope == NULL) {
            fprintf(stderr, "Error: 'break' statement not within a loop.\n");
        } else {
            emit("JMP_BREAK", NULL, NULL, loopScope->endLabel);
        }
    }
    | CONTINUE ';' {
        symbolTable *loopScope = findNearestLoopScope(currentScope);
        if (loopScope == NULL) {
            fprintf(stderr, "Error: 'continue' statement not within a loop.\n");
        } else {
            emit("JMP_CONTINUE", NULL, NULL, loopScope->starLabel);
        }
    }
    | RETURN expr ';' {}
    | DO {
        enterScope();
        currentScope->starLabel = createLabel();
        currentScope->endLabel = createLabel();
        currentScope->isLoopScope = true;
        emit("LABEL", NULL, NULL, currentScope->starLabel);
    } BLOCK WHILE '(' expr ')'{
        emit("IF_FALSE", $6.place, NULL, currentScope->endLabel);
    } ';' {
        emit("JMP", NULL, NULL, currentScope->starLabel);
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
    }
    | FOR '(' FOR_INIT ';' expr ';' expr_opt ')' stmt {}
    | WHILE '(' {
        enterScope();
        currentScope->starLabel = createLabel();
        currentScope->endLabel = createLabel();
        currentScope->isLoopScope = true;
        emit("LABEL", NULL, NULL, currentScope->starLabel);
    } expr ')' {
        emit("IF_FALSE", $4.place, NULL, currentScope->endLabel);
    } BLOCK {
        emit("JMP", NULL, NULL, currentScope->starLabel);
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
    }
    | if_prefix BLOCK {
        char *elseLabel = currentScope->endLabel;
        exitScope();
        emit("LABEL", NULL, NULL, elseLabel);
        exitScope();
    }
    | if_prefix BLOCK {
        char *endIfLabel = currentScope->parent->endLabel;
        emit("JMP", NULL, NULL, endIfLabel);
    } ELSE {
        char *startOfElseLabel = currentScope->endLabel;
        emit("LABEL", NULL, NULL, startOfElseLabel);
        exitScope();
        enterScope();
    } BLOCK {
        exitScope();
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
    }
    
    | SWITCH '(' expr ')' '{' CASE_LIST '}' {}
    | {
        enterScope();
    } BLOCK {
        exitScope();
    }
    ;

CASE_LIST:
        CASE expr ':' stmt_list CASE_LIST
    | DEFAULT ':' stmt_list
    ;
    


%%

char* tempResult(void) {
    char buffer[20];
    sprintf(buffer, "t_%d", resultCounter++);
    return strdup(buffer);
}

char* createLabel(void) {
    char buffer[20];
    sprintf(buffer, "L_%d", labelsCounter++);
    return strdup(buffer);
}

void emit(const char *op, const char *arg1, const char *arg2, const char *result) {
    if (quadFile == NULL) {
        fprintf(stderr, "Error: quad file is not open\n");
        return;
    }
    fprintf(quadFile, "%s, %s, %s, %s\n", op, arg1 ? arg1 : "NULL", arg2 ? arg2 : "NULL", result ? result : "NULL");
    fflush(quadFile);
}

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
}

void enterScope(void) {
    symbolTable *newScope = createSymbolTable(currentScope);
    if (newScope == NULL) {
        fprintf(stderr, "Error: Failed to create new scope.\n");
        return;
    }
    currentScope = newScope;
}

void exitScope(void) {
    currentScope = currentScope->parent;
}

int main(void) {
    globalTable = createSymbolTable(NULL);

    if (globalTable == NULL) {
        fprintf(stderr, "Error: Failed to allocate global symbol table.\n");
        return 1;
    }
    currentScope = globalTable;
    stackInit(&loopStack);

    // open the file for writing quads
    quadFile = fopen(resultQuadFile, "w");
    if (quadFile == NULL) {
        fprintf(stderr, "Error opening quadruples file\n");
        return 1;
    }
    int parseStatus = yyparse();
    printSymbolTable(globalTable, 0);
    fclose(quadFile);
    return parseStatus;
}