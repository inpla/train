%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sched.h>

  //#include "timer.h" //#include <time.h>
#include "linenoise/linenoise.h"
  
#include "ast.h"
  //#include "id_table.h"
  //#include "name_table.h"
  //#include "name_table.h"
  //#include "mytype.h"
  //#include "inpla.h"

#include "config.h"  



#define VERSION "0.2.1 (dev)"
#define BUILT_DATE  "14 Feb 2024"
  

 
// ---------------------------------------------------------------
// For parsing
// ---------------------------------------------------------------
int exec(Ast *st);
int destroy(void);




 
// ---------------------------------------------------------------
// For command history
// ---------------------------------------------------------------
//#define YYDEBUG 1
extern FILE *yyin;
extern int yylex();
int yyerror();
#define YY_NO_INPUT
extern int yylineno, yycolumn;

 
// For error message when nested source files are specified.
#define MY_YYLINENO 
#ifdef MY_YYLINENO
 typedef struct InfoLinenoType_tag {
   char *fname;
   int yylineno;
   struct InfoLinenoType_tag *next;
 } InfoLinenoType;
static InfoLinenoType *InfoLineno;

#define InfoLineno_Init() InfoLineno = NULL;

void InfoLineno_Push(char *fname, int lineno) {
  InfoLinenoType *aInfo;
  aInfo = (InfoLinenoType *)malloc(sizeof(InfoLinenoType));
  if (aInfo == NULL) {
    fprintf(stdout, "[InfoLineno]Malloc error\n");
    exit(1);
  }
  aInfo->next = InfoLineno;
  aInfo->yylineno = lineno+1;
  aInfo->fname = strdup(fname);

  InfoLineno = aInfo;
}

void InfoLineno_Free() {
  InfoLinenoType *aInfo;
  free(InfoLineno->fname);
  aInfo = InfoLineno;
  InfoLineno = InfoLineno->next;
  free(aInfo);
}

void InfoLineno_AllDestroy() {
  //  InfoLinenoType *aInfo;
  while (InfoLineno != NULL) {
    InfoLineno_Free();
  }
}

#endif
// ---------------------------------------------------------------

 

extern void pushFP(FILE *fp);
extern int popFP();


// Messages from yyerror will be stored here.
// This works to prevent puting the message. 
static char *Errormsg = NULL;


%}
%union{
  long longval;
  char *chval;
  Ast *ast;
}



%token <chval> NAME AGENT ALPHA_NUMERAL
%token <longval> INT_LITERAL
%token <chval> STRING_LITERAL
%token COLON

%token ANNOTATE_L ANNOTATE_R

%token NOT AND EQ OR NE GT GE LT LE
%token ADD SUB MUL DIV MOD INT LET IN IF THEN ELSE ANY WHERE
%token END_OF_FILE USE MAIN


%type <ast>
fundef
fundef_body
fundef_constr


attr_declaration
attr_name
attr_name_sequence

body

if_sentence if_compound

term
term_let
term_opcons
term_mklist
term_funapp
term_atom


name_sequence
term_sequence_twomore

attr_expr
attr_expr_body
attr_expr_sequence

expr additive_expr equational_expr logical_expr relational_expr unary_expr
multiplicative_expr primary_expr




//%type <chval> term_symbol


 //%right ':'


// For error message information
%define parse.error verbose
%locations




%%
s     
: error ';' { 
  yyclearin;
  yyerrok; 
  puts(Errormsg);
  free(Errormsg);
  ast_heapReInit();
  if (yyin == stdin) yylineno=0; yycolumn=1;
  //  YYACCEPT;
  YYABORT;
}
| ';' { 
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}

| fundef ';'
{
  exec($1);

  puts(";");
  fflush(stdout);
  
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}

| fundef STRING_LITERAL ';'
{
  exec($1);

  printf(",\n    %s", $2);
  puts(";");
  fflush(stdout);
  
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}


| STRING_LITERAL
{
  printf("%s;\n", $1);
  fflush(stdout);
  
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}

| body ';'
{
  exec($1);

  puts(";");
  fflush(stdout);
  
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}




| command {
  if (yyin == stdin) yylineno=0; yycolumn=1;
  YYACCEPT;
}
;



command
: ':' NAME
{
  if (!(strcmp($2, "quit"))) {
    destroy(); exit(0);
    
  } else if (!(strcmp($2, "q"))) {
    destroy(); exit(0);    

  } else {
    fprintf(stderr, "ERROR: No operation for the given command.");
  }
}
| ':' USE
{
  printf("USE\n");
}

| error END_OF_FILE {}
| END_OF_FILE {
  if (!popFP()) {
    destroy(); exit(1);
  }
#ifdef MY_YYLINENO
  yylineno = InfoLineno->yylineno;
  InfoLineno_Free();
  destroy();
#endif  
}
;





