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
extern int yylineno;

 
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
    printf("[InfoLineno]Malloc error\n");
    exit(-1);
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
%token LP RP LC RC LB RB COMMA CROSS ABR
%token COLON
%token TO CNCT
%token DELIMITER 

%token ANNOTATE_L ANNOTATE_R

%token PIPE CR
%token NOT AND OR LD EQUAL NE GT GE LT LE
%token ADD SUB MUL DIV MOD INT LET IN END IF THEN ELSE ANY WHERE
%token END_OF_FILE USE


%type <ast>
top
func_def
constr_term
bundle
expression
agentterm
let_term
bundle_params
ast_params
nameterm
expr additive_expr equational_expr logical_expr relational_expr unary_expr
multiplicative_expr primary_expr


%type <chval> term_symbol


%nonassoc REDUCE
%nonassoc RP

%right COLON
 //%right LD
 //%right EQ
 //%left NE GE GT LT
 //%left ADD SUB
 //%left MULT DIV

%%
s     
: error DELIMITER { 
  yyclearin;
  yyerrok; 
  puts(Errormsg);
  free(Errormsg);
  ast_heapReInit();
  if (yyin == stdin) yylineno=0;
  //  YYACCEPT;
  YYABORT;
}
| DELIMITER { 
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
| top DELIMITER
{
  exec($1);
  ast_heapReInit(); 
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
}
| command {
  if (yyin == stdin) yylineno=0;
  YYACCEPT;
};



command
: COLON NAME
{
  if (!(strcmp($2, "quit"))) {
    destroy(); exit(0);
  } else if (!(strcmp($2, "q"))) {
    destroy(); exit(0);    

  } else {
    printf("ERROR: No operation for the given command.");
  }
}
;




top
: func_def
| expr
; 

term_symbol
: NAME  { $$ = $1; }
| AGENT { $$ = $1; }
;


// (AST_RULE
//      [foo_sym_agent, const_agent, params1, params2, ...]
//      (AST_BUNDLE [expression1, expression2,...] NULL)
// )


func_def
: term_symbol constr_term LD bundle
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($2, NULL)),
		   $4);
}
| term_symbol constr_term ast_params LD bundle
{ $$ = ast_makeAST(AST_RULE,
		   ast_makeCons(ast_makeSymbol($1),
				ast_makeCons($2, $3)),
		   $5);

}
;


constr_term
: AGENT 
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
| LP AGENT RP
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($2), NULL); }
| LP AGENT ast_params RP
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($2), $3); }
;



expression
: ast_params { $$ = ast_makeAST(AST_APP, $1, NULL); }
| let_term
;



//(LET (LD (SYM_LIST x1 x2 x3) TERM) TERM)
let_term
: LET bundle_params LD expression IN bundle
{ $$ = ast_makeAST(AST_LET,
		   ast_makeAST(AST_LD, $2, $4),
		   $6); }
;



bundle
: expression 
{ $$ = ast_makeBundle(ast_makeList1($1)); }
| bundle COMMA expression 
{ $$ = ast_makeBundle(ast_makeList2($1, $3)); }
;




bundle_params
: NAME { $$=ast_makeList1(ast_makeSymbol($1)); }
| bundle_params COMMA NAME
{ $$= ast_addLast($1,
		  ast_makeList1(ast_makeSymbol($3)));
}
;



agentterm
: AGENT
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
| LP AGENT ast_params RP
{ $$=ast_makeAST(AST_AGENT, ast_makeSymbol($2), $3); }
| NAME 
{ $$=ast_makeAST(AST_NAME, ast_makeSymbol($1), NULL); }
| LP NAME ast_params RP
{ $$=ast_makeAST(AST_NAME, ast_makeSymbol($2), $3); }
;


				 
ast_params
: agentterm { $$ = ast_makeList1($1); }
| ast_params agentterm { $$ = ast_addLast($1, $2); }
| LP agentterm RP { $$ = $2; }
;

expr
: equational_expr
;

equational_expr
: logical_expr
| equational_expr EQUAL logical_expr { $$ = ast_makeAST(AST_EQ, $1, $3); }
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
: nameterm { $$ = $1;}
| INT_LITERAL { $$ = ast_makeInt($1); }
| AGENT { $$=ast_makeAST(AST_AGENT, ast_makeSymbol($1), NULL); }
| LP expr RP { $$ = $2; }
;

