module slisp;

@safe

import std.stdio;
alias std.stdio.writeln wl;

abstract class SExpression {

}

// need this wrapper to avoid a bug which doesn't let you
// "enum" a class 
struct SWrapper {
	SExpression expression;
	alias expression this;
	string toString(){return expression.toString();}
}

class SList : SExpression {
	SExpression[] list;
	this() {}
	this(SExpression[] _list) {list=_list;}
	override string toString() { 
		import std.array:join;		
		import std.format:format;
		import std.algorithm:map;
		return format("[ %s ]",list.map!(x=>x.toString()).join(" , ")); }
	alias list this;
}

class SInteger : SExpression {
	int value;
	this(int _value) {value=_value;}
	override string toString() {import std.conv; return to!string(value); }
}

class SFloat : SExpression {
	float value;
	string svalue; // hold the string version as well, because we can't work this out at CT
	this(float _value, string _svalue) {value=_value; svalue=_svalue;}
	override string toString() { return svalue; }
}
class SString : SExpression {
	string value;
	this(string _value) {value=_value;}
	override string toString() { import std.format; return format("\"%s\"",value); }
}

class SSymbol : SExpression {
	string name;
	this(string _value) {name=_value;}
	override string toString() { return name; }
}

auto tokenize(string input) {
  import std.string;
  import std.array : array;
  import std.algorithm : filter, map;
  return
    input
      .replace("(", " ( ")
      .replace(")", " ) ")      
      .split(" ")
      .map!(strip)
      .filter!(x => x != "")
      .array;
}

SExpression parseAtom(string atom) {
  import std.conv : to;
  try {
    auto x = to!int(atom);
    return new SInteger(x);    
  } catch {}
  try {
    auto x = to!float(atom);
    return new SFloat(x,atom);    
  } catch {}
  return new SSymbol(atom);
}

SExpression parse(string[] tokens) {  
  SExpression aux() {
	  auto token = tokens[0];
	  tokens = tokens[1..$];
	  switch( token ) {
	    case "(" :
	      auto next = new SList();
	      while(tokens[0] != ")")
	         next ~= aux();
	      tokens = tokens[1..$];
	      return next;
	    case ")" :
	      throw new Exception("unexpected )");
	    default :
	      return parseAtom(token);	
	  }
  }
  return aux();
}

struct function_data{
  string type;
  int minargs;
  int maxargs;
}

enum function_map = 
  [ "-" : function_data("op",1,2),
    "+" : function_data("op",1,2),
    "*" : function_data("op",2,2),
    "/" : function_data("op",2,2),
    ">" : function_data("op",2,2),
    "<" : function_data("op",2,2),
    "=" : function_data("op",2,2),
    "<=" : function_data("op",2,2),
    ">=" : function_data("op",2,2),
    "!=" : function_data("op",2,2),
    "rnd" : function_data("func",2,2),
    "WRAPP" :function_data("func",2,2),
    "cos" :function_data("func",1,1),
    "sin" :function_data("func",1,1)
  ];

alias rnd = std.random.uniform;

string compile(SExpression tokens) {
  import std.conv : to;
  import std.string : join, format;
  import std.algorithm : map, reduce, castSwitch;  

  string aux(SExpression token) {
	// unforutnately, "castSwitch" does not seem to work with CTFE
	// this is not pretty. really miss pattern matching!! :(
  	if( auto x = cast(SInteger)token) {
	  	return x.to!string;
  	} else if(auto x = cast(SFloat)token) {
	  	return x.to!string;
  	} else if(auto x = cast(SString)token) {
	  	return format("\"%s\"", x);
  	} else if(auto x = cast(SSymbol)token){
	  	return x.name;
  	} else if(auto tks = cast(SList)token){
  		// todo: handle empty lists?  		
  		auto symbol = cast(SSymbol)tks[0];
		assert(symbol, "lists must begin with a symbol");
		switch(symbol.name){
			//handle special forms
	        case "define":
	          return format("auto %s = %s",aux(tks[1]), aux(tks[2]));
	        case "if":
	          	return
	                format(
	                  q{if( %s ) {
	                      %s
	                    } else {
	                      %s
	                    }
	                  },
	                  aux(tks[1]),
	                  aux(tks[2]),
	                  aux(tks[3]));                
            case "set":
            	auto fargs = tks[1..$];
        		assert(fargs.length == 2, "function 'set' requires two arguments");
        		auto var = cast(SSymbol)fargs[0];
        		assert(var, "the first argument to 'set' must be a variable");
            	return format(q{%s = %s}, var.name, aux(fargs[1]) );
	        
	        // all other symbols
	        default:
	            auto fargs = tks[1..$];
	            assert(symbol.name in function_map, "function " ~ symbol.name ~ " is not mapped");
	            auto f = symbol.name in function_map;	            
	            assert(fargs.length >= f.minargs && fargs.length <= f.maxargs,
	            	"function " ~ symbol.name ~ " : length = " ~ to!string(fargs.length) ~ " min = " ~ to!string(f.minargs)
	            	~ " max = " ~ to!string(f.maxargs) );
	            // operators need some extra love
	            if(f.type == "op") {
	            	if(fargs.length==1)	return format(q{(%s%s)},symbol.name,fargs[0]);
	            	return format(q{(%s%s%s)},aux(fargs[0]),symbol.name,aux(fargs[1]));
	            }
	            return std.string.format("(%s(%s))",symbol.name,std.string.join(std.algorithm.map!(aux)(fargs),","));
	            
			}
      }
      return "fail";
  }

  // expect the first symbol to be the name of the class
  auto outerList = cast(SList)tokens;
  assert(outerList);  
  assert(outerList.length==3);

  //outerList[0] is the name of this script  
  auto scriptName = cast(SSymbol)outerList[0];
  assert(scriptName);

  //outerList[1] is the prelude section
  auto prelude = cast(SList)outerList[1];
  assert((cast(SSymbol)prelude[0]).name == "prelude",(cast(SSymbol)prelude[0]).name);
  string preludeCode = reduce!((x,y)=>x ~= aux(y) ~ ";\n")("", prelude[1..$] );

  //outerList[2] is the update section 
  auto update = cast(SList)outerList[2];
  assert((cast(SSymbol)update[0]).name == "update", (cast(SSymbol)update[0]).name  );
  string updateCode = reduce!((x,y)=>x ~= aux(y)~ ";\n")("", update[1..$] );
  
  return format(q{
  	%s
  	while(true){
  		%s
  		Fiber.yield;
  	}},preludeCode,updateCode);
}


string compileSLisp(string program) {
	return program.tokenize.parse.SWrapper.compile;
}