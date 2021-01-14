module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import IO;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
   return form(f.name, flatten(f.questions, boolean(true)));
}

list[AQuestion] flatten(list[AQuestion] aQuestions, AExpr expr){
	return ([] | it + flatten(aQuestion, expr) | /AQuestion aQuestion := aQuestions);
}

list[AQuestion] flatten(AQuestion aQuestion, AExpr expr) {
	list[AQuestion] returnQuestions = [];
	switch (aQuestion) {
		case normal_question(str _, AId _, AType _):
			returnQuestions += if_then(expr, [aQuestion]);
		case computed_question(str _, AId _, AType _, AExpr _):
			returnQuestions += if_then(expr, [aQuestion]);
		case block(list[AQuestion] blockQuestions):
			returnQuestions += flatten(blockQuestions, expr);
		case if_then(AExpr condition, list[AQuestion] trueQuestions):
			returnQuestions += flatten(trueQuestions, and(condition, expr));
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions):
			returnQuestions += flatten(trueQuestions, and(condition, expr)) + flatten(falseQuestions, and(not(condition), expr));
	}
	return returnQuestions;
}


/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   	Id newId;
   	try {
   	 newId = [Id]newName;
   	} catch: {
   		print("The entered name is invalid to use for replacing");
   		return f;
   	}
   	AForm ast = cst2ast(f);
   	str oldName = getOldName(ast, useOrDef);
   	return visit(f) {
   		case (Id)`<Id thisId>` => newId when "<thisId>" == oldName
   	}
} 
 
str getOldName(AForm form, loc useOrDef) {
	visit (form) {
		case normal_question(str _, AId id,  AType _, src = loc s):
			if (s == useOrDef) {
				return id.name;
			}
		case computed_question(str _, AId id,  AType _, AExpr _, src = loc s):
			if (s == useOrDef) {
				return id.name;
			}
		case ref(id,src = loc s) :
			if (s == useOrDef) {
				return id.name;
			}
	}
	return " ";
} 
 
 