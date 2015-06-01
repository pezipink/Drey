
//abstract class TestUnion
//{
//  string opDispatch(string name)()  {
//    import std.algorithm : castSwitch;
//    return this.castSwitch!(
//      (Case1 x) => mixin("x."~name)
//      (Case2 x) => mixin("x."~name)
//      );
//  }
//}
// final class Case1 : TestUnion {
//    int test;
//    this(int test){ this.test=test; }
//  } 
 
// final class Case2 : TestUnion {
//    string test2; 
//    int test3;
//    this(string test2, int test3){  this.test2=test2; this.test3=test3; }
//}
private string john(){
	import std.string : format;
	return format(q{auto x = %s} , "ross");
}







//Algebraic!(string,int)

//immutable string du =
//  "JsonValue
//   Number of n : int
//   String of lhs : Expression * rhs : Expression
//   Multiply of lhs : Expression * rhs : Expression
//   Object of value : JsonValue[] ";



//immutable string du =
//  "Expression
//   Number of n : int
//   Add of lhs : Expression * rhs : Expression
//   Multiply of lhs : Expression * rhs : Expression
//   Variable of value : string";

//mixin(du.toDu);

//auto x = new Multiply(
//          new Number(4), 
//          new Add(
//              new Number(4),
//              new Number(14)));

//x.match!(
//  (Add(Number x ,Number x) a) => a.rhs == 5 
//  )
//void virt(T)(TestUnion!T test){
//  wl(typeid(T));
//  wl(test.test6);
//}


//auto x = new Multiply(
//          new Number(4), 
//          new Add(
//              new Number(4),
//              new Number(14)
//            )
//        );


immutable string samplesData = "Header1,Header2,Header3\nHello,65,63.63\nWorld,123,3673.562";


template typedCsv(string sample){
  import std.csv;
  enum structCode = {
  	import std.conv;
  	import std.array;
  	import std.string : format;
  	import std.typecons : tuple;
  	import std.algorithm : map;
  	
    auto records = csvReader(sample);
    auto headers = records.front.array;
    auto types = headers.map!(x=>tuple(x,"string")).assocArray;
	records.popFront();
	// <snip> do type inference ...    
	foreach(record; records)
    {
    	//if(rindex > 10) break;
    	int i = 0;
        foreach(cell; record)
        {    
        	try {
          		if(auto x = to!int(cell)) {
          			types[headers[i++]] = "int"; 
          			continue; 
      			} 
  			} 
			catch {}
          
          	try {          		
      			if( auto x = to!float(cell)) {
      				types[headers[i++]] = "float"; 
      				continue; 
  				}
			} 
			catch {}          

			i++;
        }
    }
    auto structDef = q{
    	struct voldemortCsv {
			%s
    	}
    };
    // create voldemortCsv struct 
    return format(
		structDef, 
		headers
			.map!(x=> format("%s %s;",types[x], x))
			.join);     
  }();

  // compile struct into template scope
  mixin(structCode);

  // eponymous template aliases the scoped type
  alias typedCsv = voldemortCsv;
}






  //immutable string sampleData = "Header1,Header2,Header3\nHello,65,63.63\nWorld,123,3673.562";
  
  //// alias a compile-time generated voldemort struct 
  //// with inferred column data types from a sample
  //alias typedCsv!(sampleData) MyCsv;
  //foreach(r;csvReader!MyCsv(runtimeData,null)) {
  //  // header 1 is a string
  //  writeln(r.Header1 ~ " is a string!");
  //  // 2 and 3 are int and float respectively
  //  writeln(r.Header2 + r.Header3); 
  //}
