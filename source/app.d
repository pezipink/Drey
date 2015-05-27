import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;
alias std.stdio.writeln wl;
import std.traits;
import core.thread;
immutable auto RGB_Yellow = SDL_Color(255, 255, 0, 0);

T WRAPP(T)(T x, T max) { return x > max ? x-max : x; }

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
//Disable();
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
  Attacker[10000] attackers;
public:
  this( ) {
    foreach(ref a; attackers)
      a = new Attacker();
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

    foreach(attacker;attackers){
      pset(cast(int)attacker.pos.x,cast(int)attacker.pos.y,RGB_Yellow);
      pset(cast(int)attacker.pos.x,cast(int)attacker.pos.y+1,RGB_Yellow);
      pset(cast(int)attacker.pos.x+1,cast(int)attacker.pos.y,RGB_Yellow);
      pset(cast(int)attacker.pos.x+1,cast(int)attacker.pos.y+1,RGB_Yellow);
  }
    SDL_UpdateTexture(_scrTex, null, _scr.pixels, _scr.pitch);
    SDL_RenderClear(_renderer);    
    SDL_RenderCopy(_renderer, _scrTex, null, null);
    SDL_RenderPresent(_renderer);
  }

  void Update() {
    import std.algorithm : each;
      attackers.each!(x=>x.call());
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



void main(){
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
    }else {writeln("ouch", frameTime - Game.delay_time); }
    
  }
  game.Clean();
}
