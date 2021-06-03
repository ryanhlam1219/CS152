%{
    #include <string.h> 
    #include <stdio.h>
    #include <stdlib.h>
    #include <vector>
    #include <map> 
    void yyerror(const char* msg);
    extern int currLine;
    extern int currPos;
    int num1 = 0;
    int num2 = 0;
    extern FILE *yyin;

    using namespace std;

    map<string,int> variables;
    map<string,int> functions_map;
    vector<string> reserved_words = {
        "FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS," "BEGIN_BODY", "END_BODY",
        "INTEGER", "ARRAY", "ENUM", "OF", "IF", "THEN", "ENDIF", "ELSE", 
        "WHILE", "DO", "BEGINLOOP", "ENDLOOP", "CONTINUE",
        "READ", "WRITE", "AND", "OR", "NOT", "TRUE", "FALSE", "RETURN",
        "SUB", "ADD", "MULT", "DIV", "MOD",
        "L_PAREN", "R_PAREN", 
        "EQ", "NEQ", "LT", "GT", "LTE", "GTE",
        "SEMICOLON", "COLON", "COMMA", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN",
        "NUMBER",
        "IDENTIFIER",
        "program", "functions", "function", "declaration", "declarations", "function_ident", "ident", "identifiers", "var", "vars",
        "bool_exp", "relation_and_exp", "relation_exp", "comp", "expression", "expressions", "multiplicative_expression", "term",
        "statements", "statement", "else_statement" 
    }
    
%}

%union{
    int ival;
    char* identifier_value;
    struct S {
        char* code;
    }stat;
    struct E {
        char*place;
        char*code;
        bool arr;
    } expr;
}

%error-verbose
%start program

%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY
%token INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE 
%token WHILE DO BEGINLOOP ENDLOOP CONTINUE
%token READ WRITE AND OR NOT TRUE FALSE RETURN
%token SUB ADD MULT DIV MOD
%token L_PAREN R_PAREN 
%token EQ NEQ LT GT LTE GTE
%token SEMICOLON COLON COMMA L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN

%type <ival> NUMBER
%type <identifier_value> IDENTIFIER
%type <E> program functions function declaration declarations ident identifiers var vars
%type <E> bool_exp relation_and_exp relation_exp comp expression expressions multiplicative_expression term
%type <S> statements statement

%%

program:
       %empty {
           string temp_main = "main";
           
            if(functions_map.find(tempMain) == functions_map.end()){
                char temp[128];
                snprintf(temp,128,"Declared program name as variable");
                yyerror(temp);
            }

       }
       | functions program {}
       ;

functions:
       %empty 
       {
           char empty[1] = "";
           $$.code = strdup(empty);
           $$.place = strdup(empty);
       }
       | function functions {}
       ;

function: 
        FUNCTION function_ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
        {
           string temp = "func "letter
           temp.append("\n");
           temp.append($2.code);
           temp.append($5.code);
           init_params = $5.code;
           int param_number = 0;

            while(init_params.find(".") != string::npos){
                size_t pos = init_params.find(".");
                init_params.replace(pos,1,"=");
                string param = ",$";
                param.append(to_string(param_number++));
                param.append("\n");
                init_params.replace(init_params.find("\n",pos),1,param);
            }

            temp.apped(init_params);
            temp.append($8.code);
            string stats($11.code);
            
            if(statements.find("continue") != string::npos)
                printf("ERROR: Continue outside loop in function %s\n", $2.place);
                
            temp.append(statements);
            temp.append("endfunc\n");
        }
        ;

ident: 
        IDENTIFIER {
            char empty[1] = "";
            $$.place = strdup($1);
            $$.code = strdup(empty);;
        }
        ;

function_ident:
        IDENTIFIER{
            char empty[1] = "";
            if (functions.find(string($1)) != functions.end()) {
                char temp[128];
                snprintf(temp, 128, "Redeclaration of function %s", $1);
                yyerror(temp);
            }

            else 
                functions.insert(pair<string,int>($1,0));
            
            $$.place = strdup($1);
            $$.code = strdup(empty);;
        }
        ;