nameterm
: NAME {$$=ast_makeAST(AST_NAME, ast_makeSymbol($1), NULL);}




%%



int yyerror(char *s) {
  extern char *yytext;
  char msg[256];

#ifdef MY_YYLINENO
  if (InfoLineno != NULL) {
    sprintf(msg, "%s:%d: %s near token `%s'.\n", 
	  InfoLineno->fname, yylineno+1, s, yytext);
  } else {
    sprintf(msg, "%d: %s near token `%s'.\n", 
	  yylineno, s, yytext);
  }
#else
  sprintf(msg, "%d: %s near token `%s'.\n", yylineno, s, yytext);
#endif

  Errormsg = strdup(msg);  

  if (yyin != stdin) {
    //        puts(Errormsg);
    destroy(); 
    //        exit(0);
  }

  return 0;
}
















int rnum = 0;
void init_r() {
  rnum = 0;
}

#define RNUM_STR_LENGTH 10
char* new_name_r() {
  char buf[RNUM_STR_LENGTH];
  char *ret;
  snprintf(buf, RNUM_STR_LENGTH, "%s%d", SUFFIX_FRESH_NAMES, rnum);
  rnum++;

  ret = strndup(buf, RNUM_STR_LENGTH);
  
  return ret;
}


void free_name_r(char *r) {
  free(r);
}



