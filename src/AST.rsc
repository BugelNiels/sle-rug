module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId id, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str ques, AId param, AType t)
  | compQuestion(str ques, AId param, AType t, AExpr exp)
  | ifStatement(AExpr exp, list[AQuestion] questions)
  | ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | integer(int vali)
  | boolean(str valb)
  | brackets(AExpr expr)
  | mult(AExpr left, AExpr right)
  | div(AExpr left, AExpr right)
  | add(AExpr left, AExpr right)
  | subtract(AExpr left, AExpr right)
  | greater(AExpr left, AExpr right)
  | less(AExpr left, AExpr right)
  | greq(AExpr left, AExpr right)
  | leq(AExpr left, AExpr right)
  | eq(AExpr left, AExpr right)
  | neq(AExpr left, AExpr right)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);
  
data AType(loc src = |tmp:///|)
  = integer()
  | boolean()
  | string()
  ;
  