// (AST_RULE
//      [foo_sym_agent, const_agent, params1, params2, ...]
//      (AST_BUNDLE [term1, term2,...] NULL)
// )


fundef
: NAME fundef_constr '=' fundef_body
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($2, NULL)),
		   $4);
}
//
| NAME '(' fundef_constr ',' name_sequence ')' '=' fundef_body
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($3, $5)),
		   $8);

}
//
// attributes
//
| NAME attr_declaration fundef_constr '=' fundef_body
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($3, $2)),
		   $5);
}
//
| NAME attr_declaration '(' fundef_constr ',' name_sequence ')' '=' fundef_body
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($4,
					     ast_addLast($2,$6))),
		   $9);
}
;




// A constructor term in a function definition declaration
fundef_constr
// ex. Z
: AGENT 
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
//
// ex2. S x
| AGENT NAME 
{ $$=ast_makeAST(AST_AGENT,
		 ast_makeSymbol($1),
		 ast_makeList1(ast_makeSymbol($2))); }

// ex3. S(x,y,...)
| AGENT '(' name_sequence ')'
{ $$=ast_makeAST(AST_AGENT,
		 ast_makeSymbol($1),
		 $3); }

// ex4. x:y
| NAME ':' NAME
{ $$=ast_makeAST(AST_OPCONS, NULL,
		 ast_makeList2(
			       ast_makeSymbol($1),
			       ast_makeSymbol($3)));
}

// ex5. []
| '[' ']'
{ $$=ast_makeAST(AST_NIL, NULL, NULL);
}



//
//
// attribute
| AGENT attr_declaration
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), $2); }
//
/*
| '(' AGENT attr_declaration ')'
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($2), $3); }
//
| '(' AGENT attr_declaration name_sequence ')'
{ $$=ast_makeAST(AST_AGENT,
		 ast_makeSymbol($2),
		 ast_addLast($3,$4)); }
*/
//
//
| '(' fundef_constr ')'
{ $$ = $2; }

;



fundef_body
: term
| if_sentence;






attr_declaration
: '.' attr_name { $$ = ast_makeList1($2); }
| '.' '(' attr_name_sequence ')' { $$ = $3; }
;


attr_name
: NAME { $$ = ast_makeAST(AST_INTVAR, ast_makeSymbol($1), NULL); }
;

attr_name_sequence
: attr_name { $$ = ast_makeList1($1); }
| attr_name_sequence ',' attr_name { $$ = ast_addLast($1, $3); }
;




body
// (AST_BODY term NULL)
: MAIN '=' term  { $$ = ast_makeAST(AST_BODY, $3, NULL); }
| LET '(' ')' '=' term
{
  $$ = ast_makeAST(AST_BODY, $5, NULL);
}
; 




term
: '(' term_sequence_twomore ')'  // e1, e2 => (LIST e1 (LIST e2 NULL))
{ $$ = $2; }
| term_let
;




term_let
//(LET (LD (SYM_LIST x1 x2 x3) TERM) TERM)
: LET NAME '=' term IN term
{ $$ = ast_makeAST(AST_LET,
		   ast_makeAST(AST_LD, ast_makeList1(ast_makeSymbol($2)), $4),
		   $6);
}
| LET '(' name_sequence ')' '=' term IN term
{ $$ = ast_makeAST(AST_LET,
		   ast_makeAST(AST_LD, $3, $6),
		   $8);
}
| term_funapp
;



term_funapp
: NAME term_funapp
{  
  $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), ast_makeList1($2));
}
| NAME '(' term_sequence_twomore ')'
{  
  $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), $3);
}
| NAME attr_expr term_funapp
{
  // NAME attr t1  ==> NAME [t1, attr]
  $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), ast_makeCons($3, $2));
}
| NAME attr_expr '(' term_sequence_twomore ')'
{
  // NAME attr [t1,t2,...]  ==> NAME [t1, attr, t2, ...]
  // This is because t1 must be the constructor for NAME.
  { Ast *t1, *t2, *newlist;
    t1 = $4->left;
    t2 = $4->right;
    newlist = ast_makeCons($2, t2);
    newlist = ast_makeCons(t1, newlist);
  
    //$$=ast_makeAST(AST_NAME, ast_makeSymbol($1), ast_addLast($2,$3));
    $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), newlist);
  }
}
| term_opcons
;



term_opcons
: term_mklist ':' term_funapp
{
  $$ = ast_makeAST(AST_OPCONS, NULL, ast_makeList2($1, $3));
}
| term_mklist
;


term_mklist
: '[' ']' { $$ = ast_makeAST(AST_NIL, NULL, NULL); }
| '[' term ']'
{ $$ = ast_makeAST(AST_MKLIST,
		   NULL,
		   ast_paramToCons(ast_makeList1($2)));
}
| '[' term_sequence_twomore ']'
{ $$ = ast_makeAST(AST_MKLIST,
		   NULL,
		   ast_paramToCons($2));
}
| term_atom
;







