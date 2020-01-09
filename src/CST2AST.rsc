module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

import IO;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf)
  = cst2ast(sf.top);

AForm cst2ast(f:(Form)`form <Id name> { <Question* qq> }`) 
	= form(cst2ast(name),[ cst2ast(q) | Question q <- qq ],src=f@\loc);

AQuestion cst2ast(Question q) {
  switch (q) {
  	case (Question)`<Str q1> <Id param> : <Type t>`:
  		return question("<q1>", cst2ast(param), cst2ast(t), src=q@\loc);
  	case (Question)`<Str q1> <Id param> : <Type t> = <Expr exp>`: 
		return compQuestion("<q1>", cst2ast(param), cst2ast(t), cst2ast(exp), src=q@\loc);
	case (Question)`if ( <Expr exp> ) { <Question* qq> }`: 
		return ifStatement(cst2ast(exp), [cst2ast(q1) | q1 <- qq], src=q@\loc);
	case (Question)`if ( <Expr exp> ) { <Question* ifqq> } else { <Question* elseqq> }`: 
		return ifElseStatement(cst2ast(exp), [cst2ast(q1) | q1 <- ifqq], [cst2ast(q2) | q2 <- elseqq], src=q@\loc);

    default: throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`                      	: return ref(cst2ast(x), src=x@\loc);
    case (Expr)`<Int i>`                     	: return integer(toInt("<i>"), src=i@\loc);
    case (Expr)`<Bool b>`                    	: return boolean(fromString("<b>"), src=b@\loc);    
    case (Expr)`(<Expr exp>)`                	: return brackets(cst2ast(exp), src=e@\loc);
    case (Expr)`!<Expr exp>`                	: return not(cst2ast(exp), src=e@\loc);
    case (Expr)`<Expr left> * <Expr right>`  	: return mult(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> / <Expr right>`  	: return div(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> + <Expr right>`  	: return add(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> - <Expr right>`  	: return subtract(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> \> <Expr right>` 	: return greater(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> \< <Expr right>` 	: return less(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> \>= <Expr right>`	: return greq(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> \<= <Expr right>`	: return leq(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> == <Expr right>` 	: return eq(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> != <Expr right>` 	: return neq(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> && <Expr right>` 	: return conj(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> || <Expr right>` 	: return disj(cst2ast(left), cst2ast(right), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
  	case (Type)`integer`: return integer(src=t@\loc);
  	case (Type)`boolean`: return boolean(src=t@\loc);
  	case (Type)`string` : return string(src=t@\loc);
  	
    default: throw "Unhandled type: <t>";
  }
}

AId cst2ast((Id)`<Id d>`) = id("<d>", src=d@\loc);
