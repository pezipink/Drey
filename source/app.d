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
import MessageRouter;
import DeckControl;
import types;
alias wl = writeln;
import Messages;

class GameState
{
public:
  int mouseX, mouseY;
  Uint8* keyState;  
  bool gameRunning;
  static immutable float fps = 60.0;
  static immutable float delay_time = 1000.0 / fps;
  static immutable int width = 1600;
  static immutable int height = 900;
  SDL_Renderer* renderer;
  TTF_Font* font;
  Pandemic pandemic;
  bool IsKeyDown(SDL_Scancode code){ return keyState[code] == 1; }
  UnionMessageRouter!ControlMessages router;

  public void ShowText(const(char)* text, int x, int y, ubyte r, ubyte g, ubyte b, bool centre)
  {
    SDL_Color text_colour = SDL_Color(r,g,b);
    SDL_Surface* surface;
    scope(exit) SDL_FreeSurface(surface);    
    surface = TTF_RenderText_Solid(font,text,text_colour);
    SDL_Texture* font_tex = SDL_CreateTextureFromSurface(renderer,surface);
    scope(exit) SDL_DestroyTexture(font_tex);
    SDL_Rect dest;
    dest.x=x;
    dest.y=y;
    SDL_QueryTexture(font_tex, null, null, &dest.w,&dest.h);
    if(centre)
      {
        dest.x -= dest.w/2;
      }
    SDL_RenderCopy(renderer, font_tex, null, &dest);

  }

}


public class StatusControl : Control!GameState
{
  import Messages;
  string text = "hello world!";

  void HandleUpdate(ControlMessages message)
  {
    text = message.AsStatus.message;
  }
  this(CoreControl parent, GameState state)
  {
    super(parent);
    state.router.Subscribe(ControlMessages.Tags.Status, &HandleUpdate);
  }
  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    import std.string;
    state.ShowText(text.toStringz, relativeBounds.x, relativeBounds.y, 255,255,255,true);
  }
  
}

public class MainMenuControl : Control!GameState
{
  auto titleWidth = 976;
  auto mapHeight = 1340;
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
  }

  ubyte g = 255;
  override bool HandleInput(GameState state, InputMessage msg, SDL_Rect relativeBounds, bool handled){ return false; }
  override void Update(GameState state){ }
  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_SetRenderDrawColor(renderer,255,g,0,0);
    SDL_RenderFillRect(renderer,&relativeBounds);
  }
  override bool OnMouseEnter(GameState state, bool handled){g = 50; return false; }
  override bool OnMouseLeave(GameState state, bool handled){g = 255; return false; }
  
}


public class Window : Control!GameState
{

  this(Control!GameState parent,SDL_Rect bounds)
  {
    this.bounds = bounds;
    super(parent);

  }

  public void Test()
  {
    AddControl(new Window(this,SDL_Rect(30,30,100,100)));
  }

  ubyte g = 255;
  override bool HandleInput(GameState state, InputMessage msg, SDL_Rect relativeBounds, bool handlded){ return false; }
  override void Update(GameState state, ){ }
  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_SetRenderDrawColor(renderer,255,g,0,0);
    SDL_RenderFillRect(renderer,&relativeBounds);
  }
  override bool OnMouseEnter(GameState state, bool handled){g = 50; return false; }
  override bool OnMouseLeave(GameState state, bool handled){g = 255; return false; }
  
}


public class MapControl : Control!GameState
{

private:
  double _zoomLevel = 1.0;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  immutable _map_width = 1200.0;
  immutable _map_height = 849.0;

public:

  
  this(Control!GameState parent)
  {
    import std.path;
    import std.string;

    super(parent);
    bounds.x = 0;
    bounds.y = 0;
    bounds.w = GameState.width;
    bounds.h= GameState.height;
    //    auto w = new Window(this,SDL_Rect(30,30,500,500));
    //    AddControl(w);
    //    w.Test();
  }

  override void Update(GameState state)
  {
    // if( state.IsKeyDown(7))
    //   {
    //     // d
	
    //     _xOffset += 12.0;
    //     if( _xOffset > _map_width * _zoomLevel)
    //       {
    //         _xOffset -= _map_width * _zoomLevel;
    //       }
    //   }
    // if (state.IsKeyDown(4))
    //   {
    //     // a
    //     _xOffset -= 12.0;
    //     if( _xOffset < 0.0)
    //       {
    //         _xOffset += _map_width * _zoomLevel;
    //       }
    //   }
    // if( state.IsKeyDown(26) && _zoomLevel < 1.0)
    //   {
    //     // w
    //     _yOffset -= 2.0;
    //   }
    // if( state.IsKeyDown(22) )
    //   {
    //     // s
    //     _yOffset += 2.0;
    //   }
    // if( state.IsKeyDown(48) && _zoomLevel < 1.0)
    //   {
    //     // [
    //     _zoomLevel += 0.1;
    //   }
    // if( state.IsKeyDown(47) )
    //   {
    //     // ]
    //     _zoomLevel -= 0.1;
    //   }
    
    return;
  }

  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
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
    dst.h = cast(int)state.height - 50;
    dst.w = cast(int)(state.width * (1.0 - wpct));
    SDL_RenderCopy(renderer, TextureManager.GetTexture("map"), &src, &dst);
    src.x = 0;
    src.y = 0;
    src.w = cast(int)_xOffset;
    //src.h = cast(int)_yOffset;
    dst.x =  cast(int)(state.width * (1.0 - wpct));
    dst.y =  0;
    dst.w = cast(int)(state.width * wpct);
    dst.h = cast(int)state.height;
    SDL_RenderCopy(renderer, TextureManager.GetTexture("map"), &src, &dst);