term_atom
: AGENT
{ 
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL);
}
| AGENT term_atom
{  
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), ast_makeList1($2));
}
| AGENT '(' term_sequence_twomore ')'
{  
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), $3);
}
| NAME
{ 
  $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), NULL);
}
//
// with attr_expr
| AGENT attr_expr
{
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), $2);
}
| AGENT attr_expr term_atom
{
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), ast_addLast($2,$3));
}
| AGENT attr_expr '(' term_sequence_twomore ')'
{
  $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), ast_addLast($2,$4));
}
| NAME attr_expr
{
  $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), $2);
}

| '(' term ')' { $$ = $2; }
;


term_sequence_twomore
: term ',' term { $$=ast_makeList2($1, $3); }
| term_sequence_twomore ',' term
{ $$= ast_addLast($1, $3);
}
;

name_sequence
: NAME { $$=ast_makeList1(ast_makeSymbol($1)); }
| name_sequence ',' NAME
{ $$= ast_addLast($1, ast_makeSymbol($3));
}
;





attr_expr
: '.' attr_expr_body { $$ = $2; }
;

attr_expr_body
: expr { $$ = ast_makeList1($1); }
| '(' expr ',' attr_expr_sequence ')' { $$ = ast_makeCons($2,$4); }
;

attr_expr_sequence
: expr { $$ = ast_makeList1($1); }
| attr_expr_sequence ',' expr { $$ = ast_addLast($1, $3); }
;


expr
: equational_expr
;

equational_expr
: logical_expr
| equational_expr EQ logical_expr { $$ = ast_makeAST(AST_EQ, $1, $3); }
| equational_expr NE logical_expr { $$ = ast_makeAST(AST_NE, $1, $3); }

logical_expr
: relational_expr
| NOT relational_expr { $$ = ast_makeAST(AST_NOT, $2, NULL); }
| logical_expr AND relational_expr { $$ = ast_makeAST(AST_AND, $1, $3); }
| logical_expr OR relational_expr { $$ = ast_makeAST(AST_OR, $1, $3); }
;

relational_expr
: additive_expr
| relational_expr LT additive_expr { $$ = ast_makeAST(AST_LT, $1, $3); }
| relational_expr LE additive_expr { $$ = ast_makeAST(AST_LE, $1, $3); }
| relational_expr GT additive_expr { $$ = ast_makeAST(AST_LT, $3, $1); }
| relational_expr GE additive_expr { $$ = ast_makeAST(AST_LE, $3, $1); }
;

additive_expr
: multiplicative_expr
| additive_expr ADD multiplicative_expr { $$ = ast_makeAST(AST_PLUS, $1, $3); }
| additive_expr SUB multiplicative_expr { $$ = ast_makeAST(AST_SUB, $1, $3); }
;

multiplicative_expr
: unary_expr
| multiplicative_expr MUL primary_expr { $$ = ast_makeAST(AST_MUL, $1, $3); }
| multiplicative_expr DIV primary_expr { $$ = ast_makeAST(AST_DIV, $1, $3); }
| multiplicative_expr MOD primary_expr { $$ = ast_makeAST(AST_MOD, $1, $3); }


unary_expr
: primary_expr
| SUB primary_expr { $$ = ast_makeAST(AST_UNM, $2, NULL); }
;

primary_expr
:NAME {$$=ast_makeAST(AST_NAME, ast_makeSymbol($1), NULL);}
| INT_LITERAL { $$ = ast_makeInt($1); }
//| AGENT { $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
| '(' expr ')' { $$ = $2; }
;





// if_sentence
if_sentence
: IF expr THEN if_compound ELSE if_compound
{ $$ = ast_makeAST(AST_IF, $2, ast_makeAST(AST_THEN_ELSE, $4, $6));}
;


if_compound
: if_sentence
| term
;










%%



int yyerror(char *s) {
  extern char *yytext;
  char msg[256];

  
#ifdef MY_YYLINENO
  if (InfoLineno != NULL) {
    sprintf(msg, "%s:%d:%d: %s near token `%s'.\n", 
	    InfoLineno->fname, yylineno+1, yycolumn, s, yytext);
  } else {
    sprintf(msg, "%d:%d: %s near token `%s'.\n", 
	    yylineno, yycolumn, s, yytext);
  }
#else
  sprintf(msg, "%d: %s near token `%s'.\n", yylineno, s, yytext);
#endif

  Errormsg = strdup(msg);  

  if (yyin != stdin) {
    fputs(Errormsg, stderr);
    destroy(); 
    exit(0);
  }

  return 0;
}












// -------------------------------------------------
// Management of fresh names
// -------------------------------------------------


// TODO: The table can be deleted in future...


