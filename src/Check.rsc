module Check

import Set;
import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
Type resolveType(booleanType()) = tbool();
Type resolveType(integerType()) = tint();
Type resolveType(stringType()) = tstr();
default Type resolveType(AType _) = tunknown();

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  return {<q.src, q.param.name, q.ques, resolveType(q.t)> | /AQuestion q := f.questions, q has param};
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return 
  	{check(q, tenv, useDef) | /AQuestion q := f.questions, q has id}	// Check for each question if it has an id
  	+ {check(exp, tenv, useDef) | /AExpr exp := f}						// Check for each expression
  	;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  return
  	{ error("Question <q.id> already exists with a different type", q.src) | q has id, size(tenv[_, q.id, _]) >= 2 }
  	+ { warning("Duplicate label <q.lbl> found", q.src) | q has lbl, size((tenv<2,0>)[q.ques] >= 2) }
  	+ { error("The declared type of the computed question <q.id> does not match the type of the expression", q.src) | q has computedExpr, resolveType(q.questionType) != typeOf(q.computedExpr, tenv, useDef) };
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case mult(lhs, rhs):
      msgs += { error("Invalid multiplication", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case div(lhs, rhs):
      msgs += { error("Invalid division", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case add(lhs, rhs):
      msgs += { error("Invalid addition", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case subtract(lhs, rhs):
      msgs += { error("Invalid subtraction", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case greater(lhs, rhs):
      msgs += { error("Invalid comparison", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case less(lhs, rhs):
      msgs += { error("Invalid comparison", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case greq(lhs, rhs):
      msgs += { error("Invalid comparison", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case leq(lhs, rhs):
      msgs += { error("Invalid comparison", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tint() };
    case eq(lhs, rhs):
      msgs += { error("Invalid equality comparison", x.src) | typeOf(lhs) != typeOf(rhs) || (typeOf(lhs) != tint() && typeOf(lhs) != tbool()) };
    case neq(lhs, rhs):
      msgs += { error("Invalid equality comparison", x.src) | typeOf(lhs) != typeOf(rhs) || (typeOf(lhs) != tint() && typeOf(lhs) != tbool()) };
    case conj(lhs, rhs):
      msgs += { error("Invalid conjunction", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tbool() };
    case disj(lhs, rhs):
      msgs += { error("Invalid disjunction", x.src) | typeOf(lhs) != typeOf(rhs) || typeOf(lhs) != tbool() };
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case integer(_): 				return tint();
    case boolean(_): 				return tbool();
    case brackets(AExpr expr):		return typeOf(expr, tenv, useDef);
    case mult(_, _):				return tint();
    case div(_, _):					return tint();
    case add(_, _):					return tint();
    case subtract(_, _):			return tint();
    case greater(_, _):				return tbool();
    case less(_, _):				return tbool();
    case greq(_, _):				return tbool();
    case leq(_, _):					return tbool();
    case eq(_, _):					return tbool();
    case neq(_, _):					return tbool();
    case conj(_, _):				return tbool();
    case disj(_, _):				return tbool();
    default:						return tunknown();
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