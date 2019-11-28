module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id Block; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str question Id param ":" Type type 					// Question
  | Str question Id param ":" Type type "=" Expr exp	
  | Block block
  | "if" "(" Expr comp ")" Block block
  | "if" "(" Expr comp ")" Block if "else" Block else
  ;
  
syntax Block = "{" Question* "}";

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | "(" Expr e ")"
  | left (left Expr l "*" Expr r
  		 | Expr l "/" Expr r
  		 )
  > left ( left Expr l "+" Expr r
         | Expr l "-" Expr r
         )
  | left ( left Expr l "\>" Expr r
  		 | Expr l "\<" Expr r
  		 | Expr l "\>=" Expr r
  		 | Expr l "\<=" Expr r
  		 | Expr l "==" Expr r
  		 | Expr l "!=" Expr r
  		 )
  | Int
  | Bool
  ;
  
syntax Type
  = "string"
  | "integer"
  | "boolean"
  ;
  
lexical Str
  = "\"" ![\"]* "\"";

lexical Int
  = [1-9][0-9]*
  | [0]
  ;

lexical Bool
  = "true"
  | "false"
  ;