int FreshName_rnum = 0;
int FreshName_wnum = 0;

#define MAX_FRESHNAME 256
int FreshName_table_idx = 0;
char* FreshName_table[MAX_FRESHNAME];

#define FRESH_STRBUF_LENGTH 10


void FreshName_ClearCounter() {

  FreshName_rnum = 0;
  FreshName_wnum = 0;
  ast_symTableInit();

  FreshName_table_idx = 0;
}  

void FreshName_Init() {
  FreshName_ClearCounter();
  for (int i=0; i<MAX_FRESHNAME; i++) {
    FreshName_table[i] = NULL;
  }
}

void FreshName_reInit() {
  FreshName_ClearCounter();
  for (int i = 0; i < FreshName_table_idx; i++) {
    if (FreshName_table[i] != NULL) {
      free(FreshName_table[i]);
    }
  }
}


void FreshName_record(char *freshname) {
  FreshName_table[FreshName_table_idx] = freshname;
  FreshName_table_idx++;  
}

char* FreshName_new(char *suffix, int *counter) {
  char buf[FRESH_STRBUF_LENGTH];
  char *ret;

  while (1) {
  
    snprintf(buf, FRESH_STRBUF_LENGTH, "%s%d",
	     suffix, *counter);

    *counter = *counter + 1;

    if (ast_lookupSymTable(buf) == -1) {      
      break;
    }

    
  }

  ret = strndup(buf, FRESH_STRBUF_LENGTH);

  FreshName_record(ret);
  
  return ret;
}


char* FreshName_new_r() {
  return FreshName_new(SUFFIX_FRESH_NAMES, &FreshName_rnum);
}


char* FreshName_new_w() {
  return FreshName_new(SUFFIX_FRESH_NAMES_FOR_NESTED, &FreshName_wnum);
}





// -------------------------------------------------




void puts_expr_from_ast_equational(Ast *p);
void puts_expr_from_ast_logical(Ast *p);
void puts_expr_from_ast_relational(Ast *p);
void puts_expr_from_ast_additive(Ast *p);
void puts_expr_from_ast_multiplicative(Ast *p);
void puts_expr_from_ast_unary(Ast *p);
void puts_expr_from_ast_atom(Ast *p);


void puts_expr_from_ast(Ast *p) {
  puts_expr_from_ast_equational(p);
  
}


void puts_expr_from_ast_equational(Ast *p) {
  if (p->id == AST_EQ) {
    puts_expr_from_ast_equational(p->left);
    printf("==");
    puts_expr_from_ast_logical(p->right);
    
  } else if (p->id == AST_NE) {
    puts_expr_from_ast_equational(p->left);
    printf("!=");
    puts_expr_from_ast_logical(p->right);
    
  } else {
    puts_expr_from_ast_logical(p);
  }    
  
}



void puts_expr_from_ast_logical(Ast *p) {
  if (p->id == AST_NOT) {
    puts_expr_from_ast_relational(p->left);
    printf("!");
    
  } else if (p->id == AST_AND) {
    puts_expr_from_ast_logical(p->left);
    printf("&&");
    puts_expr_from_ast_relational(p->right);
    
  } else if (p->id == AST_OR) {
    puts_expr_from_ast_logical(p->left);
    printf("!!");
    puts_expr_from_ast_relational(p->right);
        
  } else {
    puts_expr_from_ast_relational(p);
  }    
}


void puts_expr_from_ast_relational(Ast *p) {
  if (p->id == AST_LT) {
    puts_expr_from_ast_relational(p->left);
    printf("<");
    puts_expr_from_ast_additive(p->right);

  } else if (p->id == AST_LE) {
    puts_expr_from_ast_relational(p->left);
    printf("<=");
    puts_expr_from_ast_additive(p->right);

  } else {
    puts_expr_from_ast_additive(p);
  }
}


void puts_expr_from_ast_additive(Ast *p) {
  if (p->id == AST_PLUS) {
    puts_expr_from_ast_additive(p->left);
    printf("+");
    puts_expr_from_ast_multiplicative(p->right);

  } else if (p->id == AST_SUB) {
    puts_expr_from_ast_additive(p->left);
    printf("-");
    puts_expr_from_ast_multiplicative(p->right);

  } else {
    puts_expr_from_ast_multiplicative(p);
  }
}


void puts_expr_from_ast_multiplicative(Ast *p) {
  if (p->id == AST_MUL) {
    puts_expr_from_ast_multiplicative(p->left);
    printf("+");
    puts_expr_from_ast_unary(p->right);

  } else if (p->id == AST_DIV) {
    puts_expr_from_ast_multiplicative(p->left);
    printf("/");
    puts_expr_from_ast_unary(p->right);
    
  } else if (p->id == AST_MOD) {
    puts_expr_from_ast_multiplicative(p->left);
    printf("%%");
    puts_expr_from_ast_unary(p->right);
    
  } else {
    puts_expr_from_ast_unary(p);    
  }
}
  

