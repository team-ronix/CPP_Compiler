%{
#include "structs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "handlers/arithmetic.h"
#include "handlers/comparison.h"
#include "handlers/logical.h"
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
function *currentFunction = NULL;
valType funcType = noType;
bool isConstDecl = false;
int resultCounter = 0;
int labelsCounter = 0;
const char *resultQuadFile = "quads.txt";
const char *resultErrorFile = "errors.txt";
FILE *quadFile = NULL;
char* startLabel = NULL;
char* endLabel = NULL;
Stack loopStack;
Stack labelsStack;
Stack switchStack;





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

    argNode *argList;

}

%type <assign> ASSIGNMENT
%token <iValue> INTEGER
%token <fValue> FLOATING
%token <cValue> CHARACTER
%token <sValue> STRING_LITERAL
%token <sValue> IDENTIFIER
%token <bValue> BOOLEAN
%type <exprNode> expr
%type <exprNode> FUNCTION_CALL
%type <argList> ARG_LIST
%type <exprNode> for_cond_opt
%type <bValue> BLOCK_STMT_LIST BLOCK branch_stmt single_if if_else stmt unscoped_stmt unbraced_stmt
%token INT FLOAT BOOL CHAR STRING
%token IF ELSE FOR WHILE SWITCH CASE DO BREAK CONTINUE RETURN DEFAULT
%token PRINT
%token OR AND NOT
%token GE LE EQ NE
%token INC DEC
%token CONST
%token VOID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

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

TYPE:
    INT {currentType = typeInt;}
    | FLOAT {currentType = typeFloat;}
    | BOOL {currentType = typeBool;}
    | CHAR {currentType = typeChar;}
    | STRING {currentType = typeString;}
    | VOID {currentType = typeVoid;}
    ;

BLOCK_STMT_LIST:
            /* empty */ { $$ = 0; }
        | stmt BLOCK_STMT_LIST { $$ = $1 || $2; }
    ;

BLOCK:
        '{' BLOCK_STMT_LIST '}' { $$ = $2; }
    ;

branch_stmt:
            '{' { enterScope(); } BLOCK_STMT_LIST '}' { exitScope(); $$ = $3; }
        | single_if { $$ = $1; }
        | if_else { $$ = $1; }
        | { enterScope(); } unbraced_stmt { exitScope(); $$ = $2; }
    ;

PARAM_LIST:
    /* empty */
    | PARAMETER
    | PARAM_LIST ',' PARAMETER
    ;

PARAMETER:
    TYPE IDENTIFIER ASSIGNMENT {
        if(currentFunction != NULL) {
            varNode *param = findParameter(currentFunction, $2);
            if (param == NULL) {
                if ($3.hasValue) {
                    param = addVariableWithValue(currentScope, $2, currentType, false, $3.val);
                } else {
                    param = addVariable(currentScope, $2, currentType);
                }
                if (param == NULL) {
                    ERRORF("Failed to declare parameter '%s'.", $2);
                } else {
                    if (!addParameterToFunction(currentFunction, param)) {
                        ERRORF("Failed to add parameter '%s' to function.", $2);
                    } else {
                        param->variable.isInitialized = true;
                        emit("PARAM", $3.hasValue ? $3.place : NULL, NULL, $2);
                    }
                }
            }
        }
    }
    ;

FUNCTION:
    TYPE IDENTIFIER '('{
        function* func = findFunction(currentScope, $2);
        if (func != NULL) {
            ERRORF("Function '%s' already declared in this scope.", $2);
            // exit(1);
        } else {
            func = addFunction(currentScope, $2, currentType);
            if(func == NULL) {
                ERRORF("declaring function");
                // exit(1);
            } else {
                currentFunction = func;
                enterScope();
                func->scope = currentScope;
                currentScope->isFunctionScope = true;
                funcType = currentType;
                emit("FUNC_START", NULL, NULL, $2);
            }
        }        
    } PARAM_LIST ')' {
        if (currentFunction != NULL) {
            // printf("Declared function '%s' with return type %d and parameters: ", currentFunction->id, funcType);
            varNode *param = currentFunction->parameters;
            bool hasDefault = false;
            while (param != NULL) {
                if (hasDefault && !param->variable.isInitialized) {
                    ERRORF("Non-default parameter '%s' cannot follow default parameters.", param->variable.id);
                }
                if (param->variable.isInitialized) {
                    hasDefault = true;
                }
                param = param->paramNext;
            }
        }
    } BLOCK {
        if (currentFunction != NULL) {
            if (funcType != typeVoid && !$8) {
                WARNF("Function '%s' may reach end without returning a value.", currentFunction->id);
            }
            currentFunction = NULL;
            currentType = noType;
            funcType = noType;
            exitScope();
            emit("FUNC_END", NULL, NULL, $2);
        }
    }
  ;

