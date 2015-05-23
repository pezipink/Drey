import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;
static immutable int fps = 60;
static immutable float delay_time = 1000.0 / fps;
static immutable screen_width = 640;
static immutable screen_height = 480;
SDL_Window* _window;
SDL_Renderer* _renderer;
SDL_Surface* _scr;
SDL_Texture* _scrTex;

alias std.stdio.writeln wl;
import std.traits;

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

private string toDu(immutable string duString){
  import std.stdio;
  import std.string;
  import std.typecons;
  auto cases = duString.split("\n");
  auto unionName = cases[0];
  Tuple!(string,Tuple!(string,string)[])[] allCases;
  foreach(ca; cases[1..$]){
    auto caseParts = ca.split("of");
    auto caseName = caseParts[0].strip;
    Tuple!(string,string)[] types;
    foreach(b; caseParts[1].split("*")){
      auto c = b.split(":");
      types ~= tuple(c[0].strip,c[1].strip);
    }
    allCases ~= tuple(caseName,types);
  }
  string code = "abstract class " ~ unionName ~ " {\n";
  code ~= "\n}";
  foreach(ucase; allCases){
    code ~= "\tfinal class " ~ ucase[0] ~ " : " ~ unionName ~ "{\n";
    string sig = "";
    string ctor = "";
    foreach(i,field ; ucase[1]){
      code ~= "\t" ~ field[1] ~ " " ~ field[0] ~ ";\n";
      if(i>0) sig ~=",";
      sig ~= field[1] ~ " " ~ field[0];
      ctor ~= ucase[0] ~ "." ~ field[0] ~ "=" ~ field[0] ~ ";";
    }
    code ~= "\tthis(" ~ sig ~ "){" ~ ctor ~ "}";
    code ~= "\n\t}\n";
  }
  
  return code;
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


immutable string csv  = "a,b,c\nHello,65,63.63\nWorld,123,3673.562";

template typedCsv(string input){
  enum typedCsv = {
    import std.csv;
    import std.conv;
  
    auto records = csvReader(input);
    string[string] types;
    auto headers = records.front;
    records.popFront();
    //auto samples
    foreach(header; headers){
      types[header] = "string";
    }


    foreach(record; records)
    {
        foreach(cell; record)
        {
          try{
            if( auto i = to!int(cell)){
              wl("pass");
            }
          }
          catch {wl("fail");}
          wl(typeid(cell));
            wl(cell);
        }
    }

      return ""; 
  }();
}

void main(){
  wl(csv);
  import std.csv;
  import std.conv;
  //enum data = typedCsv!(csv);
    auto records = csvReader(csv);
    foreach(record; records)
    {
      wl(record);
        foreach(cell; record)
        {
          try{
            if( auto i = to!int(cell)){
              wl("pass");
            }
          }
          catch {wl("fail");}
          wl(typeid(cell));
            wl(cell);
        }
    }
    auto x = {
      if(1 == 2) return 42; else return 23;
    }();

    wl("!!!",x);
//auto x = new Number(4);
  //wl(du.toDu);

  //auto x = new Case2("x",4);
  //virt(x);
    //auto x = new Case3(new Case2("ross",42));
    //.match(x=)
    //wl(x.quinton.test2);
	  //DerelictSDL2.load();
    //DerelictSDL2Image.load();
  
    //SDL_Init(SDL_INIT_EVERYTHING);  
   // auto _window = SDL_CreateWindow("Drey", SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_SHOWN);



   // _scr = SDL_CreateRGBSurface(0, 640, 480, 32,
   //                                     0x00FF0000,
   //                                     0x0000FF00,
   //                                     0x000000FF,
   //                                     0xFF000000);
   // _scrTex = SDL_CreateTexture(_renderer,
   //                                         SDL_PIXELFORMAT_ARGB8888,
   //                                         SDL_TEXTUREACCESS_STREAMING,
   //                                         640, 480);

}

void render(){
  SDL_UpdateTexture(_scrTex, null, _scr.pixels, _scr.pitch);
  SDL_RenderClear(_renderer);
  SDL_RenderCopy(_renderer, _scrTex, null, null);
  
  // the rest of the shit is drawn via the renderer like normal
 
   SDL_RenderPresent(_renderer);
}








class John(T)
{
  T[string] data;

  //void opDispatch(string name)(T newData){
  //  data[name] = newData;
  //}

  string opDispatch(string numeral)()  {
    import std.conv;
    return to!string(numeral);
    //if(name in data)
    //  return data[name];
    //return T.init;
  } 
}

