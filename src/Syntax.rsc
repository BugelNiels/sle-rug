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
  = Str question Id param ":" Type type 					// Question
  | Str question Id param ":" Type type "=" Expr expr		// Computed question
  | Block block
  | "if" "(" Comparison comp ")" Block block
  | "if" "(" Comparison comp ")" Block if "else" Block else
  ;
  
syntax Block = "{" Question* "}";

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Addition
  | Disjunction
  | Comparison
  ;
  
syntax Comparison
  = Addition "\>" Addition
  | Addition "\<" Addition
  | Addition "\>=" Addition
  | Addition "\<=" Addition
  | Addition "==" Addition
  | Addition "!=" Addition
  | Disjunction "==" Disjunction
  | Disjunction "!=" Disjunction
  | Disjunction
  ;
  
syntax Addition
  = Subtraction "+" Subtraction
  | Subtraction
  ;
  
syntax Subtraction
  = Multiplication "-" Multiplication
  | Multiplication
  ;
  
syntax Multiplication
  = Division "*" Division
  | Division
  ;
  
syntax Division
  = Atom "/" Atom
  | Atom
  ;
  
syntax Atom
  = Int
  | "(" Addition ")"
  | Id \ "true" \ "false" // true/false are reserved keywords.
  ;
  
syntax Disjunction
  = Conjunction "||" Conjunction
  | Conjunction
  ;  
  
syntax Conjunction
  = Literal "&&" Literal
  | Literal
  ;
  
syntax Literal
  = Bool
  | "!" Bool
  | Id \ "true" \ "false" // true/false are reserved keywords.
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
  | "(" Disjunction ")"
  ;



