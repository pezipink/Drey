
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import derelict.sdl2.mixer;
import control;
import std.stdio;
import std.typecons;
import du;
import pandemic;
import TextureManager;
import DeckControl;
import types;
alias wl = writeln;


class GameState
{
public:
  int mouseX, mouseY;
  Uint8* keyState;  
  bool gameRunning;
  static immutable float fps = 60.0;
  static immutable float delay_time = 1000.0 / fps;
  int width = 1600;
  int height = 900;
  SDL_Renderer* renderer;
  SDLTextureManager textures;
  Pandemic pandemic;
  bool IsKeyDown(SDL_Scancode code){ return keyState[code] == 1; }

 
}


mixin(DU!q{

Union GameStates =
  | MainMenu
  | InPlay of state : Pandemic


});

public class MainMenuControl : Control
{
  SDL_Texture* title;
  auto titleWidth = 976;
  auto titleHeight = 1340;
  enum ButtonId
    {
      SinglePlayer,
      Exit
    }

  this(CoreControl parent,SDL_Rect bounds)
  {
    import std.path;
    import std.string;
    this.bounds = bounds;
    super(parent);
    auto surf = IMG_Load(relativePath(r"images\title.jpg").toStringz);
    title = SDL_CreateTextureFromSurface(parent.state.renderer,surf);
    SDL_FreeSurface(surf);

  }

  ubyte g = 255;
  override bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled){ return false; }
  override void Update(){ }
  override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_SetRenderDrawColor(renderer,255,g,0,0);
    SDL_RenderFillRect(renderer,&relativeBounds);
  }
  override bool OnMouseEnter(bool handled){g = 50; return false; }
  override bool OnMouseLeave(bool handled){g = 255; return false; }
  
}


public class Window : Control
{

  this(Control parent,SDL_Rect bounds)
  {
    this.bounds = bounds;
    super(parent);

  }

  public void Test()
  {
    AddControl(new Window(this,SDL_Rect(30,30,100,100)));
  }

  ubyte g = 255;
  override bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handlded){ return false; }
  override void Update(){ }
  override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_SetRenderDrawColor(renderer,255,g,0,0);
    SDL_RenderFillRect(renderer,&relativeBounds);
  }
  override bool OnMouseEnter(bool handled){g = 50; return false; }
  override bool OnMouseLeave(bool handled){g = 255; return false; }
  
}


public class MapControl : Control
{

private:
  SDL_Texture* _map;
  double _zoomLevel = 1.0;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  immutable _map_width = 1200.0;
  immutable _map_height = 849.0;
  GameState _state;
public:

  
  this(Control parent, GameState state)
  {
    import std.path;
    import std.string;
    _state = state;
    super(parent);
    bounds.x = 0;
    bounds.y = 0;
    bounds.w = _state.width;
    bounds.h= _state.height;
    auto surf = IMG_Load(relativePath(r"images\pandemicMap.jpg").toStringz);
    _map = SDL_CreateTextureFromSurface(_state.renderer,surf);
    SDL_FreeSurface(surf);
    auto w = new Window(this,SDL_Rect(30,30,500,500));
    AddControl(w);
    w.Test();
  }

  override void Update()
  {
    if( _state.IsKeyDown(7))
      {
	// d
	
	_xOffset += 12.0;
	if( _xOffset > _map_width * _zoomLevel)
	  {
	    _xOffset -= _map_width * _zoomLevel;
	  }
      }
    if (_state.IsKeyDown(4))
      {
	// a
	_xOffset -= 12.0;
	if( _xOffset < 0.0)
	  {
	    _xOffset += _map_width * _zoomLevel;
	  }
      }
    if( _state.IsKeyDown(26) && _zoomLevel < 1.0)
      {
	// w
	_yOffset -= 2.0;
      }
    if( _state.IsKeyDown(22) )
      {
	// s
	_yOffset += 2.0;
      }
    if( _state.IsKeyDown(48) && _zoomLevel < 1.0)
      {
	// [
	_zoomLevel += 0.1;
      }
    if( _state.IsKeyDown(47) )
      {
	// ]
	_zoomLevel -= 0.1;
      }
    
    return;
  }

  override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_SetRenderDrawColor(renderer,255,0,0,0);
    SDL_Rect src;
    SDL_Rect dst;
    int width = cast(int)(_map_width * _zoomLevel);
    int height = cast(int)(_map_height * _zoomLevel);

   
    src.x = cast(int)_xOffset;
    src.y = cast(int)_yOffset;
    //src.w =cast(int)( _map_width - _xOffset);
    src.w =cast(int)( width - _xOffset);
    src.h =cast(int)( height -_yOffset);

    double wpct = 0.0;
    if( _xOffset > 0.0 )
      {
	//	wpct = _xOffset / _map_width;
       	wpct = _xOffset / width;
      }
    
    //dst.x = cast(int)( _state.width * wpct);

    dst.x = 0;
    dst.y = 0;
    dst.h = cast(int) _state.height;
    dst.w = cast(int)( _state.width * (1.0 - wpct));
    SDL_RenderCopy(renderer, _map, &src, &dst);
    src.x = 0;
    src.y = 0;
    src.w = cast(int)_xOffset;
    //src.h = cast(int)_yOffset;
    dst.x =  cast(int)( _state.width * (1.0 - wpct));
    dst.y =  0;
    dst.w = cast(int)(_state.width * wpct);
    dst.h = cast(int)_state.height;
    SDL_RenderCopy(renderer, _map, &src, &dst);

