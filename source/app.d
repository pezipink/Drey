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

// import std.container;
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
    mixin(
      "(basicAttack
        (prelude 
          (define angle 0.0) 
          (define delta (rnd 10 200)))
        (update
          (set angle (WRAPP (+ angle 0.5) 360.0))
          (set pos.y (+ 240 (* (cos angle) delta)))
          (set pos.x (WRAPP (+ pos.x 1) 640 ))))
        ".compileSLisp);
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
  Attacker[] attackers;
public:
  this( ) {
     for(int i = 0; i < 300; i++){
       attackers ~=  new Attacker();
     }
    //attackers2.insert( new Attacker());
    // }
    
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
    SDL_FillRect(_scr, null, 0x000000);
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
      // attackers.each!(x=>x.call());
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

import slisp;
void main(){
  wl(std.conv.to!float("0.0"));
  enum tokens = "(basicAttack
                  (prelude 
                    (define angle 0.0) 
                    (define delta (rnd 10 200)))
                  (update
                    (set angle (WRAPP (+ angle 0.05) 360.0))
                    (set pos.y (+ 240 (* (cos angle) delta)))
                    (set pos.x (WRAPP (+ pos.x 1) 640 ))))
                  ".tokenize();
                  //pos.x =WRAPP(pos.x+1,640);
  // wl(tokens);
  enum p = tokens.parse.SWrapper;
  import std.algorithm;
   
  enum c = compile(p);
  
   wl("!!",c);

  // wl(PrintExpression(p));
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
      SDL_Delay(cast(int)Game.delay_time-frameTime);
      //wl(frameTime);
    }else {writeln("ouch ", frameTime - Game.delay_time, " ", frameTime); }
    
  }
  game.Clean();
}
