module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = normal_question: Str Id ":" Type
  | computed_question: Str Id ":" Type "=" Expr
  | block: "{" Question* "}"
  | if_then_else: "if" "(" Expr ")" "{" Question "}"
  | if_then: "if" "(" Expr ")" "{" Question "}" "else" "{" Question "}"
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool 
  | Int
  | Str
  | pars: "(" Expr ")" //highest precedence
  > right not: "!" Expr //right associative
  > left (
  mul: Expr "*" Expr
  | div: Expr "/" Expr
  )
  | left (
  add: Expr "+" Expr
  | sub: Expr "-" Expr
  )
  //generally i think comparison operator should be non associative
  > non-assoc (
  eq: Expr "==" Expr
  | neq: Expr "!=" Expr
  )
  //non associative because for example 3 < 4 < 5 is not (3 < 4) < 5
  | non-assoc(
  gt: Expr "\>" Expr
  | lt: Expr "\<" Expr
  | leq: Expr "\<=" Expr
  | geq: Expr "\>=" Expr
  )
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr 
  ;
  
// was confused if it should be these or Bool | Int | Str  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;  
  
//took this from series2, means everything a string is a quote,
// follow by zero or more chars that is not a quote and another quote
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



