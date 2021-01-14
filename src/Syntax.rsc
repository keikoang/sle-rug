module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id id "{" Question* questions"}"; 

syntax Question
  = normal_question: Str label Id ident ":" Type qtype
  | computed_question: Str label Id ident ":" Type qtype "=" Expr expr
  | block: "{" Question* questions "}"
  | if_then: "if" "(" Expr condition ")" "{" Question* trueQuestions"}"
  | if_then_else: "if" "(" Expr condition ")" "{" Question* trueQuestions "}" "else" "{" Question* falseQuestions"}"
  ; 
 

syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool 
  | Int
  | Str
  | pars: "(" Expr expr")" //highest precedence
  > right not: "!" Expr expr //right associative
  > left (
    mul: Expr left "*" Expr right
  | div: Expr left "/" Expr right
  )
  > left (
    add: Expr left "+" Expr right
  | sub: Expr left "-" Expr right
  )
  //generally i think comparison operator should be non associative
  > non-assoc (
    eq: Expr left "==" Expr right
  | neq: Expr left "!=" Expr right
  )
  //non associative because for example 3 < 4 < 5 is not (3 < 4) < 5
  > non-assoc(
    gt: Expr left "\>" Expr right
  | lt: Expr left "\<" Expr right
  | leq: Expr left "\<=" Expr right
  | geq: Expr left "\>=" Expr right
  )
  > left and: Expr left "&&" Expr right
  > left or: Expr left "||" Expr right
  ;
  
// was confused if it should be these or Bool | Int | Str  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;  
  
//took this from series2, means everything a string is a quote,
// follow by zero or more chars that is not a quote and followed by another quote
lexical Str = [\"] ![\"]* [\"]; 

//integer can be zero or other number, but cant be 03 for example
lexical Int 
  = [1-9][0-9]*
  | [0]
  ;

lexical Bool 
  = "true"
  | "false"
  ;

/*  For testing:
	import ParseTree;
	import Syntax;
	l = //copy source location//;
	pt = parse(#start[Form], l); 
*/

