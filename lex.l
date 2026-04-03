%{
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "y.tab.h"
void yyerror(char *);
%}

digit   [0-9]
letter  [a-zA-Z]

%%

/* keywords */
"const"    { return CONST; }
"int"      { 
    
    return INT; }
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


/* logical operators */
"||" { return OR; }
"&&" { return AND; }
"!"  { return NOT; }

/* relational operators */
">=" { return GE; }
"<=" { return LE; }
"==" { return EQ; }
"!=" { return NE; }

/* multi-character operators */ MCOP
"++" { return OAO; }
"--" { return OAO; }
"+=" { return TAO; }
"-=" { return TAO; }
"*=" { return TAO; }
"/=" { return TAO; }
"%=" { return TAO; }

/* literals */

{digit}+\.{digit}+ {
    yylval.fValue = atof(yytext);
    return FLOATING;
}

{digit}+ {
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

    if (yytext[len-1] != '"') {
        warning("improperly terminated string");
    }

    yylval.sValue = (char*)malloc(len);
    strncpy(yylval.sValue, yytext+1, len-2);
    yylval.sValue[len-2] = '\0';

    printf("found '%s'\n", yylval.sValue);
    return STRING_LITERAL;
}

/* identifiers */
{letter}({letter}|{digit})* {
    yylval.sValue = strdup(yytext);
    return IDENTIFIER;
}

/* operators & punctuation */
[-()+*/;{}.,<>=%] { return *yytext; }

/* whitespace */
[ \t\n]+ ;

/* error */
. { yyerror("Unknown character"); }

%%

int main() {
    yylex();
    return 0;
}