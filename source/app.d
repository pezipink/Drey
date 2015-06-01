import derelict.sdl2.sdl;
import derelict.sdl2.image;

import scratchpad;
import std.stdio;
alias std.stdio.writeln wl;
import std.traits;
import core.thread;
import std.parallelism;
immutable auto RGB_Yellow = SDL_Color(255, 255, 0, 0);

T WRAPP(T)(T x, T max) { return x > max ? x-max : x; }

import std.container;
class Attacker  : Fiber {
  import std.random;
  import maths.vector;
  import core.thread;
  import std.math ;
  vec2 pos;
  vec2 vel = vec2(0.1,0.0);
  int time;
  this() {

      super(&update);
      pos = vec2(uniform(0,300),0.0);
  }
  void update(){
    float angle = 0.0;
    int delta = uniform(10,200);
    while(true){
      //pos += vel;
      angle = WRAPP(angle+0.05,360.0);
      pos.x =WRAPP(pos.x+1,640);
      pos.y =  240 + cos(angle)*delta;
      Fiber.yield();
    }
  }
}
import core.memory;

class Game
{    
private:  
  static immutable int fps = 60;
  static immutable float delay_time = 1000.0 / fps;
  static immutable screen_width = 640;
  static immutable screen_height = 480;
  SDL_Window* _window;
  SDL_Renderer* _renderer;
  SDL_Surface* _scr;
  SDL_Texture* _scrTex;
  bool gameRunning = false;
  SList!Attacker attackers;
  SList!Attacker attackers2;
public:
  this( ) {
    for(int i = 0; i < 30000; i++){
      attackers.insert( new Attacker());
    //attackers2.insert( new Attacker());
    }
    
  }
  void Init()
  {
    
    SDL_Init(SDL_INIT_EVERYTHING);  
    _window = SDL_CreateWindow("Squirrelatron", SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_SHOWN);
    //SDL_SetWindowFullscreen(_window,SDL_WINDOW_FULLSCREEN);
    _renderer = SDL_CreateRenderer(_window,-1,0);
//    InputHandler.InitializeJoysticks();
    _scr = SDL_CreateRGBSurface(0, 640, 480, 32,
                                        0x00FF0000,
                                        0x0000FF00,
                                        0x000000FF,
                                        0xFF000000);
    _scrTex = SDL_CreateTexture(_renderer,
                                            SDL_PIXELFORMAT_ARGB8888,
                                            SDL_TEXTUREACCESS_STREAMING,
                                            640, 480);
    gameRunning = true;
  };
  
  @system
  private void pset(int x, int y, const SDL_Color color)
  {
    if(x < 0 || y < 0 || x >= screen_width || y >= screen_height) return;
    uint colorSDL = SDL_MapRGB(_scr.format, color.r, color.g, color.b);
    uint* bufp;
    bufp = cast(uint*)_scr.pixels + y * _scr.pitch / 4 + x;
    *bufp = colorSDL;
  }

  void Render(){
    //SDL_FillRect(_scr, null, 0x000000);
    //for(int x=0; x<screen_width; x++) {
    //  pset(x,50,RGB_Yellow);
    //  pset(x,50,RGB_Yellow);
    //  pset(x,50,RGB_Yellow);
    //  pset(x,50,RGB_Yellow);
    //}      
    auto color = RGB_Yellow;
    uint colorSDL = SDL_MapRGB(_scr.format, color.r, color.g, color.b);
    foreach(attacker;attackers){
      int y = cast(int)attacker.pos.y;
      int x = cast(int)attacker.pos.x;
      //if(x < 0 || y < 0 || x >= screen_width || y >= screen_height) return;
      uint* bufp;
      bufp = cast(uint*)_scr.pixels + y * _scr.pitch / 4 + x;
      bufp = cast(uint*)_scr.pixels + y+1 * _scr.pitch / 4 + x;
      bufp = cast(uint*)_scr.pixels + y+1 * _scr.pitch / 4 + x+1;
      bufp = cast(uint*)_scr.pixels + y * _scr.pitch / 4 + x+1;
      *bufp = colorSDL;
    }

  //  foreach(attacker;attackers){
  //    pset(cast(int)attacker.pos.x,cast(int)attacker.pos.y,RGB_Yellow);
  //    pset(cast(int)attacker.pos.x,cast(int)attacker.pos.y+1,RGB_Yellow);
  //    pset(cast(int)attacker.pos.x+1,cast(int)attacker.pos.y,RGB_Yellow);
  //    pset(cast(int)attacker.pos.x+1,cast(int)attacker.pos.y+1,RGB_Yellow);
  //}
    SDL_UpdateTexture(_scrTex, null, _scr.pixels, _scr.pitch);
    SDL_RenderClear(_renderer);    
    SDL_RenderCopy(_renderer, _scrTex, null, null);
    SDL_RenderPresent(_renderer);
  }