    //   }
    
    // src.x=cast(int)_xOffset;
    // src.y=cast(int)_yOffset;
    // src.w=cast(int)(_map_width * _zoomLevel);
    // src.h=cast(int)(_map_height * _zoomLevel);
    
    // SDL_RenderDrawRect(renderer,&dest);
       
    return;
  }
}


class CoreControl : Control
{

public:
  this(GameState state)
  {
    super(null);
    this.state = state;
  }


  GameState state;

protected:
  
  override bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled)
  {
    return false;
  }


  override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    return;
  }
}



class Game
{
  // SDL stuff
  SDL_Window* _window;
  SDL_Surface* _scr;
  CoreControl _core;
  GameState _state;
  void Init()
  {
    _state = new GameState();
    _window = SDL_CreateWindow
      ("Pandemic",
       SDL_WINDOWPOS_CENTERED,
       SDL_WINDOWPOS_CENTERED,
       _state.width,
       _state.height,
       SDL_WINDOW_SHOWN);
    //SDL_SetWindowFullscreen(_window,SDL_WINDOW_FULLSCREEN);
    _state.renderer = SDL_CreateRenderer(_window,-1,SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
    _state.textures = SDLTextureManager(_state.renderer);
    _state.pandemic = new Pandemic([Role.Tags.Medic,Role.Tags.Scientist],5);
    InitializeTextures();
    _core = new CoreControl(_state);
    CreateControls();
    _state.gameRunning = true;
  }

  void InitializeTextures()
  {
    _state.textures.EnsureLoaded("playercards","images\\playercards.png");
  }

  void CreateControls()
  {
    _core.AddControl(new MapControl(_core,_state));
    auto c =
      new DeckControls!PlayerCard
      (_core,
       _state.pandemic.playerCards.active_deck,
       SDL_Rect(0,0,100,140),
       (ref card,face, renderer, dest) =>
         {
           auto tex = _state.textures.GetTexture("playercards");
           SDL_Rect r;
           r.w = 200;
           r.h = 290;

           if(face == DeckControl.Face.Front)
             {
             }
           else
             {
               r.x = 200;
               r.y = 290;
             }
           SDL_RenderCopy(renderer, tex, &r, &dest);

         }());
    _core.AddControl(c);
  }
    

  void Render()
  {
    SDL_SetRenderDrawColor(_state.renderer,0,0,0,0);
    SDL_RenderFillRect(_state.renderer, null);
    _core.CoreRender(_state.renderer,_core.bounds);
    SDL_RenderPresent(_state.renderer);
  }

  void Update()
  {
    _core.CoreUpdate();
  }
    
  void HandleEvents()
  {
    _state.keyState = SDL_GetKeyboardState(null);
    if(_state.IsKeyDown(SDL_SCANCODE_ESCAPE)) 
      {
	_state.gameRunning=false;
      }

    SDL_Event event;
    while (SDL_PollEvent(&event))
      {
	switch(event.type)
	  {
	  case SDL_KEYDOWN:
	    switch(event.key.keysym.sym)
	      {
	      case 'm':
		{
		  break;
		}            
	      default:
		break;
	      }
	    break;
	  case SDL_MOUSEMOTION:
            
	    _state.mouseX = event.motion.x;
	    _state.mouseY = event.motion.y;
            _core.CoreHandleInput
              (new MouseMove(_state.mouseX,_state.mouseY),_core.bounds,false);
	    break;
	  case SDL_MOUSEBUTTONUP:
	    if(event.button.button == SDL_BUTTON_LEFT)
	      {
                _core.CoreHandleInput
                  (new MouseButton(MouseButtonType.Left, _state.mouseX, _state.mouseY),_core.bounds,false);
	      }
            else if(event.button.button == SDL_BUTTON_RIGHT)
	      {
                _core.CoreHandleInput
                  (new MouseButton(MouseButtonType.Right, _state.mouseX, _state.mouseY),_core.bounds,false);
	      }

	    break;
	  case SDL_QUIT:
	    _state.gameRunning=false;
	    break;

	  default:
	    break;  
	  }
      }
  }

  void Clean()
  {
    SDL_DestroyWindow(_window);
    SDL_DestroyRenderer(_state.renderer);
    SDL_Quit();
  };

  @property bool running() { return _state.gameRunning; }

}

void main()
{
  DerelictSDL2.load();
  DerelictSDL2Image.load();
  DerelictSDL2ttf.load();
  DerelictSDL2Mixer.load();

  auto game = new Game();
  
  uint frameStart, frameTime;
  game.Init();
  //  wl("init ", Game.delay_time);
  while(game.running)
  {
    frameStart = SDL_GetTicks();
    game.HandleEvents();
    game.Update();
    game.Render();

    frameTime = SDL_GetTicks() - frameStart;
    if( frameTime < Game._state.delay_time )
    {
      SDL_Delay(cast(int)Game._state.delay_time-frameTime);
    }
    else 
    {
       writeln("ouch ", frameTime - Game._state.delay_time, " ", frameTime); 
    }
    
  }
  game.Clean();



  
  wl("dtest");










}

