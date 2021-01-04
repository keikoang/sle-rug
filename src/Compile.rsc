/* for testing
import ParseTree;
import Syntax;
l = //copy source location//;
pt = parse(#start[Form], l);
import CST2AST;
ast = cst2ast(pt);
import Compile;
compile(ast);
*/
module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  	head(title("QL in HTML5")),
  	body(
  		div(
  			h1("Questionnaire <f.name>"),
  			div([question2html(question) | \AQuestion question <- f.questions])
  		)
  	),
  	footer(script(src(f.src[extension="js"].file)))
  );
}

HTML5Node question2html(AQuestion q) {
	switch(q) {	
		case normal_question(str label, AId ident, AType qtype):
			return div(
				class("NormalQuestion"),
				p(label),
				input(id(ident.name), type2html(qtype))
			);
		case computed_question(str label, AId ident, AType qtype, AExpr expr):
			return div(
				class("ComputedQuestion"),
				p(label),
				textarea(id(ident.name), html5attr("readonly",""))
			);
		case block(list[AQuestion] questions):
			return div([question2html(question) | \AQuestion question <- questions] + [class("Block")] );
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions):
			return div(
				class("IfElse"),
				div([question2html(question) | \AQuestion question <- trueQuestions]),
				div([question2html(question) | \AQuestion question <- falseQuestions])
			);		
		case if_then(AExpr condition, list[AQuestion] trueQuestions):
			return div(
				class("If"),
				div([question2html(question) | \AQuestion question <- trueQuestions])
			);
	}
	return div();
}

HTML5Attr type2html(AType qtype) {
	switch(qtype){
		case boolean():
			return \type("checkbox");
		case integer(): 
			return \type("number");
		case string():
			return \type("text");
	}
	return \type("");
}


str form2js(AForm f) {
  return "function <f.name> () {\n" 
  + questions2js(f.questions) 
  + "\n}\n" ;
}

str questions2js(list[AQuestion] questions) {
	str jsQuestions = "";
	for (AQuestion question <- questions){ 
		jsQuestions += questions2js(question);
	}
	return jsQuestions;
}

str question2js(AQuestion question) {
	str jsQuestion = "";
	switch(question) {	
		case normal_question(str label, AId ident, AType qtype):
			return "function <ident.name> () {\n"
			 + "\t return " + type2js(qtype, ident.name) + ";"
			 + "\n}\n";
		case computed_question(str label, AId ident, AType qtype, AExpr expr):
			return "function <ident.name> () {\n"
			+ "\t return " + expr2js(expr) + ";"
			+ "\n}\n";	
		case block(list[AQuestion] questions):
			return questions2js(questions);
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions):
			jsQuestion += questions2js(trueQuestions) + questions2js(falseQuestions);
		case if_then(AExpr condition, list[AQuestion] trueQuestions):
			jsQuestion += questions2js(trueQuestions);
	}
	return jsQuestion;
}

str type2js(AType qtype, str identName) {
	str jsType = "";
	switch(qtype) {
		case integer():
			jsType += "parseInt(document.getElementById(\"<identName>\").value)";
		case boolean():
			jsType += "document.getElementById(\"<identName>\").checked";
		case string():
			jsType += "document.getElementById(\"<identName>\").value";
	}
	return jsType;
}

str expr2js(AExpr expr) {
	switch(expr) {
		case ref(id(str name)) :
			return " <name> ";
		case boolean(bool b):
			return " " + toString(b) + " ";
		case integer(int n):
			return " " + toString(n) + " ";
		case string(str s):
			return " <s> "; 
		case pars(AExpr e):
			return "(" 	+ expr2js(e) + ")";
		case not(AExpr e):
			return "!" + expr2js(e);
		case mul(AExpr left, AExpr right):
			return expr2js(left) + "*" + expr2js(right);
		case div(AExpr left, AExpr right):
			return expr2js(left) + "/" + expr2js(right);
		case add(AExpr left, AExpr right):
			return expr2js(left) + "+" + expr2js(right);
		case sub(AExpr left, AExpr right):
			return expr2js(left) + "-" + expr2js(right);
		case eq(AExpr left, AExpr right):
			return expr2js(left) + "==" + expr2js(right);
		case neq(AExpr left, AExpr right):
			return expr2js(left) + "!=" + expr2js(right);
		case gt(AExpr left, AExpr right):
			return expr2js(left) + "\>" + expr2js(right);
		case lt(AExpr left, AExpr right):
			return expr2js(left) + "\<" + expr2js(right);
		case leq(AExpr left, AExpr right):
			return expr2js(left) + "\<=" + expr2js(right);
		case geq(AExpr left, AExpr right):
			return expr2js(left) + "\>=" + expr2js(right);
		case and(AExpr left, AExpr right):
			return expr2js(left) + "&&" + expr2js(right);
		case or(AExpr left, AExpr right):
			return expr2js(left) + "||" + expr2js(right);
	}
}