void puts_term_from_ast(Ast *p) {
  switch (p->id) {
    
  case AST_SYM:
    printf("%s", p->sym);
    break;

    
  case AST_NAME:
    puts_term_from_ast(p->left);
    break;

    
  case AST_AGENT: {
    puts_term_from_ast(p->left);

    if (p->right != NULL) {
    
      printf("(");
      
      Ast *ast_list = p->right;
      while (ast_list != NULL) {
	Ast *hd = ast_list->left;
	puts_term_from_ast(hd);
	ast_list = ast_getTail(ast_list);
	if (ast_list == NULL) {
	  break;
	}
	printf(",");
	
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
      printf(",");
      
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
      printf(",");
    }

    
    break;
  }


    
  default:
    printf("?-puts_term_from_ast\n");
    printf("id=%d, AST_LIST=%d\n", p->id, AST_LIST);
    
  }
}


// LIST(AST_AGENT sym NULL, paramlist)
// ==>
// LIST(AST_AGENT sym paramlist, NULL)


// LIST(AST_NAME sym paramlist, NULL)
// ==>
// LIST(AST_NAME sym NULL, paramlist)
int normalise_function_application(Ast *ast) {
  if (ast->id != AST_LIST) {
    return 0;
  }

  Ast* hd = ast->left;

  if (hd->id == AST_AGENT) {
    //    puts("normalise ast_agent:");
    //    ast_puts(ast);puts("");

    if (hd->right == NULL) {
      hd->right = ast->right;
      ast->right = NULL;
    }
    return 1;
  }

  
  if (hd->id != AST_NAME) {
    return 0;
  }

  if (hd->right != NULL) {
    // main
    Ast* paramlist = hd->right;
    hd->right = NULL;
    ast->right = paramlist;
    return 1;
  }

  return 0;
  
}



int compile_expression(Ast *sym_list, Ast *body) {

  switch (body->id) {
  case AST_AGENT: {

    // the length of the return bundle is 1
    Ast *hd_sym_list = ast_getNth(sym_list,0);
    char *sym = hd_sym_list->sym;    
    printf("%s~", sym);
    
    puts_term_from_ast(body);
    break;
  }
    
  case AST_APP: {
    //T(foo C(...) a b = f a b)
    //==> foo(r1,a,b) >< C(...) => f(r,b) ~ a
    
    //    puts("AST_APP:");
    //    ast_puts(body); puts("");


    // (AST_APP (AST_LIST term tail) NULL);
    Ast *terms = body->left;

    normalise_function_application(terms);


    if (terms->right == NULL) {
      //thus, terms is [term].
      Ast *sym_list_1st = sym_list->left;
      puts_term_from_ast(sym_list_1st);
      printf("~");
      Ast *terms_1st = terms->left;
      puts_term_from_ast(terms_1st);

      
    } else {
      // term is [t1, t2, t3,...]
      // t1 is f_name_ast,
      // t2 is constructor_ast
      // t3... is f_param_list

      
      
      // (f a b c ...)
      Ast *f_name_ast = terms->left;               // AST_NAME
      Ast *f_sym_ast = f_name_ast->left;           // AST_SYM

      terms = terms->right;
      Ast *constructor_ast = terms->left;   // AST_NAME

      Ast *f_param_list = terms->right;


      // Change sym in sym_list into AST_NAME
      // and append it to f_param_list
      Ast *param_list = sym_list;
      while (sym_list != NULL) {
	Ast *elem = sym_list->left;
	sym_list->left = ast_makeAST(AST_NAME, elem, NULL);
	if (sym_list->right == NULL) {
	  // Append
	  sym_list->right = f_param_list;
	  break;
	}

	// next
	sym_list = sym_list->right;
      }
      
      

      
      Ast *f_ast = ast_makeAST(AST_AGENT,
			       f_sym_ast,
			       param_list);
			      


      puts_term_from_ast(f_ast);
      printf("~");
      puts_term_from_ast(constructor_ast);
      
    }

    
    break;
  }
    
  case AST_LET: {
    puts("LET");
    break;
  }

    
  default:
    puts("????");
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
    compile_expression(symlist, rhs);

    // Finish
    return 1;

  }


  
  int bundle_arity;
  if (body->id == AST_BUNDLE) {
    bundle_arity = body->intval;
    
  } else {
    // AST_APP

    // we have to memorise the number of returning bundles.
    // But, anyway we assume that it is just 1.

    bundle_arity = 1;

  }
    

  // make the responsible names: r1, r2, r3, ...
  // according to the number bundle_arity
  Ast *sym_list = NULL;
  for (int i=0; i<bundle_arity; i++) {
    sym_list = ast_addLast(sym_list, ast_makeSymbol(new_name_r()));
  }


  // Operation for LHS
  Ast *def_list = at->left;
  
  Ast *ast_sym = def_list->left;
  char *sym = ast_sym->sym;
  printf("%s(", sym);
  
  def_list = ast_getTail(def_list);
  
  Ast *constr = def_list->left;
  
  

  Ast *p = sym_list;
  while (p != NULL) {
    printf("%s", p->left->sym);
    if (p->right == NULL) {
      break;      
    }
    printf(",");
    p = p->right;
  }

  
  Ast *param_list = ast_getTail(def_list);
  
  while (param_list != NULL) {
    printf(",");
    puts_term_from_ast(param_list->left);
    param_list = ast_getTail(param_list);
  }
  
  
  printf(")><");
  puts_term_from_ast(constr);
  

  
  printf(" => ");

  
  
  
  switch (body->id) {
  case AST_APP: {      
    // (AST_APP (AST_LIST term tl) NULL);

    // T(foo C(...) a b = t)  // where t is just a term, not a bundle
    // ==> foo(r1,a,b) >< C(...) => r1~t

    
    //T(foo C(...) a b = f a b)
    //==> foo(r1,a,b) >< C(...) => f(r,b) ~ a
    //
    //T(foo C(...) a b = f a b)
    //==> foo(r1,r2,a,b) >< C(...) => f(r1,r2,b) ~ a
    //
    // we have to memorise the number of returning bundles.
    // But, anyway we assume that it is just 1.
    
    //ast_puts(body); puts("");
    
    
    //    Ast *sym_list = ast_makeList1(ast_makeSymbol(r));
    compile_expression(sym_list, body);
    
    break;
  }

    
  case AST_BUNDLE: {
    Ast *exps = body->left;
    Ast *syms = sym_list;

    while (exps != NULL) {
      compile_expression(ast_makeList1(syms->left), exps->left);
      exps = exps->right;
      syms = syms->right;
      if (exps != NULL) {
	printf(", ");
      }
    }
    
    break;
  }

    
  default:
    puts("???");
  }


  // free names
  p = sym_list;
  while (p != NULL) {
    free_name_r(p->left->sym);
    p = p->right;
  }
    


  
  return 1;
}



int compile(Ast *ast) {
  //  puts("compile");
  
  switch (ast->id) {
  case AST_RULE:
    return compile_rule(ast);
    puts("END");
    break;

    
  default:
    puts("ERROR: No matching ID in compile");
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
  
  
  init_r();     // initialise the number for r.
  compile(at);
    
  // The delimiter for the ends.
  puts(";");
  fflush(stdout);
  
  
  
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
  int retrieve_flag = 1; // 1: retrieve to interpreter even if error occurs

  
#ifdef MY_YYLINENO
  InfoLineno_Init();
#endif


  ast_heapInit();

  
  
  
  
  
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