  void Update() {
    import std.algorithm : each;
    foreach(a; parallel(attackers[]))
      a.call();
      //attackers.each!(x=>x.call());
  };
  
  Uint8* _keyState;  
  
  bool IsKeyDown(SDL_Scancode code){ return _keyState[code] == 1; }
  
  void HandleEvents()  {
    _keyState = SDL_GetKeyboardState(null);
    if(IsKeyDown(SDL_SCANCODE_ESCAPE)) {
      gameRunning=false;
    }

    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
      switch(event.type)
      {
        case SDL_QUIT:
          gameRunning=false;
        break;

        default:
        break;
      }
    }
    //InputHandler.Update();
  };

  void Clean()  {
    //InputHandler.Clean();
    SDL_DestroyWindow(_window);
    SDL_DestroyRenderer(_renderer);
    SDL_Quit();
  };

  @property bool running() { return gameRunning; }
}


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
abstract class Atom {

} final class Int : Atom{
  int value;
  this(int value){Int.value=value;}
  }
  final class Float : Atom{
  float value;
  this(float value){Float.value=value;}
  }
  final class Symbol : Atom{
  string value;
  this(string value){Symbol.value=value;}
  }

abstract class Tokens {

} final class Token : Tokens{
  Atom value;
  this(Atom value){Token.value=value;}
  }
  final class TokenList : Tokens{
  Tokens[] values;
  this(Tokens[] values){TokenList.values=values;}
  }

// immutable string atomDu =
//  "Atom
//   Int of value : int
//   Float of value : float
//   Symbol of value : string";
// pragma(msg,atomDu.toDu);
// mixin(atomDu.toDu);

// immutable string tokenDu = 
//   "Tokens
//    Token of value : Atom
//    TokenList of values : Tokens[]";
// pragma(msg,tokenDu.toDu);
// mixin(tokenDu.toDu);   


import std.variant;

alias rnd = std.random.uniform;

struct function_data{
  string type;
  int minargs;
  int maxargs;
}

enum function_map = 
  [ "-" : function_data("op",1,2),
    "+" : function_data("op",1,2),
    ">" : function_data("op",2,2),
    "<" : function_data("op",2,2),
    "=" : function_data("op",2,2),
    "<=" : function_data("op",2,2),
    ">=" : function_data("op",2,2),
    "!=" : function_data("op",2,2),
    "rnd" : function_data("func",2,2)
  ];
  
mixin template call_function(string name, Tokens[] tks) {
  
  static assert(name in function_map, "function " ~ name ~ "is not mapped");
  
  static assert(function_map[name].minargs.length >= tks.length 
      && function_map[name].maxargs.length <= tks.length);
  
  string f = std.string.format(q{%s(%s)},name,std.string.join(std.algorithm.map!(aux)(tks),","));

}

// string compile(Tokens tokens)() {
//   import std.conv : to;
//   import std.string : join, format;
//   import std.algorithm : map, reduce;  

//   string aux(Tokens token) {
//     return
//       token.visit!(
//         (Atom a) => 
//           a.visit!((int i) => i.to!string,
//                    (float f) => f.to!string,
//                    (Symbol s) => s), 
          
//         (delegate string (Tokens[] tks) {
//             // extract the first value and do stuff depending on what it is.
//             if(tks[0].get!(Atom).peek!(Symbol) !is null ){
//               auto sym = tks[0].get!(Atom).get!(Symbol);
//               switch(sym) {
//                 case "define":
//                   // for some reason reduce blows up the compiler here 
//                   // so I am using map |> join instead
//                   return format("auto %s = %s;\n",aux(tks[1]), aux(tks[2]));
//                 case "if":
//                   return
//                     format(
//                       q{if( %s ) {
//                           %s
//                         } else {
//                           %s
//                         }
//                       },
//                       aux(tks[1]),
//                       aux(tks[2]),
//                       aux(tks[3]));                
//                 case "-":
//                     assert(tks.length >1 && tks.length < 4, "- has incorrect amount of arguments");
//                     if(tks.length == 2){
//                       //negation
//                       return format("-%s",aux(tks[1]));
//                     } else {
//                       return format("%s - %s",aux(tks[1]),aux(tks[2]));
//                     }