void puts_expr_from_ast_unary(Ast *p) {
  if (p->id == AST_UNM) {
    printf("-");
    puts_expr_from_ast_atom(p->left);
    
  } else {
    puts_expr_from_ast_atom(p);    
  }
}



void puts_expr_from_ast_atom(Ast *p) {
  if (p->id == AST_NAME) {
    printf("%s", p->left->sym);
    
  } else if (p->id == AST_INT) {
    printf("%ld", p->longval);
    
  } else {
    printf("(");
    puts_expr_from_ast(p);
    printf(")");
  }	   
}

 
void puts_term_from_ast(Ast *p) {
  switch (p->id) {
    
  case AST_SYM:
    printf("%s", p->sym);
    break;

    
  case AST_NAME:
    puts_term_from_ast(p->left);
    break;


  case AST_NIL: {
    printf("[]");
    break;
  }
    
  case AST_MKLIST:{
    printf("[");

    Ast *ast_list = p->right;
    while (ast_list != NULL) {
      Ast *hd = ast_list->left;
      puts_term_from_ast(hd);

      if ((ast_list->right == NULL)
	  || (ast_list->right->id == AST_NIL)) {
	break;
      }
      ast_list = ast_list->right;
      printf(", ");
      
    }

    
    printf("]");
    break;
  }


  case AST_OPCONS:{

    Ast *ast_list = p->right;

    Ast *hd = ast_list->left;

    if (((hd->id == AST_NAME) && (hd->right == NULL)) // x y ...
	|| (hd->id == AST_AGENT) // Z S(x) ...
	|| (hd->id == AST_MKLIST) // [t,s,u,...]
	|| (hd->id == AST_NIL) // []
	) {
	
      puts_term_from_ast(hd);
      
    } else {
      printf("(");
      puts_term_from_ast(hd);
      printf(")");
    }
      
    printf(":");
    hd = ast_list->right->left;    
    puts_term_from_ast(hd);

          
    break;
  }


    
  case AST_AGENT: {
    
    puts_term_from_ast(p->left);

    
    if (p->right != NULL) {
    
      printf("(");
      
      Ast *ast_list = p->right;
      while (ast_list != NULL) {
	Ast *hd = ast_list->left;
	puts_term_from_ast(hd);

	if (ast_list->right == NULL) {
	  break;
	}
	ast_list = ast_list->right;
	printf(", ");
	
      }
      printf(")");
    }
    
    break;
  }
    
  case AST_LET: {
    //(LET (LD (SYM_LIST x1 x2 x3) TERM) TERM)
    printf("(let");

    Ast *ast_list = p->right->right;
    while (ast_list != NULL) {
      Ast *hd = ast_list->left;
      puts_term_from_ast(hd);
      ast_list = ast_getTail(ast_list);
      if (ast_list == NULL) {
	break;
      }
      printf(", ");
      
    }

    printf("=");
    
    puts_term_from_ast(p->right->left);
    printf(" in ");
    puts_term_from_ast(p->left);
    printf(")");
    puts("");
    
    break;

  }

  case AST_LIST: {
    Ast *param_list = p;
    
    while (param_list != NULL) {
      puts_term_from_ast(param_list->left);
      param_list = param_list->right;
      if (param_list == NULL) {
	break;
      }
      printf(", ");
    }

    
    break;
  }

  case AST_INTVAR: {
    printf("int %s", p->left->sym);
    break;
  }


  case AST_INT:
  case AST_PLUS: 
  case AST_SUB:
  case AST_MUL:
  case AST_DIV:
  case AST_MOD:
  case AST_LT:
  case AST_LE:
  case AST_EQ:
  case AST_NE: {
    puts_expr_from_ast(p);
    break;
  }

    
  default: 
    printf("?-puts_term_from_ast\n");
    printf("id=%d, AST_LIST=%d\n", p->id, AST_LIST);
  }
}


void puts_main_symlist(Ast *p) {
  Ast *param_list = p;
    
  while (param_list != NULL) {
    puts_term_from_ast(param_list->left);
    param_list = param_list->right;
    if (param_list == NULL) {
      break;
    }
    printf(" ");
  }
  
}




int is_non_nested(Ast *ast) {

  
  if (ast == NULL) {
    return 1;
  }

  switch (ast->id) {
  case AST_AGENT: {
    Ast *args = ast->right;

    if (args == NULL) {
      return 1;
    }
    
    while (args != NULL) {
      if (!is_non_nested(args->left)) {
	return 0;
      }
      args = args->right;
    }
    return 1;
    break;
  }
    
  case AST_NAME: {
    Ast *args = ast->right;
    if (args == NULL) {
      return 1;
    } else {
      return 0;
    }
  }

  case AST_LIST: {
    Ast *args = ast->right;

    while (args != NULL) {
      if (!is_non_nested(args->left)) {
	return 0;
      }
      args = args->right;
    }
    return 1;
    break;
    
  }
    
  default:
    //    puts("ERROR: is_non_nested");
    //    ast_puts(ast);
    //    exit(1);
    
    return 1;
  }

}