ARG_LIST:
    /* empty */ { $$ = NULL; }
    | expr {
        argNode *arg = malloc(sizeof(argNode));
        arg->val = $1.val;
        arg->place = $1.place;
        arg->next = NULL;
        $$ = arg;
    }
    | ARG_LIST ',' expr {
        argNode *arg = malloc(sizeof(argNode));
        arg->val = $3.val;
        arg->place = $3.place;
        arg->next = NULL;

        argNode *current = $1;
        if (current == NULL) {
            $$ = arg;
        } else {
            while (current->next != NULL) {
                current = current->next;
            }
            current->next = arg;
            $$ = $1;
        }
    }
;

FUNCTION_CALL:
    IDENTIFIER '(' ARG_LIST ')' {
        $$.place = strdup("INVALID_CALL");
        $$.val.type = noType;
        $$.val.value.iValue = 0;

        function *func = findFunction(currentScope, $1);
        if (func == NULL) {
            ERRORF("Function '%s' not declared.", $1);
        } else {
            bool callHasErrors = false;
            varNode *params = func->parameters;
            argNode *args = $3;
            while (params != NULL) {
                if (args != NULL) {
                    canConvertResult res = canConvert(args->val.type, params->variable.type);
                    if (!res.canConvert) {
                        ERRORF("Argument type mismatch in function '%s' call. Expected type %d but got type %d.", $1, params->variable.type, args->val.type);
                        callHasErrors = true;
                        break;
                    } else {
                        emit("ARG", args->place, NULL, NULL);
                    }
                    args = args->next;
                } else {
                    if (params->variable.isInitialized) {
                        // Emit default value - convert to string representation
                        char defaultVal[50];
                        switch (params->variable.type) {
                            case typeInt:
                                sprintf(defaultVal, "%d", params->variable.value.iValue);
                                break;
                            case typeFloat:
                                sprintf(defaultVal, "%f", params->variable.value.fValue);
                                break;
                            case typeBool:
                                sprintf(defaultVal, "%d", params->variable.value.bValue);
                                break;
                            case typeChar:
                                sprintf(defaultVal, "'%c'", params->variable.value.cValue);
                                break;
                            case typeString:
                                sprintf(defaultVal, "\"%s\"", params->variable.value.sValue);
                                break;
                            default:
                                strcpy(defaultVal, "0");
                        }
                        emit("ARG", strdup(defaultVal), NULL, NULL);
                    } else {
                        ERRORF("Too few arguments in function '%s' call. Missing argument of type %d.", $1, params->variable.type);
                        callHasErrors = true;
                        break;
                    }
                }
                params = params->paramNext;
            }

            if (args != NULL) {
                ERRORF("Function '%s' called with too many arguments.", $1);
                callHasErrors = true;
            }

            // Only emit CALL if there were no validation errors
            if (!callHasErrors) {
                if (func->returnType == typeVoid) {
                    $$.place = strdup("VOID_CALL");
                } else {
                    $$.place = tempResult();
                }
                $$.val.type = func->returnType;
                $$.val.value.iValue = 0;
                emit("CALL", $1, NULL, func->returnType == typeVoid ? NULL : $$.place);
            }
        }
    }
;


FOR_INIT:
    TYPE IDENTIFIER '=' expr {
        if(isInCurrentScope(currentScope, $2)) {
            ERRORF("Variable '%s' already declared in this scope.", $2);
        } else {
            emit("DECL", $4.place, NULL, $2);
            addVariableWithValue(currentScope, $2, currentType, false, $4.val);
        }
        currentType = noType;
    }
    | IDENTIFIER '=' expr {
        varNode *var = findVariable(currentScope, $1);
        if(!var) {
            ERRORF("Variable '%s' you can't assign value to variable not declared before", $1);
        } else {
            if(!editValue(currentScope, $1, &$3.val)) {
                ERRORF("Failed to assign value to variable '%s'.", $1);
            } else {
                emit("=", $3.place, NULL, $1);
                var->variable.isInitialized = true;
            }
        }
    }
    | /* empty */
;

for_cond_opt:
      /* empty */ {
        valNode node;
        node.type = typeBool;
        node.value.bValue = true;
        $$.place = strdup("true");
        $$.val = node;
      }
    | expr {
        $$ = $1;
    }
