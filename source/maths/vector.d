module maths.vector;

import std.algorithm : map;
import std.array : array;
import std.math : sqrt;

@safe 

import std.traits;
import std.typetuple;
struct Vector(int n, T = float) {
	alias Vector!(n,T) thisType;
	enum arity = n;
	private T[n] _data;
	
	// constructors 
	this(T data){
		_data[] = data;
	}
	this(T[n] data){
		_data[] = data[];
	}
	this(T[n] data...){
		_data[] = data[];
	}

	this(Range)(Range r)if (isIterable!Range) {
		assert(r.length == n);
		//this one lets us use results of functional algos from std.algorithm
		//withouht an additional copy ( I think! )
		int i = 0;
		foreach(ref T v; r) _data[i++] = v;
	}

	@property ref T get(int n)(){ return _data[n]; }

	// setup handy aliases for common vector usages; 
	// x y z w
	// r g b a

	alias get!0 x;
	alias get!0 r;

	static if(n >= 2) {
		alias get!1 y;
		alias get!1 g;
	}
	static if(n >= 3) {
		alias get!2 z;
		alias get!2 a;
	}

	alias _data this; // let this also be used as a 2d array

	thisType opUnary(string op)() if( op == "-") {
		return thisType(_data[].map!(a=>-a));
	}

	thisType opBinary(string op)(thisType rhs) 	
		if(op == "+" || op == "-")
	{
		static if(op == "+") {
			return add(this,rhs);
		}
		else static if(op == "-") {
			return sub(this,rhs);
		}
	}

	thisType opBinary(string op, U)(U rhs) 	{
		 static if(op == "*") {
			return mul(this,rhs);
		}
		else static if(op == "/") {
			return div(this,rhs);
		}
	}
}

// meta stuff

alias Vector!2 vec2;
alias Vector!3 vec3;
alias Vector!4 vec4;

alias Vector!(2,int) veci2;
alias Vector!(3,int) veci3;
alias Vector!(4,int) veci4;


template isVector(T) {
	enum isVector = (is(T : Vector!(N,TL), int N, TL));		
}

/// extracts the type of the underlying data eg float
template vectorType(T) {
	static if (is(T == Vector!(N,U), int N, U )) {
		alias vectorType = U;
	}
}


// module functions to perform operations on and return new vectors

T mul(T, U)(T source, U scalar) pure nothrow 
	if(isVector!T)
{	
	return T(source[].map!(a=>a*scalar));
}

T div(T, U)(T source, U scalar) pure nothrow 
	if(isVector!T)
{	
	return T(source[].map!(a=>a/scalar));
}

T add(T)(T left, T right) pure 
	if(isVector!T)
{
	import std.range : zip;
	return T(
		zip(left[],right[])
	     .map!(x=>x[0]+x[1]));
}

T sub(T)(T left, T right) pure 
	if(isVector!T)
{
	import std.range : zip;
	return T(
		zip(left[],right[])
	     .map!(x=>x[0]+(-x[1])));
}

private mixin template seed() {
	import std.algorithm : reduce;
	import std.traits : isFloatingPoint;
	static if(isFloatingPoint!(vectorType!T))
		auto seed = 0.0;
	else
		auto seed = 0;
}

/*
Magnitude is defined as the square root of the sum of the squares of the components.
Note this will only work where the Vector data type is a floating point or integer based type
To support other types, they will need to be added to the static if and have a seed provided,
as well as supporting the + and * operators.
*/
auto mag(T)(T source) 
	if(isVector!T) 
{
	mixin seed;
	return	
		reduce!((acc, x)=> acc + x * x)(seed,source[])
		.sqrt;
}

auto dist(T)(T left, T right) 
	if(isVector!T) 
{
	import std.range : zip;
	mixin seed;
	return	
		reduce!((acc, x)=> acc + ((x[1] - x[0]) * (x[1] - x[0])))(seed,zip(left[],right[]))
		.sqrt;
}

auto dot(T)(T left, T right) 
	if(isVector!T) 
{
	import std.range : zip;
	mixin seed;
	return	
		reduce!((acc, x)=> acc + x[0] * x[1])(seed,zip(left[],right[]));		
}


auto cross(T)(T left, T right) 
	if(isVector!T && T.arity == 3) 
{
	return
		T((left[1]*right[2] - left[2]*right[1],
		   left[2]*right[0] - left[0]*right[2],
		   left[0]*right[1] - left[1]*right[0]));
}

T norm(T)(T source) 
	if(isVector!T)
{
	return source.div(source.mag);
}

unittest {
	// template tests
	assert(isVector!vec2);
	assert(isVector!vec3);
	assert(isVector!vec4);
	assert(isVector!veci2);
}

unittest {	
	// constructor tests
	auto a = vec2(2.0);
	assert(a.x == 2.0 && a.y == 2.0);
	assert(a[1]==2.0);
	auto b = veci3(1,2,3);	
	assert(b.x == 1 && b.y == 2 && b.z==3);
	auto c = veci3(b[].map!(x=>x+1));
	assert(c.x == 2 && c.y == 3 && c.z==4);
}

unittest { 
	import std.algorithm : equal;
	// negate
	auto a = vec3(2);
	auto b = -a;	
	assert(equal([-2,-2,-2],b[]));

	// +  - 
	assert(equal([10,10,10],(b + vec3(12))[]));
	assert(equal([-14,-14,-14],(b - vec3(12))[]));
}

unittest {
	// module function tests
	import std.algorithm : equal;	
	import std.math : approxEqual;
	auto a = vec2(-2.0);
	
	// multiply (commutatative)
	auto b = a.mul(5.0);
	assert(equal([-10.0,-10.0],b[]));
	auto c = mul(a,5);;
	assert(equal([-10.0,-10.0],c[]));
	assert(equal([-10.0,-10.0],(a * 5)[]));		

	// divide (anticommutatative)	
	assert(equal([-1.0,-1.0],a.div(2.0)[]));	
	assert(equal([-1.0,-1.0],(a / 2.0)[]));	

	// addition (commutative)
	auto d = a.add(b);
	assert(equal([-12.0,-12.0],d[]));	

	//subtraction (anticommutative)
	auto e = a.sub(b);
	// -2 (a) - -10 (b) = 8
	assert(equal([8.0,8.0],e[]));
	// -10 (a) - -2 (b) = -8
	auto f = b.sub(a);
	assert(equal([-8.0,-8.0],f[]));

	// magnitude	
	assert(vec2(3,4).mag == 5);
	assert(vec2(3.0,4.0).mag == 5.0);	
	assert(approxEqual(vec3(5.0,-4.0,7.0).mag, 9.48683));

	// normalize
	assert(approxEqual([0.923,-0.385],vec2(12.0,-5.0).norm[]));

	// distance
	assert(dist(vec2(5,0),vec2(-1,8)) == 10);

	// dot product (commutative)
	assert(dot(vec2(4,6),vec2(-3,7)) == 30);
}



//template isFloatVector(T) {
//	static if (is(T == Vector!(N,U), int N, U : float)) {
//		// can't seem to check this in one go? the line
//		// above allows any type that can be implicitly cast
//		// to float.
//		enum isFloatVector = (is(U == float));
//	}
//	else enum isFloatVector = false;
//}

//template isFloatVector(T) {
//	enum isFloatVector = (is(T == Vector!(N,U), int N, U : float)) ;
//}

//template isIntVector(T) {
//	static if (is(T : Vector!(N,TL), int N, TL : int)) {
//		pragma(msg, typeic(TL));
//		enum isIntVector = true;
//	}
//	else enum isIntVector = false;
//}