    //   }
    
    // src.x=cast(int)_xOffset;
    // src.y=cast(int)_yOffset;
    // src.w=cast(int)(_map_width * _zoomLevel);
    // src.h=cast(int)(_map_height * _zoomLevel);
    
    // SDL_RenderDrawRect(renderer,&dest);
       
    return;
  }
}


class CoreControl : Control!GameState
{

public:
  this()
  {
    super(null);
  }

protected:
  
  override bool HandleInput(GameState state, InputMessage msg, SDL_Rect relativeBounds, bool handled)
  {
    return false;
  }

  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
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
    import std.path;
    import std.string;
    _state = new GameState();
    _window = SDL_CreateWindow
      ("Pandemic",
       SDL_WINDOWPOS_CENTERED,
       SDL_WINDOWPOS_CENTERED,
       _state.width,
       _state.height,
       SDL_WINDOW_SHOWN);
    SDL_SetWindowFullscreen(_window,SDL_WINDOW_FULLSCREEN);
    _state.renderer = SDL_CreateRenderer(_window,-1,SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
    //_state.textures = SDLTextureManager(_state.renderer);
    TextureManager.SetRenderer(_state.renderer);
    _state.pandemic = new Pandemic([Role.Tags.Medic,Role.Tags.Scientist],5);
    InitializeTextures();
    TTF_Init();    
    //_state.font = TTF_OpenFont(relativePath(r"..\leadcoat.ttf").toStringz,24);
    _state.font = TTF_OpenFont(r"c:\windows\fonts\lucon.ttf".toStringz,24);
    assert(_state.font);

    _core = new CoreControl();
    CreateControls();
    _state.gameRunning = true;
  }

  void InitializeTextures()
  {
    TextureManager.EnsureLoaded("playercards","images\\playercards.png");
    TextureManager.EnsureLoaded("title","images\\title.jpg");
    TextureManager.EnsureLoaded("map","images\\pandemicMap.jpg");
  }

  void CreateControls()
  {
    _core.AddControl(new MapControl(_core));
    auto status = new StatusControl(_core, _state);
    status.bounds.x = GameState.width/2-100;
    status.bounds.y = GameState.height-50;
    _core.AddControl(status);
    auto c =
      new DeckControls!(GameState,PlayerCard)
      (_core,
       _state.pandemic.playerCards.active_deck,
       SDL_Rect(0,0,100,140),
       (ref card,face,state, renderer, dest) =>
         {
           auto tex = TextureManager.GetTexture("playercards");
           assert(tex !is null);
           SDL_Rect r;
           r.w = 200;
           r.h = 290;

           if(face == DeckControl.Face.Front)
             {
               if(auto x = card.AsEpidemicCard)
                 {
                   r.x = 200;
                 }
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
    _core.CoreRender(_state,_state.renderer,_core.bounds);
    SDL_RenderPresent(_state.renderer);
  }

  void Update()
  {
    _core.CoreUpdate(_state);
    _state.router.ProcessMessages();
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
              (_state, new MouseMove(_state.mouseX,_state.mouseY),_core.bounds,false);
	    break;
	  case SDL_MOUSEBUTTONUP:
	    if(event.button.button == SDL_BUTTON_LEFT)
	      {
                _core.CoreHandleInput
                  (_state, new MouseButton(MouseButtonType.Left, _state.mouseX, _state.mouseY),_core.bounds,false);
	      }
            else if(event.button.button == SDL_BUTTON_RIGHT)
	      {
                _core.CoreHandleInput
                  (_state, new MouseButton(MouseButtonType.Right, _state.mouseX, _state.mouseY),_core.bounds,false);
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
  int slowFrames = 0;
  while(game.running)
  {
    frameStart = SDL_GetTicks();
    game.HandleEvents();
    game.Update();
    game.Render();

    frameTime = SDL_GetTicks() - frameStart;
    if( frameTime <= Game._state.delay_time )
    {
      SDL_Delay(cast(int)Game._state.delay_time-frameTime);
    }
    else 
    {
      slowFrames++;
       // writeln("ouch ", frameTime - Game._state.delay_time, " ", frameTime); 
    }
    
  }
  game.Clean();
  
  wl("SLOW FRAMES : ", slowFrames);

}