int compile_term(Ast *sym_list, Ast *body);

void compile_nested_params(Ast *body) {
  // body->id == AST_AGENT

  //  puts("compile_nested_params"); ast_puts(body); puts("");
  
  Ast *args = body->right;
  
  while (args != NULL) {
    Ast *term = args->left;

    /*
    if (normalise_function_application(term)) {
      // Make it a term by removing the whole list
      term = term->left;
    }
    */
    
    
    if (!is_non_nested(term)) {
      
      char *new_name = FreshName_new_w();
      Ast *new_name_sym = ast_makeSymbol(new_name);
      args->left = ast_makeAST(AST_NAME, new_name_sym, NULL);
      
      compile_term(ast_makeList1(new_name_sym), term);
      printf(", ");
      
      //	free_name(new_name);
    }
    
    args = args->right;
  }
    
}

int compile_term(Ast *sym_list, Ast *body) {

  //  puts("\ncompile_term");
  //  ast_puts(body); puts("");



  switch (body->id) {

  case AST_NIL:
  case AST_MKLIST:
  case AST_OPCONS:
  case AST_AGENT: {

    compile_nested_params(body);
    
    Ast *hd_sym_list = ast_getNth(sym_list,0);
    char *sym = hd_sym_list->sym;    
    printf("%s~", sym);
    puts_term_from_ast(body);

    
    return 1;
    
         
    break;
  }

    
  case AST_NAME: {
    //T(foo C(...) a b = f a b)
    //==> foo(r1,a,b) >< C(...) => f(r,b) ~ a
          
    // (AST_NAME sym [args])
    // (f a b1 b2) ==> f(sym1, sym2, ..., b1, b2) ~ a
    
    Ast *f_name = body->left;               // AST_SYM
    
    Ast *terms = body->right;

    if (terms == NULL) {
      //thus, the terms is [t].


      Ast *sym_list_1st = sym_list->left;
      Ast *terms_1st = body->left;

      //      puts("term_1st"); ast_puts(terms_1st); puts("");
      //      compile_nested_params(terms_1st);
      
      puts_term_from_ast(sym_list_1st);
      printf("~");
      puts_term_from_ast(terms_1st);

      
      break;
    }


    
    // [constructor_ast, f_param_list ...]
    Ast *constructor_ast = terms->left;
    Ast *f_param_list = terms->right;


    //        puts("f_param_list"); ast_puts(f_param_list); puts("");
    
    
    // Change sym in sym_list into AST_NAME
    // and append it to f_param_list
    Ast *sym_list_at = sym_list;
    Ast *params = NULL;

    
    
    while (sym_list_at != NULL) {
      Ast *elem = sym_list_at->left;

      params = ast_addLast(params,
			   ast_makeAST(AST_NAME, elem, NULL));
      
      if (sym_list_at->right == NULL) {
	// Append
	// sym_list_at->right = f_param_list;

	//	params->right = f_param_list;
	params = ast_appendList(params, f_param_list);
	

	/*
	if (f_param_list != NULL) {
	  // f_param_list is already a list,
	  // so f_param_list->left must be added as an element.
	  params = ast_addLast(params, f_param_list->left);
	}
	*/

	
	break;
      }
      
      // next
      sym_list_at = sym_list_at->right;
    }

    
    /*
    if (f_param_list != NULL) {
      params = ast_addLast(params, f_param_list);
      puts("params"); ast_puts(params); puts("");
    }
    */
    
    //        puts("params"); ast_puts(params); puts("");
    
    Ast *f_ast = ast_makeAST(AST_AGENT,
			     f_name,
			     params);



    //        puts("f_ast"); ast_puts(f_ast); puts("");
    
    
    
    compile_nested_params(f_ast);

    
    compile_nested_params(constructor_ast);

    
    if ((constructor_ast->id != AST_AGENT)
	&& ((constructor_ast->id == AST_NAME) &&
	    (constructor_ast->right != NULL))) {
      
      char *new_name = FreshName_new_w();
      Ast *new_name_sym = ast_makeSymbol(new_name);
      Ast *orig_constructor_ast = constructor_ast;
      
      constructor_ast = ast_makeAST(AST_NAME, new_name_sym, NULL);
      
      compile_term(ast_makeList1(new_name_sym), orig_constructor_ast);
      printf(", ");
      
    }
    
    puts_term_from_ast(f_ast);

    printf("~");
    puts_term_from_ast(constructor_ast);
    
    break;
    

  }


    
  case AST_LET: {
    //(LET (LD (SYM_LIST x1 x2 x3) TERM) TERM)
    Ast *param_list = sym_list;
    Ast *mainbody = body->right;
    Ast *let_variables = body->left->left;
    Ast *let_mainbody = body->left->right;

    
    compile_term(let_variables, let_mainbody);
    printf(", ");
    compile_term(param_list, mainbody);
            
    break;
  }


  case AST_IF: {
    // (AST_IF expr (AST_THEN_ELSE then else))}
    printf("if ");
    puts_expr_from_ast(body->left);

    printf(" then ");
    compile_term(sym_list, body->right->left);

    printf(" else ");
    compile_term(sym_list, body->right->right);
    break;
  }

  case AST_LIST: {
    Ast *param_list = sym_list;
    Ast *bundle = body;
    
    while (param_list != NULL) {
      Ast *elem = param_list->left;
      Ast *bundle_elem = bundle->left;
      if (bundle_elem == NULL) {
	break;
      }
      compile_term(ast_makeList1(elem), bundle_elem);
      
      param_list = param_list->right;
      bundle = bundle->right;

      if (param_list != NULL) {
	printf(", ");
      }
    }
    
    break;
  }


    
  default:
    puts("????");
    printf("log:"); ast_puts(body); puts("");
  }

  
  return 1;
}


