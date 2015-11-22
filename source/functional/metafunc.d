module metafunc;
// Instantiates a template, since you cannot do T!U[0]!U[1] and other weird stuff
alias Instantiate(alias Template, Params...) = Template!Params;

template Make(T)
{
	T Make(Args...)(Args args)
	{
		static if(is(T == class))
		{
			return new T(args);
		}
		else static if(is(T == struct))
		{
			return T(args);
		}
		else
		{
			return T.init;
		}
	}
}

// partially applies non-partial templates 
template meta_partial(alias T, Args...)
{
	template meta_partial(U...)
	{
		alias meta_partial = Instantiate!(T, Args, U);
	}
}

// ronseal
private template typeTupleLength(T...)
{
	enum typeTupleLength = T.length;
}

// accepts a variadic type list and insantiaties the templates 
// in the form of T[1]!T[0] recusrively, allowing meta functions
// to be piped into one another. Templates may return type tuples
// thenselves, and the returned list will be applied to the next 
// template as a variadc set of arguments

private template rec(int count, T...) // this template has to be global and not tested in t_compose
									  // so lambdas can be used  (DMD bug)
{
	alias cur = Instantiate!(T[count],T[0..count]);
	static if(T.length - count == 1)
	{
		alias rec = cur;
	}
	else
	{
		import std.traits : isTypeTuple;
		static if(isTypeTuple!cur)
		{
			enum length = typeTupleLength!cur;
			alias rec = rec!(length, cur,T[count+1..$]);
		}
		else
		{
			alias rec = rec!(1, cur,T[count+1..$]);
		}
	}

}
template meta_pipe(T...) if(T.length >= 2)
{
	alias meta_pipe = rec!(1,T);
}

// higher order templates suitable for use in pipe without having to use partial! on them
// (templates that return another template for each parameter)

template meta_filter(alias F)
{
	template meta_filter(Args...)
	{
		import std.meta : Filter;
		alias meta_filter = Filter!(F,Args);
	}
}

template meta_map(alias F)
{
	template meta_map(Args...)
	{
		import std.meta : staticMap;
		alias meta_map = staticMap!(F,Args);
	}
}

//template fold(alias Acc, alias Folder)
//{
//	template fold(Args...)
//	{
//		template rec(alias innerAcc, innerArgs...)
//		{
//			static if(innerArgs.length == 0)
//			{
//				alias rec = innerAcc;
//			}
//			else
//			{
//				alias rec = rec!(Folder!(innerArgs[0],innerAcc),innerArgs[1..$]);
//			}
//		}
//		alias fold = rec!(Acc,Args);
//	}
//}


template meta_fold(Acc, alias Folder)
{
	template meta_fold(Args...)
	{		
		enum meta_fold()
		{
			auto result = Make!Acc;
			foreach(t;Args)
			{
				result = Folder!(t)(result);	
			}
			return result;
		}
	}
}


import std.functional : pipe, unaryFun;
import std.algorithm : map, filter;
template try_transform(alias mapper, alias pred) 
	if (is(typeof(unaryFun!mapper)) && is(typeof(unaryFun!filter)))
{

	alias try_transform = pipe!(map!(mapper), filter!(pred));
} 

template filter_map(alias predicate, alias mapper ) 
	if (is(typeof(unaryFun!predicate)) && is(typeof(unaryFun!mapper)))
{
	import std.range: isInputRange;
	import std.traits: Unqual;
    auto filter_map(Range)(Range range) if (isInputRange!(Unqual!Range))
    {
        return FilterMapResult!(unaryFun!predicate, unaryFun!mapper, Range)(range);
    }
}

unittest
{
	import std.array;

	import std.algorithm : filter, map;
	string s = null;
	string[] r = ["",null,""];
	//alias test = pipe!(map!(a=>a), filter!(a=>false));
	//auto cxx = test(r);

	alias test = try_transform!("a", x=>x !is null);
	//auto x = try_transform!(a => a, x=>false)(r);
	auto z = test(r).array;

	//z.filter_map
	
	//auto x = r.filter_map!(x=>x*x,x=>x<4);
	import std.stdio;
	writeln(z);
	//assert(0,z);
}
//static if (is(typeof(fun) == delegate) || is(typeof(fun) == function))
    //{    

private struct FilterMapResult(alias pred, alias mapper, Range)
{	
	import std.range: isInputRange, isInfinite, isForwardRange;
	import std.traits: Unqual;
    
    alias R = Unqual!Range;
    R _input;
    
    this(R r)
    {
        _input = r;
        // move to the first item that matches the predicate
        while (!_input.empty && !pred(_input.front))
        {
            _input.popFront();
        }
    }

    auto opSlice() { return this; }

    static if (isInfinite!Range)
    {
        enum bool empty = false;
    }
    else
    {
        @property bool empty() { return _input.empty; }
    }

    void popFront()
    {
    	// transform the current item and move to the next 
    	// that matches the predicate
        do
        {
            _input.popFront();
        } while (!_input.empty && !pred(_input.front));
    }

    @property auto ref front()
    {
        return mapper(_input.front);
    }

    static if (isForwardRange!R)
    {
        @property auto save()
        {
            return typeof(this)(_input.save);
        }
    }
}
