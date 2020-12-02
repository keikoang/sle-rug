module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

//visit all AExpr to get the source and name(id)
Use uses(AForm f) {
	return {<e.src, e.id.name> | /AExpr e := f.questions, e has id};
    //return {<id.src, id.name> | /ref(AId id) := f}; 
}

//visit all normal_question and computed_question
Def defs(AForm f) {
	return {<q.ident.name, q.src> | /AQuestion q := f.questions, q has ident};
    /*return {<id.name, id.src> | /normal_question(_, AId id, _) := f} 
    + {<id.name, id.src> | /computed_question(_, AId id, _, _) := f}; */
}