int compile_rule(Ast *at) {
  // (AST_RULE
  //      [foo_sym_agent, const_agent, arg1, arg2...]
  //      //<body> <-- ast (not LIST for now)
  //      (AST_BUNDLE explist NULL) 
  // )

  Ast *body = at->right;

  if (body == NULL) {
    puts("ERROR: the body is NULL.");
    return 0;
  }


  
  // Let expression
  if (body->id == AST_LET) {
    // body is LET
    //(LET (LD (SYM_LIST x1 x2 x3) TERM) TERM)
    //
    //    T(foo C(...) a b = let x = t in s)
    //    ==> T(foo C(...) a b = s), Tb(x = t)
    // 

    
    Ast *s = body->right;


    
    at->right = s;

    
    compile_rule(at);



    Ast *symlist = body->left->left;
    Ast *rhs = body->left->right;

    //    puts("DEBUG rhs");
    //    ast_puts(rhs); puts("");
    
    printf(", ");
    compile_term(symlist, rhs);

    // Finish
    return 1;

  }


  // The first def_list (ie, sym)
  char *func_sym = at->left->left->sym;


  
  // Calculation of bundle_arity
  int bundle_arity = 1;
  if (body->id == AST_LIST) {
    bundle_arity = ast_getLen(body);

    
    
  } else if (body->id == AST_NAME) {

    ast_lookupConst(body->left->sym, &bundle_arity);    
    
  } else if (body->id == AST_IF) {
    ast_lookupConst(func_sym, &bundle_arity);
    //    printf("%s:%d\n", func_sym, bundle_arity);

    // Warning:
    
  }

  
  // Memorise the bundle_arity with sym
  ast_recordConst(func_sym, bundle_arity);

    
  
  
  // make the responsible names: r1, r2, r3, ...
  // according to the number bundle_arity
  Ast *sym_list = NULL;
  for (int i=0; i<bundle_arity; i++) {
    sym_list = ast_addLast(sym_list, ast_makeSymbol(FreshName_new_r()));
  }


  
  // Operation for LHS

  // The first def_list (ie, sym)
  Ast *def_list = at->left;
  
  //  Ast *ast_sym = def_list->left;
  //  char *sym = ast_sym->sym;
  printf("%s(", func_sym);



		  
  // The second element of def_list (ie, constr)
  def_list = def_list->right;
  
  Ast *constr = def_list->left;
    

  Ast *p = sym_list;
  while (p != NULL) {
    printf("%s", p->left->sym);
    if (p->right == NULL) {
      break;      
    }
    printf(", ");
    p = p->right;
  }

  
  // The third element of def_list (ie, param_list)
  Ast *param_list = def_list->right;
  
  while (param_list != NULL) {
    printf(", ");
    puts_term_from_ast(param_list->left);
    param_list = ast_getTail(param_list);
  }
  
  
  printf(") >< ");

  
  puts_term_from_ast(constr);
  
  
  printf(" =>\n    ");

  
  // Operation for LHS
  
  
  switch (body->id) {
    //  case AST_APP: {
  case AST_NAME:
  case AST_AGENT: {
    // (AST_AGENT sym arglist)
    // T(foo C(...) a b = t)  // where t is just a term, not a bundle
    // ==> foo(r1,a,b) >< C(...) => r1~t

    
    // (AST_NAME sym arglist)
    // T(foo C(...) a b = f a b)
    // ==> foo(r1,a,b) >< C(...) => f(r,b) ~ a
    //
    // T(foo C(...) a b = f a b)
    // ==> foo(r1,r2,a,b) >< C(...) => f(r1,r2,b) ~ a
    //
    // we have to memorise the number of returning bundles.
    // But, anyway we assume that it is just 1.
    
    //ast_puts(body); puts("");
    
    
    //    Ast *sym_list = ast_makeList1(ast_makeSymbol(r));


    //ast_puts(body); puts("");

    
    compile_term(sym_list, body);
    
    break;
  }

    
  case AST_LIST: {
    Ast *exps = body;
    Ast *syms = sym_list;

    while (exps != NULL) {
      compile_term(ast_makeList1(syms->left), exps->left);

      exps = exps->right;
      syms = syms->right;
      if (exps != NULL) {
	printf(", ");
      }
    }


    
    break;
  }


  case AST_IF: {
    compile_term(sym_list, body);
    break;
  }

  case AST_NIL:
  case AST_MKLIST:
  case AST_OPCONS: {
    compile_term(sym_list, body);
    break;
  }


    
  default:
    puts("???");
    ast_puts(body);
  }



  
  return 1;
}



