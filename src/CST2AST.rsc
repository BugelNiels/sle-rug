module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

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
  
AForm cst2ast((Form)`form <Id name> { <Question* qq> }`)
	= form(id("<name>"),[ cst2ast(q) | Question q <- qq]);
  
AQuestion cst2ast((Question)` <Str question> <Id param> : <Type t>`) 
	= question(string("<question>"), id("<param>"), typ("<t>"));
	
AQuestion cst2ast((Question)` <Str question> <Id param> : <Type t> = <Expr exp>`) 
	= compQuestion(string("<question>"), id("<param>"), typ("<t>"), cst2ast(exp));
	
AQuestion cst2ast((Question)` if (<Expr exp>) { <Question* qq> }`) 
	= ifStatement(string("<question>"), id("<param>"), typ("<t>"));
	
AQuestion cst2ast((Question)` if (<Expr exp>) { <Question* ifqq> } else { <Question* elseqq> }`) 
	= ifElseStatement(string("<question>"), id("<param>"), typ("<t>"));

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast((Type)`<Type t>`) = typ("test");
