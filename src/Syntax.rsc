module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = 
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | ValExpr
  | BoolExpr
  ;

syntax ValExpr
  =  "(" ValExpr ")"
  | ValExpr "+" ValExpr
  | ValExpr "-" ValExpr
  | Term
  ;

syntax BoolExpr
  = "(" BoolExpr ")"
  | "!" BoolExpr
  | BoolExpr "&&" BoolExpr
  | BoolExpr "||" BoolExpr
  | Bool  
  ;
  
syntax Disjunction
  = Conjunction "||" Conjunction
  | Conjunction
  ;  
  
syntax Conjunction
  = Disjunction "&&" Disjunction
  | Disjunction
  ;
  
syntax Literal
  = Bool
  | "!" Bool
  ;
    

syntax Term
  = Term "*" Term
  | Term "/" Term  
  | Int
  ;
  
syntax Type
  = ;  
  
lexical Str = ;

lexical Int 
  = ;

lexical Bool
  = "True"
  | "False"
  | Disjunction;



