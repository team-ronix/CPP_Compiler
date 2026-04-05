%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    int iValue;
    float fValue;
    char cValue;
    char *sValue;
    int bValue;
}

%token <iValue> INTEGER
%token <fValue> FLOATING
%token <cValue> CHARACTER
%token <sValue> STRING_LITERAL
%token <sValue> IDENTIFIER
%token <bValue> BOOLEAN

%token INT FLOAT BOOL CHAR STRING
%token IF ELSE WHILE FOR SWITCH CASE DO BREAK CONTINUE RETURN
%token PRINT
%token OR AND NOT
%token GE LE EQ NE
%token INC DEC
%token CONST

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%left AND
%left OR
%nonassoc right NOT 
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

expr:
      IDENTIFIER
    | INTEGER
    | FLOATING
    | BOOLEAN
    | CHARACTER
    | STRING_LITERAL
    | '-' expr %prec UMINUS
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
    | '(' expr ')'
    | NOT expr
    | expr AND expr
    | expr OR expr
    ;

TYPE:
    INT
    | FLOAT
    | BOOL
    | CHAR
    | STRING
    | VOID
    ;

BLOCK_STMT_LIST:
      /* empty */
    |stmt_list
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
    | '=' expr
;   
    
CHAINED_DECLARATION:
    /* empty */
    | ',' IDENTIFIER ASSIGNMENT CHAINED_DECLARATION
;

stmt:
      ';'
    | expr ';'
    | PRINT '(' expr ')' ';'
    | TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';'
    | CONST TYPE IDENTIFIER ASSIGNMENT CHAINED_DECLARATION ';'
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
    return yyparse();
}