module Check

import AST;
import Resolve;
import Message; // see standard library
import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

Type ast2type(AType atype){
	switch(atype){
		case integer():
			return tint();
		case boolean():
			return tbool();
		case string():
			return tstr();
	}
	return tunknown();
}

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
	TEnv type_environment = {};
	visit(f){
		case normal_question(str label, id(name), AType atype, src = loc source) :
			type_environment += {<source, name, label, ast2type(atype)>};	
		case computed_question(str label, id(name), AType atype, AExpr _, src = loc source) :
			type_environment += {<source, name, label, ast2type(atype)>};
	}
  	return type_environment; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  	return ({} | it + check(question, tenv, useDef) | /AQuestion question <- f.questions); 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	switch(q){
		case normal_question(str _, AId id, AType _, src = loc l):
			msgs += {error("Duplicate question with different type", l) | (size((tenv<1,3>)[id.name]) > 1)} 
			+ {warning("Same label for different questions", l) | (size((tenv<2,0>)[q.label]) > 1)}
			+ {warning("Different label for occurences of same question", l) | (size((tenv<1,2>)[q.ident.name]) > 1) };
		case computed_question(str _, AId id, AType _, AExpr expr, src = loc l):
			msgs += {error("Duplicate question with different type", l) | (size((tenv<1,3>)[id.name]) > 1)}
			+ {warning("Same label for different questions", l) | (size((tenv<2,0>)[q.label]) > 1)}
			+ {warning("Different label for occurences of same question", l) | (size((tenv<1,2>)[q.ident.name]) > 1)}
			+ check(expr, tenv, useDef);
		case block(list[AQuestion] questions, src = loc _):
			msgs += ({} | it + check(question, tenv, useDef) | /AQuestion question <- questions);
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions, src = loc l):
			msgs += {error("Condition is not boolean", l) | (typeOf(condition, tenv, useDef) != tbool())}
			+ check(condition, tenv, useDef)
			+ ({} | it + check(tQuestion, tenv, useDef) | /AQuestion tQuestion <- trueQuestions)
			+ ({} | it + check(fQuestion, tenv, useDef) | /AQuestion fQuestion <- falseQuestions);
		case if_then(AExpr condition, list[AQuestion] trueQuestions, src = loc l): 
			msgs += {error("Condition is not boolean", l) | (typeOf(condition, tenv, useDef) != tbool())}
			+ check(condition, tenv, useDef)
			+ ({} | it + check(tQuestion, tenv, useDef) | /AQuestion tQuestion <- trueQuestions);
	}
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
    set[Message] msgs = {};
  
    switch (e) {
        case ref(AId x):
        	msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
		case pars(AExpr expr):
			msgs += check(expr, tenv, useDef);
		case not(AExpr expr):
			msgs += { error("Invalid operand types to operator", expr.src) | typeOf(expr, tenv, useDef) != tbool()};
    	case mul(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
    	case div(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case add(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case sub(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case eq(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != typeOf(rightExpr, tenv, useDef)}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case neq(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != typeOf(rightExpr, tenv, useDef)}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case gt(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
    	case lt(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);		
    	case gt(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
    	case leq(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
    	case geq(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tint() || typeOf(rightExpr, tenv, useDef) != tint()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
    	case and(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tbool() || typeOf(rightExpr, tenv, useDef) != tbool()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  		case or(AExpr leftExpr, AExpr rightExpr):
    		msgs += { error("Invalid operand types to operator", e.src) | typeOf(leftExpr, tenv, useDef) != tbool() || typeOf(rightExpr, tenv, useDef) != tbool()}
    		+ check(leftExpr, tenv, useDef) + check (rightExpr, tenv, useDef);
  	}  
  	return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  	switch (e) {
    	case ref(id(_, src = loc u)):  
      		if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        		return t;
      		}
      	case boolean(bool _, src = loc _):
      		return tbool();
      	case integer(int _, src = loc _):
      		return tint();
      	case string(str _, src = loc _):
      		return tstr();
      	case pars(AExpr expr, src = loc _):
      		return typeOf(expr, tenv, useDef);
      	case not(AExpr expr, src = loc _):
      		if (typeOf(expr, tenv, useDef) == tbool()) return tbool();
      		else return tunknown();
      	case mul(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tint();
      		else return tunknown();
      	case div(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tint();
      		else return tunknown();
      	case add(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tint();
      		else return tunknown();
      	case sub(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tint();
      		else return tunknown();
      	case eq(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tbool() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case neq(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tbool() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case gt(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case lt(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case geq(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case leq(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tint() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case and(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tbool() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
      	case or(AExpr leftExpr, AExpr rightExpr, src = loc _):
      		if (typeOf(leftExpr, tenv, useDef) == tbool() && typeOf(rightExpr, tenv, useDef) == tint()) return tbool();
      		else return tunknown();
  }
  return tunknown(); 
}


/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

