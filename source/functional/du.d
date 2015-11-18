module du;
import std.typecons;
import std.array;


template DU(string S) {

	private struct unionType {
		import std.algorithm: map;
		import std.range : chain;
		import std.string: join, format, strip;
		string className;
		string[string] attributeMap;
		Tuple!(string,string,string)[] fields;
		unionType[] derivedTypes;

		@property auto fieldString()
		{
			return this.fields.map!(x=>format("%s %s;",x[1],x[0]).strip).join("\n");
		}
		
		auto toStringMethod(Tuple!(string,string,string)[] superCtorFields )
		{
			// return "public override string toString() { return \"ross\"; } ";
			string str; 
			auto fields = chain(superCtorFields, this.fields).array;
			// auto fields = this.fields;
			if(fields.length == 0)
			{
				str = "\"" ~ this.className ~ "\""; 
			}
			else
			{
				str = "\"" ~ this.className ~ " : \" ";
			}
			foreach(i,tup; fields)
			{
				auto field = tup[0].strip;
				if(i==0)
				{
					str ~= "\"" ~ field ~ " => (\" ~ to!string(this." ~ field ~ ") ~ \" )\" ";
				}
				else
				{
					str ~= " ~ \", " ~ field ~ " => (\" ~ to!string(this." ~ field ~ ") ~ \" )\" ";
				}

			}				
			return q{
				public override string toString()
				{
					import std.conv : to;
					string str = %s ;
					return str;
				}
			}.format(str);
		}

		@property auto derivedAlias()
		{
			return format("import std.meta : AliasSeq; alias __derivedTypes = AliasSeq!(%s);",
				derivedTypes.map!(x=>x.className).join(","));
		}

		@property auto opDispatchMethods()
		{
			return q{
				@property bool opDispatch(string s)()			
					if(s[0..2] == "Is")
				{
					mixin("auto x = cast("~s[2..$]~")this;");
					return x !is null;
				}

				@property auto opDispatch(string s)()			
					if(s[0..2] == "As")
				{
					mixin("return cast("~s[2..$]~")this;");
				}
			};
		}


		auto ctorParamString(Tuple!(string,string,string)[] superCtorFields = [])
		{
			return chain(superCtorFields,this.fields).map!(x=>
				{
					if(x[2] != "")
					{
						return format("%s %s = %s",x[1],x[0],x[2]).strip;
					}
					else
					{
						return format("%s %s",x[1],x[0]).strip;
					}
				}()).join(",");
		}

		string tagMethod(bool isAbstract)
		{
			if(isAbstract)
			{
				return q{string __tag() { return ""; } };
			}
			else
			{
				return (q{override string __tag() { return "%s"; } }).format(className.strip);
		
			}
		}

		@property auto ctorBodyString()
		{
			return this.fields.map!(x=>format("this.%s=%s;",x[0],x[0]).strip).join("");
		}
	}
	
	auto extractFromParens(string input) 
	{
		import std.string;	
		import std.typecons;
		immutable firstParen = input.indexOf("(");

		return tuple(input[0..firstParen].strip, input[firstParen+1.. input.lastIndexOf(")")].strip);
	}

	auto parseAttributes(string input)
	{
		string[string] output;
		int parenStack;
		string temp;
		string currentAtt;
		foreach(c;input)
		{
			if( c == '(')
			{
				if( parenStack == 0)
				{	
					currentAtt = temp;
				}
				parenStack ++;
			}

			if( c == ')')
			{
				parenStack--;
				if(parenStack == 0)
				{
					temp ~= c;
					output[currentAtt] = temp;
				}
			}

			if(c == ',' && parenStack == 0)
			{
				currentAtt = "";
				temp = "";
			}
			else
			{
				temp ~= c;
			}
		}
		return output;
	}

	private string createAttributes(string[string] kvp)
	{
		import std.algorithm : map;
		import std.string : join, format;
		
		if(kvp.length==0)
		{
			return "";
		}
		return format("@(%s)", kvp.values.join(","));
	}


	private auto extractClassData(string input) 
	{
		import std.string : split, lastIndexOf, strip, indexOf;	
		import std.typecons : tuple;
		import std.array : assocArray;
		import std.algorithm : map;

		immutable fsplit = split(input,"of");	

		immutable leftSide = fsplit[0];

		string[string] attributeMap;
		Tuple!(string,string,string)[] fieldMap;
		string className;

		if( leftSide[0..2] == "@(")
		{
			immutable lastParen = leftSide.lastIndexOf(")");
			attributeMap = 
				leftSide[2..lastParen]
				.parseAttributes;
			className = leftSide[lastParen+1..$].strip;			
		}
		else
		{
			className = leftSide;
		}

		if(fsplit.length > 1){
			foreach(fieldSplit; split(fsplit[1],"*")){
				immutable data = split(fieldSplit,":");
				if( data[1].indexOf("#") > -1)
				{
					immutable innerSplit = split(data[1],"#");
					fieldMap ~= tuple(data[0].strip,innerSplit[0].strip,innerSplit[1].strip);
				}
				else
				{
					fieldMap ~= tuple(data[0].strip,data[1].strip, "");
				}
			}
		}

		return tuple(className,attributeMap,fieldMap);
	}

	string DU() {		
		import std.string : strip, format, join, split, lastIndexOf;
		import std.algorithm : map;
		import std.stdio;

		enum outer = split(S,"=");
		static assert(outer.length==2,"Discriminated Unicorn not in excepted form.");
		
		auto at = unionType();
		auto abstractClassData = outer[0].strip.extractClassData;
		at.className = abstractClassData[0];
		at.attributeMap = abstractClassData[1];
		at.fields = abstractClassData[2];

		immutable inner = outer[1].split("|").array;
		foreach(innerType; inner[1..$] ) {
			auto der = unionType();			
			auto classData = innerType.strip.extractClassData;
			der.className = classData[0];
			der.attributeMap = classData[1];
			der.fields = classData[2];
			foreach(key; at.attributeMap.keys)
			{		
				if(key !in der.attributeMap)
				{					
					der.attributeMap[key] = at.attributeMap[key];
				}
			}
			at.derivedTypes ~= der;
		}

		enum string abstractTemplate =
			q{abstract class %s {
				%s
				this(%s)
				{
					%s
				}
				%s
				%s
				%s
			}};

		immutable string abs = 
			format(abstractTemplate, 
					at.className, 
					at.fieldString, 
					at.ctorParamString, 
					at.ctorBodyString,
					at.tagMethod(true),
					at.opDispatchMethods,
					at.derivedAlias);

		enum string derivedTemplate = 
			q{%s final class %s : %s {
			   %s
			   %s
			   %s
			}} ;
		
	 	string derived;
	 	foreach(d;at.derivedTypes) {
	 		auto attributes = createAttributes(d.attributeMap);
	 		auto tostring = d.toStringMethod(at.fields);
	 		auto fields = d.fieldString;
	 		auto ctorParams = d.ctorParamString(at.fields);
	 		auto ctorBody = d.ctorBodyString;
	 		if(at.fields.length > 0)
	 		{
	 			ctorBody ~= format("super(%s);",at.fields.map!(x=>x[0]).join(","));
	 		}
			auto classDef = format("%s\nthis(%s){%s}",fields,ctorParams,ctorBody);
					import std.string : format;
			derived ~= format(derivedTemplate,attributes,d.className,at.className,classDef,d.tagMethod(false),tostring);
	 	}
	 	if( !__ctfe)
	 	{
	 	  [abs,derived].join("\n").writeln;	
	 	}
 		return [abs,derived].join("\n");
	}
}