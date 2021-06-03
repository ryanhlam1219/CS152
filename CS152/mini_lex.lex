%{
    #include "y.tab.h"
    int currLine  =  1, currPos = 1;
%}

NUMBER                       [0-9]
LETTER                      [a-zA-Z]
IDENTIFIER                  ({LETTER}({LETTER}|{NUMBER}|"_")*({LETTER}|{NUMBER}))|{LETTER}
INVALID_CASE1               ({NUMBER}|"_")+{IDENTIFIER}
INVALID_CASE2               {IDENTIFIER}"_"+
INVALID_CASE3               {NUMBER}+{IDENTIFIER}+"_"+

%%

"function"	{currPos += yyleng; return FUNCTION;}
"beginparams"	{currPos += yyleng; return BEGIN_PARAMS; }
"endparams"	{currPos += yyleng; return END_PARAMS; }
"beginlocals"	{currPos += yyleng; return BEGIN_LOCALS;}
"endlocals"	{currPos += yyleng; return END_LOCALS;}
"beginbody"	{currPos += yyleng; return BEGIN_BODY;}
"endbody"	    {currPos += yyleng; return END_BODY; }
"integer"	    {currPos += yyleng; return INTEGER;}
"array"	    {currPos += yyleng; return ARRAY;}
"enum"        {currPos+= yyleng; return ENUM}
"of"	        {currPos += yyleng; return OF;}
"if"	        {currPos += yyleng; return IF;}
"then"	    {currPos += yyleng; return THEN;}
"endif"	    {currPos += yyleng; return ENDIF;}
"else"	    {currPos += yyleng; return ELSE;}
"while"	    {currPos += yyleng; return WHILE;}
"do"	        {currPos += yyleng; return DO;}
"beginloop"	{currPos += yyleng; return BEGINLOOP;}
"endloop"	    {currPos += yyleng; return ENDLOOP;}
"continue"	{currPos += yyleng; return CONTINUE;}
"read"	    {currPos += yyleng; return READ;}
"write"	    {currPos += yyleng; return WRITE;}
"and"	        {currPos += yyleng; return AND;}
"or"	        {currPos += yyleng; return OR;}
"not"	        {currPos += yyleng; return NOT;}
"true"	    {currPos += yyleng; return TRUE;}
"false"	    {currPos += yyleng; return FALSE;}
"return"      {currPos += yyleng; return RETURN;}

"-"   {currPos += yyleng; return SUB;}
"+"   {currPos += yyleng; return ADD;}
"*"   {currPos += yyleng; return MULT;}
"/"   {currPos += yyleng; return DIV;}
"%"   {currPos += yyleng; return MOD;}
"("   {currPos += yyleng; return L_PAREN;}
")"   {currPos += yyleng; return R_PAREN;}
"=="   {currPos += yyleng; return EQ;}
"<>"   {currPos += yyleng; return NEQ;}
"<"   {currPos += yyleng; return LT;}
">"   {currPos += yyleng; return GT;}
"<="   {currPos += yyleng; return LTE;}
">="   {currPos += yyleng; return GTE;}
";"   {currPos += yyleng; return SEMICOLON;}
":"   {currPos += yyleng; return COLON;}
","   {currPos += yyleng; return COMMA;}
"["   {currPos += yyleng; return L_SQUARE_BRACKET;}
"]"   {currPos += yyleng; return R_SQUARE_BRACKET;}
":="   {currPos += yyleng; return ASSIGN;}

{NUMBER}+                                       {currPos += yyleng; yylval.ival = atoi(yytext); return NUMBER;}
{IDENTIFIER}	                                {currPos += yyleng; yylval.identifier_value = strdup(yytext); return IDENTIFIER}
{INVALID_CASE1}                                 {printf("Error at line %d, column %d: invalid identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0);  }
{INVALID_CASE2}                                 {printf("Error at line %d, column %d: invalid identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext); exit(0); }
{INVALID_CASE3}                                 {printf("Error at line %d, column %d: invalid identifier \"%s\" must begin with a letter and cannot end with an underscore\n", currLine, currPos, yytext); exit(0); }
##.*                                            {currLine++; currPos = 1;}
[ \t]+                                           {currPos+= yyleng;}
"\n"                                            {currLine++; currPos = 1;}
.                                               {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%

int main(int argc, char ** argv){
   if(argc >= 2){
        yyin = fopen(argv[1], "r");
        if(yyin == NULL){
                yyin = stdin;
        }
   }else{
     //yylex();
     yyparse();
   }

   return 0;
}



