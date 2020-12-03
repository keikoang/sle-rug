module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("<f.id>", [cst2ast(question) | question <- f.questions], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
	switch(q) {
		case (Question)`<Str label> <Id ident>: <Type qtype>`:
			return normal_question("<label>", id("<ident>"), cst2ast(qtype), src=q@\loc);
		case (Question)`<Str label> <Id ident>: <Type qtype> = <Expr expr>`:
			return computed_question("<label>", id("<ident>"), cst2ast(qtype), cst2ast(expr), src=q@\loc);
		case (Question)`{<Question* questions>}`:
			return block([cst2ast(question) | question <- questions], src=q@\loc);
		case (Question)`if (<Expr expr>) {<Question* questions>}`:
			return if_then(cst2ast(expr), [cst2ast(question) | question <- questions], src=q@\loc);
		case (Question)`if (<Expr expr>) {<Question* tQuestions>} else {<Question* fQuestions>}`:
			return if_then_else(cst2ast(expr), [cst2ast(tQuestion) | tQuestion <- tQuestions], [cst2ast(fQuestion) | fQuestion <- fQuestions], src=q@\loc);
		default: throw "Unhandled question: <q>";
	}
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`:
    	return ref(id("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Bool b>`:
    	return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`<Int i>`:
    	return integer(toInt("<i>"), src=i@\loc);
    case (Expr)`<Str s>`:
    	return string("<s>", src=s@\loc);
    case (Expr)`(<Expr expr>)`:
    	return pars(cst2ast(expr), src=expr@\loc);
    case (Expr)`!<Expr expr>`:
    	return not(cst2ast(expr), src=expr@\loc);
    case (Expr)`<Expr leftExpr> * <Expr rightExpr>`:
		return mul(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> / <Expr rightExpr>`:
    	return div(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> + <Expr rightExpr>`:
    	return add(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> - <Expr rightExpr>`:
    	return sub(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> == <Expr rightExpr>`:
    	return eq(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> != <Expr rightExpr>`:
    	return neq(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> \> <Expr rightExpr>`:
    	return gt(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> \< <Expr rightExpr>`:
    	return lt(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> \<= <Expr rightExpr>`:
    	return leq(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> \>= <Expr rightExpr>`:
    	return geq(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> && <Expr rightExpr>`:
    	return and(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    case (Expr)`<Expr leftExpr> || <Expr rightExpr>`:
    	return or(cst2ast(leftExpr), cst2ast(rightExpr), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
	switch (t) {
    	case (Type)`boolean`:
      		return boolean(src=t@\loc);
    	case (Type)`integer`:
      		return integer(src=t@\loc);
    	case (Type)`string`:
    	    return string(src=t@\loc);
    	default: throw "Unhandled type: <t>";
	}
}
