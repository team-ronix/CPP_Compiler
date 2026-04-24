%{
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "structs.h"
#include "y.tab.h"
void yyerror(char *);

int lineNumber = 1;
%}

digit   [0-9]
letter  [a-zA-Z]

%%

\n      { lineNumber++; }

"void"     { return VOID; }
"const"    { return CONST; }
"int"      { return INT; }
"float"    { return FLOAT; }
"bool"     {  return BOOL; }
"char"     { return CHAR; }
"string"   { return STRING; }
"print"    { return PRINT; }
"if"       { return IF; }
"else"     { return ELSE; }
"while"    { return WHILE; }
"for"      { return FOR; }
"switch"   { return SWITCH; }
"case"     { return CASE; }
"do"       { return DO; }
"break"    { return BREAK; }
"continue" { return CONTINUE; }
"return"   { return RETURN; }
"default"  { return DEFAULT; }


"||" { return OR; }
"&&" { return AND; }
"!"  { return NOT; }

">=" { return GE; }
"<=" { return LE; }
"==" { return EQ; }
"!=" { return NE; }

"++" { return INC; }
"--" { return DEC; }


\-?{digit}+\.{digit}+ {
    yylval.fValue = atof(yytext);
    return FLOATING;
}

\-?{digit}+ {
    yylval.iValue = atoi(yytext);
    return INTEGER;
}

"true" {
    yylval.bValue = 1;
    return BOOLEAN;
}

"false" {
    yylval.bValue = 0;
    return BOOLEAN;
}

\'(\\.|[^\\'])\' {
    if (yytext[1] == '\\') {
        switch (yytext[2]) {
            case 'n': yylval.cValue = '\n'; break;
            case 't': yylval.cValue = '\t'; break;
            case '\\': yylval.cValue = '\\'; break;
            default: yylval.cValue = yytext[2];
        }
    } else {
        yylval.cValue = yytext[1];
    }
    return CHARACTER;
}

\"[^"\n]*["\n] {
    int len = yyleng;

    yylval.sValue = (char*)malloc(len);
    strncpy(yylval.sValue, yytext+1, len-2);
    yylval.sValue[len-2] = '\0';
    return STRING_LITERAL;
}

{letter}({letter}|{digit})* {
    yylval.sValue = strdup(yytext);
    return IDENTIFIER;
}

"/*"([^*]|\*+[^*/])*\*+"/" {
    int i;
    for (i = 0; i < yyleng; i++) {
        if (yytext[i] == '\n') {
            lineNumber++;
        }
    }
}


"//".*   ;

[-()+*/;:{}.,<>=%] { return *yytext; }


[ \t\r]+ ;


. { yyerror("Unknown character"); }

%%
int yywrap(void) {
    return 1;
}