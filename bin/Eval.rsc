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
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for (AQuestion aq <- f.questions, aq has t) {
    switch (aq.t) {
      case integer():
      	venv += (aq.param.name: vint(0));
      case boolean():
      	venv += (aq.param.name: vbool(false));
      case string():
      	venv += (aq.param.name: vstr(""));
      default:
      	throw "Unexpected Type <aq.t>";
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
  for (AQuestion aq <- f.questions) {
    venv += eval(aq, inp, venv);
  }
  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch(q) {  
	case question(str ques, AId param, AType t): 
		if (param.name == inp.question) {
			return (param.name: inp.\value);
		}
	case compQuestion(str ques, AId param, AType t, AExpr exp): 
		return (param.name: eval(exp, venv)); 
		
	case ifStatement(AExpr exp, list[AQuestion] questions): { 
		if (eval(exp, venv) == vbool(true)) {
			for (AQuestion aq <- questions) {
				venv += eval(aq, inp, venv);
			}
		}
		return venv;
	}
		
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): { 
		if (eval(exp, venv) == vbool(true)) {
			for (AQuestion aq <- ifQuestions) {
				venv += eval(aq, inp, venv);
			}
		}
		else {
			for (AQuestion aq <- elseQuestions) {
				venv += eval(aq, inp, venv);
			}
		}
		return venv;
	}
	
	default: 
		return venv;
  }
  
  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): 					return venv[x];
    case integer(int n): 				return vint(n);
    case boolean(bool b): 				return vbool(b);
    case brackets(AExpr e): 			return vint(eval(e, venv).n);
    case not(AExpr e): 					return vbool(!eval(e, venv).n);
    case mult(AExpr l, AExpr r): 		return vint(eval(l, venv).n * eval(r, venv).n);
    case div(AExpr l, AExpr r): 		return vint(eval(l, venv).n / eval(r, venv).n);
    case add(AExpr l, AExpr r): 		return vint(eval(l, venv).n + eval(r, venv).n);
    case subtract(AExpr l, AExpr r): 	return vint(eval(l, venv).n - eval(r, venv).n);
	case greater(AExpr l, AExpr r): 	return vbool(eval(l, venv).n > eval(r, venv).b);
	case less(AExpr l, AExpr r): 		return vbool(eval(l, venv).n < eval(r, venv).b);
	case greq(AExpr l, AExpr r): 		return vbool(eval(l, venv).n >= eval(r, venv).b);
	case les(AExpr l, AExpr r): 		return vbool(eval(l, venv).n <= eval(r, venv).b);
	case eq(AExpr l, AExpr r): 			return vbool(eval(l, venv).n == eval(r, venv));
	case neq(AExpr l, AExpr r): 		return vbool(eval(l, venv).n != eval(r, venv));
	case conj(AExpr l, AExpr r): 		return vbool(eval(l, venv).n && eval(r, venv).b);
	case disj(AExpr l, AExpr r): 		return vbool(eval(l, venv).n || eval(r, venv).b);
	
    
    default: throw "Unsupported expression <e>";
  }
}