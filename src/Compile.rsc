module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  	head(
  		title(f.id.name),
  		script(src(f.src[extension="js"].file))
  	),
  	body(
  	  parseQuestions2html(f.questions, div(id("questions")))
  	)
  );
}

HTML5Node parseQuestions2html(list[AQuestion] qq, HTML5Node parent) {
	for(AQuestion q <- qq){
		parent.kids += [question2html(q)];
	}
	
	return parent;
}

HTML5Node question2html(AQuestion q) {
  switch(q) {  
	case question(str ques, AId param, AType t): 
		return questionInput2html(q, false);
	case compQuestion(str ques, AId param, AType t, AExpr exp): 
		return questionInput2html(q, true);
	case ifStatement(AExpr exp, list[AQuestion] qq):
		return parseQuestions2html(qq, div());
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):{
		ifDiv = parseQuestions2html(ifQuestions, div());
		elseDiv = parseQuestions2html(elseQuestions, div());
		parentDiv = div();
		parentDiv.kids += [ifDiv, elseDiv];
		return parentDiv;
		}
	default: 
		return div();
  }
  
  return div();
}


HTML5Node questionInput2html(AQuestion q, bool dis) {
	HTML5Attr inputType;
	
	switch(q.t) {
		case integer() :
			inputType =  \type("integer"); 
		case boolean() :
			inputType =  \type("checkbox"); 
		case string() :
			inputType =  \type("text"); 
	}
	
	HTML5Node inputLabel;
	if(dis){
		inputLabel = input(inputType, name("<q.param.name>"), disabled("disabled"));
	}else{
		inputLabel = input(inputType, name("<q.param.name>"));
	}
	
	return div(
		label(\for("<q.param.name>"), q.ques),
		inputLabel,
		br()
	);
}

str form2js(AForm f) {
  return "";
}