int compile(Ast *ast) {
  //    puts("compile");

  switch (ast->id) {
  case AST_BODY: {
    // (AST_BODY expression NULL)
    
    int bundle_arity = 1;
    
    if (ast->left->id == AST_LET) {
      //(LET (LD (SYM_LIST x1 x2 x3) TERM1) TERM2)
      Ast *term2 = ast->left->right;
      
      if (term2->id == AST_LIST) {
	bundle_arity = ast_getLen(term2);
      }
      
    } else if (ast->left->id == AST_LIST) {
      bundle_arity = ast_getLen(ast->left);
      
    } else if (ast->left->id == AST_NAME) {
      char *sym = ast->left->left->sym;
      ast_lookupConst(sym, &bundle_arity);
      
    }
    

    // According to the bundle arity,
    // a fresh sym list is built.
    Ast *sym_list = NULL;
    if (bundle_arity == 1) {
      sym_list = ast_makeList1(ast_makeSymbol("main"));
    } else {
      for (int i=0; i<bundle_arity; i++) {
	sym_list = ast_addLast(sym_list, ast_makeSymbol(FreshName_new_r()));
      }
    }
    
    compile_term(sym_list, ast->left);
    puts(";");
    //puts_term_from_ast(sym_list);
    puts_main_symlist(sym_list);
        
    break;
  }
    
  case AST_RULE:
    return compile_rule(ast);
    break;

    
  default:
    fprintf(stderr, "ERROR: No matching ID in compile.\n");
    exit(1);
  }


  return 1;
}



int exec(Ast *at) {

  //#define DEBUG  
#ifdef DEBUG
  puts("DEBUG: ast_puts");
  ast_puts(at); puts("");
#endif

  compile(at);

  FreshName_reInit();
  

    
    
  
  return 1;
}



int destroy() {
  return 0;
}



int yywrap() {
  return 1;
}



int main(int argc, char *argv[])
{
  char *fname = NULL;
  int retrieve_flag = 1; // 1: retrieve to interpreter even if error occurs




  for (int i=1; i<argc; i++) {
    if (*argv[i] == '-') {
      switch (*(argv[i] +1)) {
      case 'v':
	fprintf(stderr, "Version %s (%s)\n", VERSION, BUILT_DATE);
	exit(0);
	break;

      case 'f':
	i++;
	if (i < argc) {
	  fname = argv[i];
	  retrieve_flag = 0;
	} else {
	  fprintf(stderr, "ERROR: The option `-f' needs a string of an input file name.\n");
	  exit(1);
	}
	break;
	
      }
    }
  }


  // input file source
  if (fname == NULL) {
    yyin = stdin;
    
  } else {
    if (!(yyin = fopen(fname, "r"))) {
      
      char *fname_source = malloc(sizeof(char*) * 256);
      snprintf(fname_source, 256, "%s", fname);
      if (!(yyin = fopen(fname_source, "r"))) {
	fprintf(stderr, "Error: The file `%s' cannot be opened.\n", fname);
	exit(1);
      }
      
      free(fname_source);
    }
  }
  
  
	
#ifdef MY_YYLINENO
  InfoLineno_Init();
#endif
	

  ast_heapInit();

  FreshName_Init();     // initialise FreshName.
      
  
  linenoiseHistoryLoad(".train.history.txt");

  
  // the main loop of parsing and execution
  while(1) {

    // When errors occur during parsing
    if (yyparse()!=0) {
      
      if (!retrieve_flag) {
      	exit(0);
      }
      
      if (yyin != stdin) {
      	fclose(yyin);
        while (yyin!=stdin) {
      	  popFP();
      	}
#ifdef MY_YYLINENO
      	InfoLineno_AllDestroy();
#endif
      }
      
    }
  }
  
  exit(0);
}
 

#include "lex.yy.c"
