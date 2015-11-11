module record;

// this is based on the implementation of std.tuple 

// usage : 

//unittest {

//	import std.stdio;
//	import std.typecons;

//	// type infered immutable record
//	auto x = irec!("age","name")(42, "dave");

//	// named properties
//	assert(x.name == "dave");

//	// range / slicing
//	assert(x[0] == 42);
//	assert(x[1] == "dave");

//	// cannot mutate!
//	assert(!__traits(compiles,x.name = "john"));

//	void print(int age, string name){
////		writeln(age, " ", name);
//	}

//	// expansion into functions!
//	print(x.expand);

//	// immutable record type alias
//	alias Record!(true, int, "age", string, "name") Person;
	
//	auto y = Person(42,"dave");

//	// structual equality
//	assert(y == x);

//	// mutable records 
//	auto z = rec!("age","name")(42,"john");
//	z.age = 45;
//	assert(z.age==45);

//	// note this expansion would not work with a normal named tuple!
//	print(z.expand); 
	
//	// partially mutable type 
//	alias Record!(false, immutable int, "age", string, "name") Person2;
//	auto a = Person2(42,"john");
//	a.name = "dave";
//	assert(a[1] == "dave");
//}

// implementation :



template Record(bool AllImmutable, Fields...) {
	import std.typetuple;
	import std.string;
	import std.traits;
	import std.typecons;	

	static assert (Fields.length > 0, "Records must have at least one member");
	static assert (Fields.length % 2 == 0, "Records must have evenly matched pairs of field types and names");

	template FieldSpec(T, string name) {
		alias Type = T;
		alias Name = name;
		static if (AllImmutable || is (T== immutable U, U)) 
			enum isImmutable = true;
		else 
			enum isImmutable = false;
	}
	
	static if(AllImmutable)
		// strip any qualifiers as they will be overwritten with immutable
		alias extractType(alias spec) = Unqual!(spec.Type);	
	else 
		alias extractType(alias spec) = spec.Type;	

	template parseArgs(Fields...) {
		static if(Fields.length == 0) 
			alias parseArgs = TypeTuple!();
		else static if (is(typeof(Fields[1]) : string)) 
			alias parseArgs = TypeTuple!(FieldSpec!(Fields[0 .. 2]), parseArgs!(Fields[2 .. $]));
		else 
			static assert(false, "field names must be a string.\n" ~ Fields[1].stringof ~ "is an invalid argument");
	}

	alias fieldSpecs = parseArgs!Fields;

	enum generatedCode = {
		import std.string : join, format;
		
		static if(AllImmutable)  
			enum prefix = "immutable %s";
		else 
			enum prefix = "%s";

		string[] fieldDefs,ctorSig, tupleCtor,props;
		foreach(i,name; staticMap!(extractType,fieldSpecs)){
			fieldDefs ~= format(prefix,name.stringof);
			ctorSig ~= format(prefix ~ " %s",name.stringof, fieldSpecs[i].Name);
			tupleCtor ~= fieldSpecs[i].Name;
			static if(fieldSpecs[i].isImmutable) 
				props ~= format(q{@property auto %s() { return __data[%d];} }, fieldSpecs[i].Name, i);	
			else
				props ~= format(q{@property auto %s() { return __data[%d];} }, fieldSpecs[i].Name, i)
					  ~  format(q{@property auto %s(%s value) { __data[%d] = value;} },fieldSpecs[i].Name,name.stringof, i);
		}
		return 
			tuple(
				format("Tuple!(%s)", fieldDefs.join(",")),
				ctorSig.join(","),
				tupleCtor.join(","),
				props.join("\n"));	
	}();

	enum structTemplate = q{
		struct Voldemort {
			private %s __data;			
			this(%s) {
				__data = tuple(%s);
			}
			@property auto Data() { return __data; }			
			%s
			alias Data this;
		}	
	};

	mixin(std.string.format(structTemplate, generatedCode.expand));
	alias Record = Voldemort;
}

private template recbuilder(bool Immutable, Fields...) {
	auto recbuilder(Values...)(Values values){
		static assert(Fields.length == Values.length, "insufficent names given");
		template Interleave(A...) {
			import std.typetuple;
			template and(B...) if (B.length == 1) {
				alias TypeTuple!(A[0],B[0]) and;
			}
			template and(B...) if (B.length > 1) {
				alias TypeTuple!(A[0], B[0],
					Interleave!(A[1..$]).and!(B[1..$])) and;
			}
		}
		return Record!(Immutable,Interleave!(Values).and!(Fields))(values);
	}
}

public:
template rec(Fields...) {
	auto rec(Values...)(Values values){
		return recbuilder!(false,Fields)(values);
	}
}

template irec(Fields...) {
	auto irec(Values...)(Values values){
		return recbuilder!(true,Fields)(values);
	}
}