declarations: 
        %empty{
            char empty[1] = ""
            $$.code = strdup(empty);
            $$.place = strdup(empty);
        }
        | declaration SEMICOLON declarations
		{
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty)
        }
        ;

declaration:     
        identifiers COLON INTEGER 
        {
            bool flag = true;
            string variables_placeholder($1.place);
            string temp;
            string variable;
            
            size_t prev_pos = 0;
            size_t pos = 0;
            bool reserved = false;
            while (flag) {

                pos = variables_placeholder.find("|", prev_pos);

                if (pos == string::npos) {
                    temp.append(". ");
                    variable = variables_placeholder.substr(prev_pos,pos);
                    temp.append(variable);
                    temp.append("\n");
                    flag = false;
                }

                else {
                    size_t len = pos - prev_pos;
                    temp.append(". ");
                    variable = variables_placeholder.substr(prev_pos, len);
                    temp.append(variable);
                    temp.append("\n");
                }
                
                for (unsigned int i = 0; i < reserved_words.size(); i++) {
                
                    if (reserved_words.at(i) == variable) 
                        reserved = true;
                
                } 
                
                if (variables.find(variable) != variables.end()) {
                    char temp[128];
                    snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
                    yyerror(temp);
                }

                else if (isReserved){
                    char temp[128];
                    snprintf(temp, 128, "Invalid declaration of reserved words %s", variable.c_str());
                    yyerror(temp);
                }

                else 
                    variables.insert(pair<string,int>(variable,0));
                
                prev_pos = pos + 1;
            }
            
            $$.code = strdup(temp.c_str());
            char empty[1] = "";
            $$.place = strdup(empty);
        }
        | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
		{
             if ($5 <= 0) {
                char temp[128];
                snprintf(temp, 128, "Array size can't be less than 1");
                yyerror(temp);
            }
            
            bool flag = true;
            string variables_placeholder($1.place);
            string temp;
            string variable;
            

            size_t prev_pos = 0;
            size_t pos = 0;
            while (flag) {
                pos = variables_placeholder.find("|", prev_pos);

                if (pos == string::npos) {
                    temp.append(".[] ");
                    variable = variables_placeholder.substr(prev_pos, pos);
                    temp.append(variable);
                    temp.append(", ");
                    temp.append(to_string($5));
                    temp.append("\n");
                    flag = false;
                }

                else {
                    size_t len = pos - prev_pos;
                    temp.append(".[] ");
                    variable = variables_placeholder.substr(prev_pos, len);
                    temp.append(variable);
                    temp.append(", ");
                    temp.append(to_string($5));
                    temp.append("\n");
                }
                
                if (variables.find(variable) != variables.end()) {
                    char temp[128];
                    snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
                    yyerror(temp);
                }

                else 
                    variables.insert(pair<string,int>(variable,$5));
                
                prev_pos = pos + 1;
            }
            
            char empty[1] = "";
            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty);
        }
        | identifiers COLON ENUM L_PAREN identifiers R_PAREN 
        {printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN");}
        ;

identifiers:     
        ident 
        {
            $$.place = strdup($1.place);
            $$.code = strdup(empty);
        }
        | ident COMMA identifiers
		{
            string temp;
            temp.append($1.place);
            temp.append("|");
            temp.append($3.place);
            
            $$.place = strdup(temp.c_str());
            char empty[1] = "";
            $$.code = strdup();
        }
        ;

statements:      
        statement SEMICOLON 
        {
            string temp;
            temp.append($1.code);
            $$.code = strdup(temp.c_str());
        }
        | statement SEMICOLON statements
        {
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            $$.code = strdup(temp.c_str());
        }
        ;

statement:
        var ASSIGN expression
        {
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            string intermed = $3.place;
            if ($1.array && $3.array) {
                intermed = newTemp();
                temp.append(". ");
                temp.append(intermed);
                temp.append("\n");
                temp.append("=[] ");
                temp.append(intermed);
                temp.append(", ");
                temp.append($3.place);
                temp.append("\n");
                temp.append("[]= ");
            }

            else if ($1.array) 
                temp.append("[]= ");
        
            else if ($3.array) 
                temp.append("=[] ");
            
            else 
                temp.append("= ");
            
            temp.append($1.place);
            temp.append(", ");
            temp.append(intermed);
            temp.append("\n");

            $$.code = strdup(temp.c_str());
        }   
        | IF bool_exp THEN statements else_statement ENDIF
        {
            string then_begin = newLabel();
            string after = newLabel();
            string temp;
            temp.append($2.code);
            temp.append("?:= ");
            temp.append(then_begin);
            temp.append(", ");
            temp.append($2.place);
            temp.append("\n");
            temp.append($5.code);
            temp.append(":= ");
            temp.append(after);
            temp.append("\n");
            temp.append(": ");
            temp.append(then_begin);
            temp.append("\n");
            temp.append($4.code);
            temp.append(": ");
            temp.append(after);
            temp.append("\n"); 
            $$.code = strdup(temp.c_str());
        }
        | WHILE bool_exp BEGINLOOP statements ENDLOOP
		{
            string temp;
            string begin_while = newLabel();
            string begin_loop = newLabel();
            string end_loop = newLabel();
            
            string stat = $4.code;
            string jump;
            jump.append(":= ");
            jump.append(begin_while);

            while (stat.find("continue") != string::npos) 
                stat.replace(stat.find("continue"), 8, jump);
            
            temp.append(": ");
            temp.append(begin_while);
            temp.append("\n");
            temp.append($2.code);
            temp.append("?:= ");
            temp.append(begin_loop);
            temp.append(", ");
            temp.append($2.place);
            temp.append("\n");
            temp.append(":= ");
            temp.append(end_loop);
            temp.append("\n");
            temp.append(": ");
            temp.append(begin_loop);
            temp.append("\n");
            temp.append(stat);
            temp.append(":= ");
            temp.append(begin_while);
            temp.append("\n");
            temp.append(": ");
            temp.append(end_loop);
            temp.append("\n");

            $$.code = strdup(temp.c_str());
        }
        | DO BEGINLOOP statements ENDLOOP WHILE bool_exp
		{
            string temp;
            string begin_loop = newLabel();
            string begin_while = newLabel();
            string stat = $3.code;
            string jump;
            jump.append(":= ");
            jump.append(begin_while);

            while (stat.find("continue") != string::npos) 
                stat.replace(stat.find("continue"), 8, jump);
            
            temp.append(": ");
            temp.append(begin_loop);
            temp.append("\n");
            temp.append(stat);
            temp.append(": ");
            temp.append(begin_while);
            temp.append("\n");
            temp.append($6.code);
            temp.append("?:= ");
            temp.append(begin_loop);
            temp.append(", ");
            temp.append($6.place);
            temp.append("\n");
            
            $$.code = strdup(temp.c_str());
        }
        | READ vars
		{
            string temp = $2.code;
            size_t pos = 0;

            do {
                pos = temp.find("|", pos);

                if (pos == string::npos)
                    break;

                temp.replace(pos, 1, "<");
            } while (true);

            $$.code = strdup(temp.c_str());
        }
        | WRITE vars
		{
            std::string temp = $2.code;
            size_t pos = 0;

            do {
                pos = temp.find("|", pos);

                if (pos == string::npos)
                    break;

                temp.replace(pos, 1, ">");
            } while (true);

            $$.code = strdup(temp.c_str());
        }
        | CONTINUE
		{
            string temp = "continue\n";
            $$.code = strdup(temp.c_str());
        }
        | RETURN expression
		{
            string temp;
            temp.append($2.code);
            temp.append("ret ");
            temp.append($2.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
        }
        ;

else_statement:   
    %empty
    {
        char empty[1] = "";
        $$.code = strdup(empty);
    }
    | ELSE Statements
    {
        $$.code = strdup($2.code);
    }
    ;

bool_exp:
        relation_and_exp 
        {
            $$.place = strdup($1.place);
            $$.code = strdup($1.code);
        }
        | bool_exp OR relation_and_exp 
        {
            string destination = newTemp();
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append(destination);
            temp.append("\n");
            temp.append("|| ");
            temp.append(dest);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
            $$.place = strdup(destination.c_str());
        }
        ;

relation_and_exp:	  
        relation_exp 
        {
            $$.place = strdup($1.place);
            $$.code = strdup($1.code);
        }
        | relation_and_exp AND relation_exp 
        {
            string destination = newTemp();
            string temp;

            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append(destination);
            temp.append("\n");
            
            temp.append("&& ");
            temp.append(destination);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            
            $$.code = strdup(temp.c_str());
            $$.place = strdup(destination.c_str());
        }
        ;

relation_exp:	  
        NOT relation_exp{
            string destination = newTemp();
            string temp;
            temp.append($2.code);
            temp.append(". ");
            temp.append(destination);
            temp.append("\n");
            temp.append("! ");
            temp.append(destination);
            temp.append(", ");
            temp.append($2.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
            $$.place = strdup(destination.c_str());
        }
        | expression comp expression 
        {
            string destination = newTemp();
            string temp;  
            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append(destination);
            temp.append("\n");
            temp.append($2.place);
            temp.append(destination);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
            $$.place = strdup(destination.c_str());
        }
		| TRUE 
        {
            char temp[2] = "1";
            $$.place = strdup(temp);
            $$.code = strdup(empty);
        }
		| FALSE 
        {
            char temp[2] = "0";
            $$.place = strdup(temp);
            $$.code = strdup(empty);
        }
		| L_PAREN bool_exp R_PAREN 
        {
              $$.place = strdup($2.place);
              $$.code = strdup($2.code);
        }
		;

comp:     
        EQ 
        {
            string temp = "== ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		| NEQ 
        {
            string temp = "!= ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		| LT 
        {
            string temp = "< ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		| GT 
        {
            string temp = "> ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		| LTE 
        {
            string temp = "<= ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		| GTE 
        {
            string temp = ">= ";
            $$.place = strdup(temp.c_str());
            $$.code = strdup(empty);
        }
		;

expression: 
        multiplicative_expression 
        {
            $$.code = strdup($1.code);
            $$.place = strdup($1.place);
        }
        | expression ADD multiplicative_expression 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append("+ ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
        }
        | expression SUB multiplicative_expression 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append("- ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
        }
        ;

multiplicative_expression:
        term 
        {
           $$.code = strdup($1.code);
           $$.place = strdup($1.place);
        }
        |  multiplicative_expression MULT term 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append($1.code);
            temp.append($3.code);
            temp.append("* ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
        }
        |  multiplicative_expression DIV term 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append($1.code);
            temp.append($3.code);
            temp.append("/ ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
        }
        |  multiplicative_expression MOD term 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append($1.code);
            temp.append($3.code);
            temp.append("% ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
        }
        ;

term:   
        var 
        {
            if ($$.array == true) {
                string temp;
                string intermed = newTemp();
                temp.append($1.code);
                temp.append(". ");
                temp.append(intermed);
                temp.append("\n");
                temp.append("=[] ");
                temp.append(intermed);
                temp.append(", ");
                temp.append($1.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(intermed.c_str());
                $$.array = false;
            }
            
            else {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
            }

        }
		| SUB var 
        {
            $$.place = strdup(newTemp().c_str());
            string temp;
            temp.append($2.code);
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");

            if ($2.array) {
                temp.append("=[] ");
                temp.append($$.place);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
            }

            else {
                temp.append("= ");
                temp.append($$.place);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
            }

            temp.append("* ");
            temp.append($$.place);
            temp.append(", ");
            temp.append($$.place);
            temp.append(", -1\n");
            
            $$.code = strdup(temp.c_str());
            $$.array = false;
        }
		| NUMBER {
            char empty[1] = "";
            $$.code = strdup(empty);
            $$.place = strdup(std::to_string($1).c_str());
        }
		| SUB NUMBER 
        {
            char empty[1] = "";
            string temp;
            temp.append("-");
            temp.append(std::to_string($2));
            $$.code = strdup(empty);
            $$.place = strdup(temp.c_str());
        }
		| L_PAREN expression R_PAREN 
        {
            $$.code = strdup($2.code);
            $$.place = strdup($2.place);
        }
		| SUB L_PAREN expression R_PAREN 
        {
            $$.place = strdup($3.place);
            string temp;
            temp.append($3.code);
            temp.append("* ");
            temp.append($3.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append(", -1\n");
            $$.code = strdup(temp.c_str());
        }
		| ident L_PAREN expressions R_PAREN 
        {
            if (functions.find(string($1.place)) == functions.end()) {
                char temp[128];
                snprintf(temp, 128, "Use of undeclared function %s", $1.place);
                yyerror(temp);
            }

            $$.place = strdup(newTemp().c_str());

            string temp;
            temp.append($3.code);
            temp.append(". ");
            temp.append($$.place);
            temp.append("\n");
            temp.append("call ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($$.place);
            temp.append("\n");
            
            $$.code = strdup(temp.c_str());
        }
		;

expressions:     
        %empty
        {
            char empty[1] = "";
            $$.code = strdup(empty);
            $$.place = strdup(empty);
        }
        | expression COMMA expressions
		{
            char empty[1] = "";
            string temp;
            temp.append($1.code);
            temp.append("param ");
            temp.append($1.place);
            temp.append("\n");
            temp.append($3.code);
            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty);
        }
        | expression
		{
            char empty[1] = "";
            string temp;
            temp.append($1.code);
            temp.append("param ");
            temp.append($1.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty)
        }
        ;

vars:   
        var 
        {
            char empty[1] = "";
            string temp;
            temp.append($1.code);
            if ($1.array)
                temp.append(".[]| ");
            else
                temp.append(".| ");
            
            temp.append($1.place);
            temp.append("\n");

            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty);
        }
        | var COMMA vars 
        {
            string temp;
            temp.append($1.code);
            if ($1.array)
                temp.append(".[]| ");
            else
                temp.append(".| ");
            
            temp.append($1.place);
            temp.append("\n");
            temp.append($3.code);
            
            $$.code = strdup(temp.c_str());
            $$.place = strdup(empty);
        }
        ;

var:    
        ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET
        {
            if (variables.find(string($1.place)) == variables.end()) {
                char temp[128];
                snprintf(temp, 128, "Use of undeclared variable %s", $1.place);
                yyerror(temp);
            }
            else if (variables.find(std::string($1.place))->second == 0) {
                char temp[128];
                snprintf(temp, 128, "Indexing a non-array variable %s", $1.place);
                yyerror(temp);
            }

            string temp;
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);

            $$.code = strdup($3.code);
            $$.place = strdup(temp.c_str());
            $$.array = true;
        }
        | ident
        {
            if (variables.find(string($1.place)) == variables.end()) {
                char temp[128];
                snprintf(temp, 128, "Use of undeclared variable %s", $1.place);
                yyerror(temp);
            }

            else if (variables.find(string($1.place))->second > 0) {
                char temp[128];
                snprintf(temp, 128, "Failed to provide index for array variable %s", $1.place);
                yyerror(temp);
            }
            char empty[1] = "";
            $$.code = strdup(empty);
            $$.place = strdup($1.place);
            $$.array = false;
        }
        ;

%%

std::string newLabel() {
  string temp = 'L' + to_string(num2++);
  return temp;
}

string newTemp() {
    string temp = "_t" + to_string(num1++);
    return temp;
}

void yyerror(const char *msg) {
    printf("** Line %d, position %d: %s \n", currLine, currPos, msg);
}	

