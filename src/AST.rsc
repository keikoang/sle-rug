module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = normal_question(str label, AId ident, AType qtype)
  | computed_question(str label, AId ident, AType qtype, AExpr expr)
  | block(list[AQuestion] questions)
  | if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions)
  | if_then(AExpr condition, list[AQuestion] trueQuestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolean(bool boolValue)
  | integer(int intValue)
  | string(str strValue)
  | pars(AExpr expr)
  | not(AExpr expr)
  | mul(AExpr leftExpr, AExpr rightExpr)
  | div(AExpr leftExpr, AExpr rightExpr)
  | add(AExpr leftExpr, AExpr rightExpr)
  | sub(AExpr leftExpr, AExpr rightExpr)
  | eq(AExpr leftExpr, AExpr rigthExpr)
  | neq(AExpr leftExpr, AExpr rightExpr)
  | gt(AExpr leftExpr, AExpr rightExpr)
  | lt(AExpr leftExpr, AExpr rightExpr)
  | leq(AExpr leftExpr, AExpr rightExpr)
  | geq(AExpr leftExpr, AExpr rightExpr)
  | and(AExpr leftExpr, AExpr rightExpr)
  | or(AExpr leftExpr, AExpr rightExpr)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string()
  ;
