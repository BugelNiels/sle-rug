module Transform

import Syntax;
import Resolve;
import AST;
import IO;
import ParseTree;
import Map;
import Set;

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
  f.questions = flattenQuestions(f.questions, boolean(true));
  return f; 
}

list[AQuestion] flattenQuestions(list[AQuestion] qq, AExpr exp) {
  list[AQuestion] questions = [];
  for(q <- qq) {
    questions += flattenQuestion(q, exp);
  }
  return questions;
}

list[AQuestion] flattenQuestion(AQuestion q, AExpr expr) {
  switch(q) {  
    case question(str ques, AId param, AType t): {
	  return [ifStatement(expr,[q])];
	}
	case compQuestion(str ques, AId param, AType t, AExpr exp):
	  return [ifStatement(expr,[q])];
	case ifStatement(AExpr exp, list[AQuestion] questions): { 
	  return flattenQuestions(questions,conj(expr, brackets(exp)));
	}
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): { 
	  return flattenQuestions(ifQuestions, conj(expr, brackets(exp))) + flattenQuestions(elseQuestions, conj(expr, brackets(exp)));
	}
	default: 
	  return [];
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
Form rename(Form f, loc useOrDef, str newName, RefGraph refs) {
  loc def;
  if(isEmpty(refs.useDef[useOrDef])) {
    def = useOrDef;
  } else {
    def = toList(refs.useDef[useOrDef])[0];
  }
  return visitAll(f, def, newName, refs);
} 
 
bool isValidId(str name){
  try {
    parse(#Id, name);
	return true;
  } catch: 
      return false;
}
 
Form visitAll(Form f, loc defn, str newName, RefGraph refs) { 
  if(!isValidId(newName)) {
    return f;
  }
  
  Id newId = [Id]newName;
  return visit (f) {
    case (Expr)`<Id x>` 
      => (Expr)`<Id newId>`
     
      when 
        <loc use, defn> <- refs.useDef,
        use == x@\loc
     case (Question)`<Str q1> <Id param> : <Type t>` 
       => (Question)`<Str q1>
      				'      <Id newId> : <Type t>`
	   when 
	     <str name, defn> <- refs.defs,
         param == [Id]name
  	 case (Question)`<Str q1> <Id param> : <Type t> = <Expr exp>` 
  	   => (Question)`<Str q1> 
  	   				'      <Id newId> : <Type t>`
	   when 
	     <str name, defn> <- refs.defs,
         param == [Id]name
  } 
  return f;
}
 

