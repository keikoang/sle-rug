module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  | vunknown()
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
Value astType2Value (AType ty) {
	switch (ty) {
		case boolean():
			return vbool(false);
		case integer():
			return vint(0);
		case string():
			return vstr("");
	}
	return vunknown();
}  
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
	VEnv venv = ();
	for (/AQuestion aQuestion := f.questions){
		switch(aQuestion){
			case normal_question(str _, AId id, AType ty):
				venv += (id.name : astType2Value(ty));
			case computed_question(str _, AId id, AType ty, AExpr _):
				venv += (id.name : astType2Value(ty));
		}
	}
  	return venv;
}
// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}
VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  	for (/AQuestion aQuestion := f.questions) {
  		venv = eval(aQuestion, inp, venv);
  	}
  	return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  	switch (q) {
  		case normal_question(str _, AId id, AType _):
  			if (id.name == inp.question) return (venv + (id.name : inp.\value));
  		case computed_question(str _, AId id, AType _, AExpr expr):
  			return (venv + (id.name : eval(expr, venv)));
  		case block(list[AQuestion] aQuestions):
  			for(/AQuestion aQuestion := aQuestions) {
  				venv = eval(aQuestion, inp, venv);
  			}
  		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions):
  			if (eval(condition, venv).b){
  				for (/AQuestion tQuestion := trueQuestions){
  					venv = eval(tQuestion, inp, venv);
  				}
  			} else {
  				for (/AQuestion fQuestion := falseQuestions){
  					venv = eval(fQuestion, inp, venv);
  				}
  			}
  		case if_then(AExpr condition, list[AQuestion] trueQuestions):
  			if (eval(condition, venv) == vbool(true)){
  				for (/AQuestion tQuestion := trueQuestions){
  					venv = eval(tQuestion, inp, venv);
  				}
  			}
  	}
 	return venv; 
}
Value eval(AExpr e, VEnv venv) {
  switch (e) {
  		case ref(AId x): return venv[x.name];
    	case boolean(bool boolValue): return vbool(boolValue);
    	case integer(int intValue): return vint(intValue);
    	case string(str strValue): return vstr(strValue);
    	case pars(AExpr expr): return eval(expr, venv);
    	case not(AExpr expr): return vbool(!eval(expr, venv).b);
    	case mul(AExpr leftExpr, AExpr rightExpr):
    		return vint(eval(leftExpr, venv).n * eval(rightExpr, venv).n);
    	case div(AExpr leftExpr, AExpr rightExpr):
    		return vint(eval(leftExpr, venv).n / eval(rightExpr, venv).n);
    	case add(AExpr leftExpr, AExpr rightExpr):
    		return vint(eval(leftExpr, venv).n + eval(rightExpr, venv).n);    	    
    	case sub(AExpr leftExpr, AExpr rightExpr):
    		return vint(eval(leftExpr, venv).n - eval(rightExpr, venv).n);
    	case eq(AExpr leftExpr, AExpr rightExpr):
			switch(eval(leftExpr, venv)) {
				case vbool(bool leftBool): return vbool(leftBool == eval(rightExpr, venv).b);
				case vint(int leftInt): return vbool(leftInt == eval(rightExpr, venv).n);
				case vstr(str leftStr): return vbool(leftStr == eval(rightExpr, venv).s);			
			}
		case neq(AExpr leftExpr, AExpr rightExpr):
			switch(eval(leftExpr, venv)) {
				case vbool(bool leftBool): return vbool(leftBool != eval(rightExpr, venv).b);
				case vint(int leftInt): return vbool(leftInt != eval(rightExpr, venv).n);
				case vstr(str leftStr): return vbool(leftStr != eval(rightExpr, venv).s);			
			}
		case gt(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).n > eval(rightExpr, venv).n);
    	case lt(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).n < eval(rightExpr, venv).n);
    	case geq(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).n >= eval(rightExpr, venv).n);
    	case leq(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).n <= eval(rightExpr, venv).n);
    	case and(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).b && eval(rightExpr, venv).b);
    	case or(AExpr leftExpr, AExpr rightExpr):
    		return vbool(eval(leftExpr, venv).b || eval(rightExpr, venv).b);
    default: throw "Unsupported expression <e>";
  }
  return vunknown();  
}

/* for testing
   import ParseTree;
   import Syntax;
   l = //copy source location//;
   pt = parse(#start[Form], l);
   import CST2AST;
   ast = cst2ast(pt);
   import Eval;
   inp = input("sellingPrice", vint(30));
   venv = intialEnv(ast);
   evaluated = eval(ast, inp, venv);
*/