;

expr_opt:
      /* empty */
    | IDENTIFIER INC {
        handleIncDec(currentScope, $1, "INC");
    }
    | IDENTIFIER DEC {
        handleIncDec(currentScope, $1, "DEC");
    }
    | IDENTIFIER '=' expr {
        varNode *var = findVariable(currentScope, $1);
        if(!var) {
            ERRORF("Variable '%s' you can't assign value to variable not declared before", $1);
        } else {
            if(!editValue(currentScope, $1, &$3.val)) {
                ERRORF("Failed to assign value to variable '%s'.", $1);
            }else {
                emit("=", $3.place, NULL, $1);
                var->variable.isInitialized = true;
            }
        }
    }
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
        if(isInCurrentScope(currentScope, $2)) {
            ERRORF("Variable '%s' already declared in this scope.", $2);
            // exit(1);
        } else {
            if($3.hasValue) {
                // printf("Declaring variable '%s' with initial value.\n", $2);
                valNode val = $3.val;
                if(val.type != currentType) {
                    // check if we can do implicit conversion from int to float or char to int, etc.
                    canConvertResult convRes = canConvert(val.type, currentType);
                    if(convRes.canConvert) {
                        val = convertValue(val, currentType);
                    } else {
                        ERRORF("Type mismatch for variable '%s'. Expected type %d but got type %d.", $2, currentType, val.type);
                        // exit(1);
                    }
                }
                emit("DECL", $3.place, NULL, $2);
                addVariableWithValue(currentScope, $2, currentType, false, $3.val);
            }
            else {
                if(isConstDecl) {
                    ERRORF("Constant variable '%s' must be initialized.", $2);
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
    FUNCTION_CALL {
        $$ = $1;
    }
    |
    IDENTIFIER { 
        varNode *var = findVariable(currentScope, $1);
        if (var == NULL) {
            ERRORF("Variable '%s' not declared.", $1);
            // // exit(1);
        } else {
            if (!var->variable.isInitialized) {
                WARNF("Variable '%s' is used before initialization.", $1);
                // // exit(1);
            }
            var->variable.isUsed = true;
            char buffer[20];
            sprintf(buffer, "%s", $1);
            $$.place = strdup(buffer);
            $$.val = varToValNode(var);
        }
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
            ERRORF("Unary '-' operator requires numeric operand.");
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
        exprResult res = logicalNotOperation(&$2.val);
        if(!res.error) {
            emit("NOT", $2.place, NULL, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr AND expr {
        exprResult res = logicalBinaryOperation(&$1.val, &$3.val, "AND");
        if(!res.error) {
            emit("AND", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    | expr OR expr {
        exprResult res = logicalBinaryOperation(&$1.val, &$3.val, "OR");
        if(!res.error) {
            emit("OR", $1.place, $3.place, res.place);
            $$.place = res.place;
            $$.val = res.value;
        }
    }
    ;

CONST_TYPE:
    CONST {isConstDecl = true;}
    ;

if_prefix:
    IF '(' expr ')' {
        IfLabelStorage *labels = malloc(sizeof(IfLabelStorage));
        labels->elseLabel = createLabel();
        labels->endLabel  = createLabel();
        stackPush(&labelsStack, labels);
        emit("IF_FALSE", $3.place, NULL, labels->elseLabel);
    }
    ;

single_if: if_prefix branch_stmt %prec LOWER_THAN_ELSE {
        IfLabelStorage *labels = (IfLabelStorage *)stackPop(&labelsStack);
        emit("LABEL", NULL, NULL, labels->elseLabel);
        free(labels);
                $$ = 0;
    }
    ;
if_else: if_prefix branch_stmt ELSE {
        IfLabelStorage *labels = (IfLabelStorage *)stackPeek(&labelsStack);
        emit("JMP",   NULL, NULL, labels->endLabel);
        emit("LABEL", NULL, NULL, labels->elseLabel);
                $<bValue>$ = $2;
    } branch_stmt {
        IfLabelStorage *labels = (IfLabelStorage *)stackPop(&labelsStack);
        emit("LABEL", NULL, NULL, labels->endLabel);
        free(labels);
                $$ = $<bValue>4 && $5;
    }
    ;
    
stmt:
            unbraced_stmt { $$ = $1; }
        | '{' { enterScope(); } BLOCK_STMT_LIST '}' { exitScope(); $$ = $3; }
        | single_if { $$ = $1; }
        | if_else { $$ = $1; }
    ;

unscoped_stmt:
            '{' BLOCK_STMT_LIST '}' { $$ = $2; }
        | single_if { $$ = $1; }
        | if_else { $$ = $1; }
        | unbraced_stmt { $$ = $1; }
    ;

switch_prefix:
    SWITCH '(' expr ')' {
        enterScope();
        currentScope->starLabel = NULL;
        currentScope->endLabel = createLabel();
        currentScope->isLoopScope = true;

        SwitchStorage *sw = malloc(sizeof(SwitchStorage));
        sw->switchExpr = strdup($3.place);
        sw->matchedVar = tempResult();
        
        emit("=", "false", NULL, sw->matchedVar);
        
        stackPush(&switchStack, sw);
    }
    ;

unbraced_stmt:
            ';' { $$ = 0; }
        | expr ';' { $$ = 0; }
        | PRINT '(' expr ')' ';' { 
            emit("PRINT", $3.place, NULL, NULL);
            $$ = 0;
         }
        | TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
            bool hasError = false;
            if(isInCurrentScope(currentScope, $2)) {
                ERRORF("Variable '%s' already declared in this scope.", $2);
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
                    ERRORF("Type mismatch for variable '%s'. Expected type %d but got type %d.", $2, currentType, val.type);
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
        $$ = 0;
    }
    | CONST_TYPE TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';' {
        valNode val = $4.val;
        bool hasError = false;

        if(isInCurrentScope(currentScope, $3)) {
            ERRORF("Variable '%s' already declared in this scope.", $3);
            // exit(1);
            hasError = true;
        }
        if(!$4.hasValue && hasError == false) {
            ERRORF("Constant variable '%s' must be initialized.", $3);
            // exit(1);
            hasError = true;
        }
        if(val.type != currentType && hasError == false) {
            ERRORF("Type mismatch for variable '%s'. Expected type %d but got type %d.", $3, currentType, val.type);
            hasError = true;
        }
        if (!hasError) {
            // printf("Declaring constant variable '%s' with initial value.\n", $3);
            addVariableWithValue(currentScope, $3, currentType, true, $4.val); 
            emit("CONST", $4.place, NULL, $3);
            isConstDecl = false;
            currentType = noType;
        }  
        $$ = 0;
    }
    | IDENTIFIER '=' expr ';' {
        varNode *var = findVariable(currentScope, $1);
        if(!var) {
            ERRORF("Variable '%s' you can't assign value to variable not declared before", $1);
            // exit(1);
        } else {
            if(!editValue(currentScope, $1, &$3.val)) {
                ERRORF("Failed to assign value to variable '%s'.", $1);
                // exit(1);
            }else {
                emit("=", $3.place, NULL, $1);
                var->variable.isInitialized = true;
            }
        }
        $$ = 0;
    }
    | IDENTIFIER INC ';' {
        handleIncDec(currentScope, $1, "INC");
        $$ = 0;
    }
    | IDENTIFIER DEC ';' {
        handleIncDec(currentScope, $1, "DEC");
        $$ = 0;
    }
    | BREAK ';' {
        // TODO check for switch case as well
        symbolTable *loopScope = findNearestLoopScope(currentScope);
        if (loopScope == NULL) {
            ERRORF("'break' statement not within a loop.");
        } else {
            emit("JMP_BREAK", NULL, NULL, loopScope->endLabel);
        }
        $$ = 0;
    }
    | CONTINUE ';' {
        symbolTable *loopScope = findNearestLoopScope(currentScope);
        if (loopScope == NULL) {
            ERRORF("'continue' statement not within a loop.");
        } else {
            emit("JMP_CONTINUE", NULL, NULL, loopScope->starLabel);
        }
        $$ = 0;
    }
    | RETURN expr ';' {
        if (currentFunction == NULL) {
            ERRORF("'return' statement not within a function.");
            // exit(1);
        } else {
            if (currentFunction->returnType == typeVoid) {
                ERRORF("'return' statement with a value in a void function.");
                // exit(1);
            }
            canConvertResult res = canConvert($2.val.type, funcType);
            if (res.canConvert) {
                emit("RETURN", $2.place, NULL, NULL);
            } else {
                ERRORF("Return type mismatch. Expected type %d but got type %d.", funcType, $2.val.type);
            }
        }
        $$ = 1;
    }
    | DO {
        enterScope();
        currentScope->starLabel = createLabel();
        currentScope->endLabel = createLabel();
        currentScope->isLoopScope = true;
        emit("LABEL", NULL, NULL, currentScope->starLabel);
    } unscoped_stmt WHILE '(' expr ')'{
        emit("IF_FALSE", $6.place, NULL, currentScope->endLabel);
    } ';' {
        emit("JMP", NULL, NULL, currentScope->starLabel);
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
        $$ = 0;
    }
    | FOR '(' {
        enterScope();
    } FOR_INIT ';' {
        char *l_start = createLabel();
        emit("LABEL", NULL, NULL, l_start);
        $<sValue>$ = l_start;
    } for_cond_opt ';' {
        char *l_body = createLabel();
        char *l_end = createLabel();
        char *l_inc = createLabel();
        
        currentScope->isLoopScope = true;
        currentScope->starLabel = l_inc;
        currentScope->endLabel = l_end;
        
        emit("IF_FALSE", $7.place, NULL, l_end);
        emit("JMP", NULL, NULL, l_body);
        emit("LABEL", NULL, NULL, l_inc);
        
        IfLabelStorage *forLabels = malloc(sizeof(IfLabelStorage));
        forLabels->elseLabel = l_body;
        forLabels->endLabel = $<sValue>6;
        $<sValue>$ = (char *)forLabels;
    } expr_opt ')' {
        IfLabelStorage *forLabels = (IfLabelStorage *)$<sValue>9;
        emit("JMP", NULL, NULL, forLabels->endLabel);
        emit("LABEL", NULL, NULL, forLabels->elseLabel);
        $<sValue>$ = (char *)forLabels;
    } unscoped_stmt {
        emit("JMP", NULL, NULL, currentScope->starLabel);
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        
        IfLabelStorage *forLabels = (IfLabelStorage *)$<sValue>12;
        free(forLabels);
        exitScope();
        $$ = 0;
    }
    | WHILE '(' {
        enterScope();
        currentScope->starLabel = createLabel();
        currentScope->endLabel = createLabel();
        currentScope->isLoopScope = true;
        emit("LABEL", NULL, NULL, currentScope->starLabel);
    } expr ')' {
        emit("IF_FALSE", $4.place, NULL, currentScope->endLabel);
    } unscoped_stmt {
        emit("JMP", NULL, NULL, currentScope->starLabel);
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
        $$ = 0;
    }
    
    | switch_prefix '{' CASE_LIST '}' {
        emit("LABEL", NULL, NULL, currentScope->endLabel);
        exitScope();
        
        SwitchStorage *sw = (SwitchStorage *)stackPop(&switchStack);
        free(sw->switchExpr);
        free(sw);
        $$ = 0;
    }
    ;

CASE_LIST:
      CASE_ITEM CASE_LIST
    | DEFAULT_ITEM
    | /* empty */
    ;

CASE_ITEM:
    CASE expr ':' {
        SwitchStorage *sw = (SwitchStorage *)stackPeek(&switchStack);
        char *l_cond_test = createLabel();
        char *l_body      = createLabel();
        char *l_next_case = createLabel();
        
        // If already matched, jump directly to body
        emit("IF_FALSE", sw->matchedVar, NULL, l_cond_test);
        emit("JMP", NULL, NULL, l_body);
        
        // Label for condition test
        emit("LABEL", NULL, NULL, l_cond_test);
        char *cmpRes = tempResult();
        emit("EQ", sw->switchExpr, $2.place, cmpRes);
        emit("IF_FALSE", cmpRes, NULL, l_next_case);
        
        // Cond matched! Set flag
        emit("=", "true", NULL, sw->matchedVar);
        
        emit("LABEL", NULL, NULL, l_body);
        $<sValue>$ = l_next_case;
    } BLOCK_STMT_LIST {
        emit("LABEL", NULL, NULL, $<sValue>4);
    }
    ;

DEFAULT_ITEM:
    DEFAULT ':' BLOCK_STMT_LIST
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
        ERRORF("quad file is not open");
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
        ERRORF("Failed to create new scope.");
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
        ERRORF("Failed to allocate global symbol table.");
        return 1;
    }
    currentScope = globalTable;
    stackInit(&loopStack);
    stackInit(&labelsStack);
    stackInit(&switchStack);

    // open the file for writing quads
    quadFile = fopen(resultQuadFile, "w");
    if (quadFile == NULL) {
        fprintf(stderr, "Error opening quadruples file\n");
        return 1;
    }
    
    if (!initDiagnostics(resultErrorFile)) {
        fprintf(stderr, "Error opening error file\n");
        return 1;
    }
    int parseStatus = yyparse();
    printSymbolTable(globalTable, 0);
    closeDiagnostics();
    fclose(quadFile);
    return parseStatus;
}