//                 default:
//                   mixin(call_function!(sym,tks[1..$]));
//                   return f;
//               }
//             }

//             return "ds";
//           }
//           ));
//   }

//   // expect the first symbol to be the name of the class
//   assert(tokens.type == typeid(Tokens[]));
//   enum  outerList = tokens.get!(Tokens[]);  
//   //outerList[0] is the name
//   assert(outerList.length == 3 && outerList[0].get!Atom.peek!Symbol !is null);
//   auto scriptName = outerList[0].get!Atom.get!Symbol;    
//   //outerList[1] is the prelude
//   string prelude = reduce!((x,y)=>x ~= aux(y))("", outerList[1].get!(Tokens[])[1..$] );
//   //outerList[2] is the update
//   string update = reduce!((x,y)=>x ~= aux(y))("", outerList[2].get!(Tokens[])[1..$] );
  
//   wl("0", outerList[0]);
//   wl("1", outerList[1]);
//   wl("2", outerList[2]);
//   // then we have subsections, allowed sections are prelude and update.


  
//   return prelude;
// }

string[] tokenize(string input) {
  import std.string;
  import std.array : array;
  import std.algorithm : filter;
  return
    input
      .replace("(", " ( ")
      .replace(")", " ) ")      
      .split(" ")
      .filter!(x=>strip(x) != "")
      .array;
}

Tokens parseAtom(string atom) {
  import std.conv : to;
  try {
    if(auto x = to!int(atom)) 
      return new Token(new Int(x));    
  } catch {}
  try {
    if(auto x = to!float(atom)) 
      return new Token(new Float(x));    
  } catch {}
  return new Token(new Symbol(atom));
}

Tokens parse (string[] tokens) {  
  auto token = tokens[0];
  tokens = tokens[1..$];
  switch( token ) {
    case "(" :
      TokenList next = new TokenList(Token[].init);
      while(tokens[0] != ")"){
         //next.values ~= parse(tokens);
         tokens = tokens[1..$];
       }
      tokens = tokens[1..$];
      return next;
    case ")" :
      throw new Exception("unexpected )");
    default :
      return parseAtom(token);
  }
}


void main(){
   // float angle = 0.0;
   //  int delta = uniform(10,200);
   //  while(true){
   //    //pos += vel;
   //    angle = WRAPP(angle+0.05,360.0);
   //    pos.x =WRAPP(pos.x+1,640);
   //    pos.y =  240 + cos(angle)*delta;
   //    Fiber.yield();
   //  }
  enum tokens = "(basicAttack
                  (prelude 
                    (define angle 0.0) 
                    (define delta (rnd 10 200)))
                  (update
                    (set angle (WRAPP (+ angle 0.05) 360.0))
                    (set pos.y (* (+ 240 (cos angle) delta)))))
                  ".tokenize();
  wl(tokens);
  enum p = tokens.parse;

  // wl(tokens.parse);
  // mixin("(test1
  //         (prelude 
  //           (define speed (rnd 10 200))
  //           (define width 50)
  //           (define height 50))
  //         (update
  //           (set vel.x speed)(set vel.y 0)
  //           (wait (delta pos.x width))
  //           (set vel.y speed)(set vel.x 0)
  //           (wait (delta pos.y height))
  //           (set vel.x (- speed))(set vel.y 0)
  //           (wait (delta pos.x (- width)))
  //           (set vel.y (- speed))(set vel.x 0)
  //           (wait (delta pos.y (- height))))
  //         ").compile);



  // wl("result\n",compile(parse(tokens))());
//GC.disable = true;
  import core.thread;
  //TestFiber fib = ;

  DerelictSDL2.load();
  DerelictSDL2Image.load();
  auto game = new Game();  
  uint frameStart, frameTime;
  game.Init();
  wl("init ", Game.delay_time);
  while(game.running)
  {
    frameStart = SDL_GetTicks();
    game.HandleEvents();
    game.Update();
    game.Render();

    frameTime = SDL_GetTicks() - frameStart;
    if( frameTime < Game.delay_time ){
      //wl(cast(int)Game.delay_time-frameTime);
      //SDL_Delay(cast(int)Game.delay_time-frameTime);
      //wl(frameTime);
    }else {writeln("ouch ", frameTime - Game.delay_time, " ", frameTime); }
    
  }
  game.Clean();
}
