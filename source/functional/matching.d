module matching;

import std.traits;

class Person {
	string name;
	int age;
	string occupation;
	this(string _name, int _age, string _occupation) {
		name = _name;
		age = _age;
		occupation = _occupation;
	}
}

class MatchResult(T) {
	bool flag;
	T value;
	this(){
		flag = false;
	}
	this(T _value){
		flag = true;
		value = _value;
	}
}


template match(choices...) {
	import std.typetuple;
	import std.typecons;
	
	auto match(T)(T matchObject) {
		
		alias noMatchFunction = choices[$-1];
		alias matchers = choices[0..$-1];
		
		foreach(i,choice;matchers) 
		{			
			static if(i % 2 == 0)
			{
				alias target = ParameterTypeTuple!(matchers[i+1])[0];
				auto result = cast(MatchResult!target)choice(matchObject);
				if(result.flag)
				{
					return matchers[i+1](result.value);
				}
			}
		}

		return noMatchFunction(); 
	}
}


template match(choices...) {
	import std.typetuple;
	import std.typecons;
	
	auto match(T)(T matchObject) {
		
		enum badArgs =
			"You must supply pairs of functions, and a default function to handle the case of no matches.
			The function pairs should be in the form of F, G where F is a function that accepts the object instance
			you are matching on, returning MatchResult!T, and G is a function that accepts T and processes the result of 
			if successful.
			";
				
		static assert ( choices.length >= 3, badArgsMessage);

		import std.range;

		
		//look at details of the first pair of functions
		alias matcher = choices[0];
		alias callback = choices[1];
		alias callbackArgs = ParameterTypeTuple!callback;	
		alias callbackReturnType = ReturnType!callback;	
		alias matcherArgs = ParameterTypeTuple!matcher;	
		alias matcherType = TemplateArgsOf!(ReturnType!matcher);	

		//up-front check that the functions match up (pun intended)
		for(int i = 0; i < choices.length-1; i+=2) 
		{			
			static assert(
				matcherArgs.length==1 
				&& (is(matcherArgs[0] == T)), 
				"matcher function must accept instance of type " ~ typieid(T));

			//pragma(msg, TemplateArgsOf!(ReturnType!choices[0]));
			// matcher must return MatchResult!T where T == the input of the callback
			// static assert(
			// 	(is(TemplateArgsOf!(ReturnType!choices[0])[0] == ParameterTypeTuple!(choices[1])[0])),
			// 	"callback must accept the resulting T from the matcher's MatchResult!T"
			// 	);

		}

		// this stuff fails with a undefined symbol error?!
		// template MatchingPair(alias M, alias C)
		// {
		// 	alias matcher = M;
		// 	alias callback = C;
		// }

		// template parsePairs(pairs...) 
		// {
		// 	static if(pairs.length==1)
		// 	{
		// 		alias parsePairs = TypeTuple!();
		// 	}
		// 	else 
		// 	{
		// 		alias parsePairs = TypeTuple!(MatchingPair!(pairs[0..2]), parsePairs!(pairs[2..$]));
		// 	}
		// }
		// alias pairs = parsePairs!choices;

		// foreach(i,pair;pairs) 
		// {			
		// 	alias target = ParameterTypeTuple!(pair.callback)[0];
		// 	auto result = cast(MatchResult!target)pair.matcher(matchObject);
		// 	if(result.flag)
		// 	{
		// 		return pair.callback(result.value);
		// 	}
		// }
		// end weirderror

		alias noMatchFunction = choices[$-1];
		alias matchers = choices[0..$-1];
		
		foreach(i,choice;matchers) 
		{				
			static if(i % 2 == 0)
			{
				alias target = ParameterTypeTuple!(matchers[i+1])[0];
				auto result = cast(MatchResult!target)choice(matchObject);
				if(result.flag)
				{
					return matchers[i+1](result.value);
				}
			}
		}

		return noMatchFunction(); 
	}
}


// low level mechanics
auto Match(alias pred, alias transform)(Person p) {
	alias rt = ReturnType!transform;
	if(pred(p)) return new MatchResult!rt(transform(p));
	else return new MatchResult!(rt)();
}


// write some patterns, this one matches name and returns occupation
auto NameWith(string name, Person p){
	return Match!(p=>p.name==name,(Person p)=>p.occupation)(p); 
}
// and this one applies >= to ages and returns the whole person
auto AgeAtLeast(int age, Person p){ 
	return Match!(p=>p.age>=age,(Person x)=>x)(p); 
}


// 	// //match! ultimately returning strings in this case...
// 	// auto r = tc.match!(
// 	// 		 partial!(NameWith, "juan"), (string p) => "someone named juan : " ~ p,
// 	// 		 partial!(AgeAtLeast, 20), (Person p) => "someone at least 20 : " ~ p.name,
// 	// 		 () => "" // default case for no matches
//  // 	);
	


