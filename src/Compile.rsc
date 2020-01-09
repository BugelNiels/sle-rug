module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import util::Math;
import Boolean;

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
  		script(src("https://code.jquery.com/jquery-3.4.1.min.js")),
  		script(src(f.src[extension="js"].file)),
  		link(\rel("stylesheet"), src("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"))
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
	case ifStatement(AExpr exp, list[AQuestion] qq): {
		parentDiv = div(id("if-" + exp2html(exp)));
		
		return parseQuestions2html(qq, parentDiv);
		}
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):{
		ifDiv = parseQuestions2html(ifQuestions, div(id("if-" + exp2html(exp))));
		elseDiv = parseQuestions2html(elseQuestions, div(id("else-" + exp2html(exp))));
		parentDiv = div();
		parentDiv.kids += [ifDiv, elseDiv];
		return parentDiv;
		}
	default: 
		return div();
  }
  
  return div();
}

str exp2html(exp){
	switch (exp) {
	    case ref(AId id): 					return id.name;
	    case integer(int n): 				return toString(n);
	    case boolean(bool b): 				return toString(b);
	    case brackets(AExpr e): 			return "("+ exp2html(e) + ")";
	    case not(AExpr e): 					return "!"+ exp2html(e);
	    case mult(AExpr l, AExpr r): 		return exp2html(l) + "*" + exp2html(r);
	    case div(AExpr l, AExpr r): 		return exp2html(l) + "/" + exp2html(r);
	    case add(AExpr l, AExpr r): 		return exp2html(l) + "+" + exp2html(r);
	    case subtract(AExpr l, AExpr r): 	return exp2html(l) + "-" + exp2html(r);
		case greater(AExpr l, AExpr r): 	return exp2html(l) + "\>" + exp2html(r);
		case less(AExpr l, AExpr r): 		return exp2html(l) + "\<" + exp2html(r);
		case greq(AExpr l, AExpr r): 		return exp2html(l) + "\>=" + exp2html(r);
		case les(AExpr l, AExpr r): 		return exp2html(l) + "\<=" + exp2html(r);
		case eq(AExpr l, AExpr r): 			return exp2html(l) + "==" + exp2html(r);
		case neq(AExpr l, AExpr r): 		return exp2html(l) + "!=" + exp2html(r);
		case conj(AExpr l, AExpr r): 		return exp2html(l) + "&&" + exp2html(r);
		case disj(AExpr l, AExpr r): 		return exp2html(l) + "||" + exp2html(r);
		
	    
	    default:throw "Unsupported expression <exp>";
  }
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
		inputLabel = input(inputType, name("<q.param.name>"), id("<q.param.name>"), disabled("disabled"));
	}else{
		inputLabel = input(inputType, name("<q.param.name>"), id("<q.param.name>"));
	}
	
	return div(
		label(\for("<q.param.name>"), q.ques),
		inputLabel,
		br()
	);
}

str form2js(AForm f) {
  return hideFunction() + allVariables2js(f.questions) + "console.log(\'start\');\n" + parseAllQuestions2js(f.questions);
}

str hideFunction(){
	return "function hideDiv(divId, hide){
	var x = document.getElementById(divId);
	if (!hide) {
		x.style.display = \"block\";
	} else {
		x.style.display = \"none\";
	}
}\n" ;
}

str parseAllQuestions2js(list[AQuestion] qq){
	str newData = "$(function(){
   $(\':input\').change(function(e){
   		updateValues();
   	});
});
function updateValues(){\n";
	newData += parseQuestions2js(qq);
	newData += "}
$( document ).ready(function() {
	updateValues();
    console.log(\"ready!\" );
});\n";
	return newData;
}

str parseQuestions2js(list[AQuestion] qq) {
	str newData = "";
	for(AQuestion q <- qq){
		newData += question2js(q);
	}
	return newData;
}

str question2js(AQuestion q) {
  switch(q) {
  	case question(str ques, AId param, AType t):
  		return param.name + " = document.getElementById(\'"+ param.name +"\')." + type2jsInput(t) + ";\n";
	case compQuestion(str ques, AId param, AType t, AExpr exp): 
		return param.name + " = "+ exp2html(exp) + ";
		document.getElementById(\'"+ param.name +"\')." + type2jsInput(t) + " = " + param.name + ";\n";
	case ifStatement(AExpr exp, list[AQuestion] qq): {
		ifPart = parseQuestions2js(qq);
		str expStr =  exp2html(exp);
		parentPart =  "hideDiv(\'if-"+ expStr+"\',!("+ expStr +"));\n";
		return parentPart + ifPart; 
		}
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):{
		ifPart = parseQuestions2js(ifQuestions);
		elsePart = parseQuestions2js(elseQuestions);
		parentPart = "hideDiv(\'if-"+ expStr+"\',!("+ expStr +"));
	hideDiv(\'else-"+ expStr+"\',("+ expStr +"));\n";
		return parentPart + ifPart + elsePart;
		}
	default: 
		return "";
  }
  
  return "";
}

str allVariables2js(list[AQuestion] qq) {
	str newData = "";
	for(AQuestion q <- qq){
		newData += variables2js(q);
	}
	return newData;
}

str variables2js(AQuestion q) {
  switch(q) {
  	case question(str ques, AId param, AType t): 
		return "var " + param.name + " = " + type2js(t) + ";\n";
	case compQuestion(str ques, AId param, AType t, AExpr exp): 
		return "var " + param.name + " = " + type2js(t) + ";\n";
	case ifStatement(AExpr exp, list[AQuestion] qq): {
		return allVariables2js(qq); 
		}
	case ifElseStatement(AExpr exp, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):{
		ifPart = allVariables2js(ifQuestions);
		elsePart = allVariables2js(elseQuestions);
		return ifPart + elsePart;
		}
	default: 
		return "";
  }
  
  return "";
}

str type2js(AType t){
	switch(t){
		case integer(): return "0";
		case boolean(): return "false";
		case string(): return "";
		default: return "";
	}
}

str type2jsInput(AType t){
	switch(t){
		case integer(): return "value";
		case boolean(): return "checked";
		case string(): return "value";
		default: return "";
	}
}