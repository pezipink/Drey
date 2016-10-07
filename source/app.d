

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
  // static immutable int width = 1600;
  // static immutable int height = 900;
  static immutable int width = 1200;
  static immutable int height = 849;

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

public class CityControl : Control!GameState
{
  CityName city;

  this(Control!GameState parent, CityName city)
    {
      super(parent);
      this.city=city;
      wl(city);
      bounds = GetCityBounds(city);
    }

  public override void Update(GameState state)
  {
    
  }
  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    //    if(parent.mouseControl == this)
      {
        SDL_SetRenderDrawColor(renderer,255,0,0,0);
        SDL_RenderDrawRect(renderer,&relativeBounds);
        //wl("!",relativeBounds.x, " ", relativeBounds.y, relativeBounds.w);

 SDL_SetRenderDrawColor(renderer,255,255,0,0);
        SDL_RenderDrawRect(renderer,&bounds);
       
      }
    
  }
    override bool OnMouseEnter(GameState state, bool handled)
    {
      import std.conv;
      state.router.PostMessage(new Status(city.to!string));
      return false;
    }
  public static SDL_Rect GetCityBounds(CityName city)
  {
    SDL_Rect r;
    r.w=32;
    r.h=32;
    final switch(city)
      with(CityName)
        {
                  case Algiers: r.x = 569; r.y = 335; break;
                    //case Algiers: r.x = 609; r.y = 379; break;
        case Atlanta: r.x = 236; r.y = 353; break;
        case Baghdad: r.x = 750; r.y = 365; break;
        case Bangkok: r.x = 974; r.y = 472; break;
        case Beijing: r.x = 1013; r.y = 287; break;
        case Bogota: r.x = 285; r.y = 525; break;
        case BuenosAires: r.x = 360; r.y = 711; break;
        case Cairo: r.x = 676; r.y = 397; break;
        case Chennai: r.x = 913; r.y = 516; break;
        case Chicago: r.x = 204; r.y = 285; break;
        case Delhi: r.x = 900; r.y = 370; break;
        case Essen: r.x = 614; r.y = 219; break;
        case HoChiMinhCity: r.x = 1028; r.y = 537; break;
        case HongKong: r.x = 1025; r.y = 430; break;
        case Istanbul: r.x = 687; r.y = 319; break;
        case Jakarta: r.x = 974; r.y = 597; break;
        case Johannesburg: r.x = 688; r.y = 666; break;
        case Karachi: r.x = 835; r.y = 397; break;
        case Khartoum: r.x = 694; r.y = 489; break;
        case Kinshasa: r.x = 635; r.y = 578; break;
        case Kolkata: r.x = 962; r.y = 394; break;
        case Lagos: r.x = 583; r.y = 509; break;
        case Lima: r.x = 254; r.y = 624; break;
        case London: r.x = 524; r.y = 236; break;
        case LosAngeles: r.x = 109; r.y = 413; break;
        case Madrid: r.x = 513; r.y = 328; break;
        case Manila: r.x = 1115; r.y = 532; break;
        case MexicoCity: r.x = 192; r.y = 445; break;
        case Miami: r.x = 292; r.y = 430; break;
        case Milan: r.x = 649; r.y = 263; break;
        case Montreal: r.x = 293; r.y = 284; break;
        case Moscow: r.x = 757; r.y = 263; break;
        case Mumbai: r.x = 844; r.y = 465; break;
        case NewYork: r.x = 360; r.y = 293; break;
        case Osaka: r.x = 1160; r.y = 389; break;
        case Paris: r.x = 589; r.y = 282; break;
        case Riyadh: r.x = 761; r.y = 450; break;
        case SanFrancisco: r.x = 90; r.y = 319; break;
        case Santiago: r.x = 265; r.y = 731; break;
        case SaoPaulo: r.x = 409; r.y = 640; break;
        case Seoul: r.x = 1092; r.y = 281; break;
        case Shanghai: r.x = 1018; r.y = 351; break;
        case StPetersburg: r.x = 711; r.y = 200; break;
        case Sydney: r.x = 1165; r.y = 724; break;
        case Taipei: r.x = 1093; r.y = 419; break;
        case Tehran: r.x = 818; r.y = 306; break;
        case Tokyo: r.x = 1153; r.y = 317; break;
        case Washington: r.x = 330; r.y = 347; break;
        }
    return r;
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

  int city  = -1;
  this(Control!GameState parent)
    {
      import std.path;
      import std.string;

      super(parent);
      // the map handles rendering its own childrne onto a separate texture
      autoRenderChildren = false;
      TextureManager.EnsureLoaded("map","images\\pandemicMap.jpg");
      TextureManager.ReplicateAsTargetTexture("map","map_target");
      bounds.x = 0;
      bounds.y = 0;
      bounds.w = GameState.width;
      bounds.h= GameState.height;
      //    auto w = new Window(this,SDL_Rect(30,30,500,500));
      //    AddControl(w);
      //    w.Test();
      for(int i =0; i<48; i++)
        {
          AddControl(new CityControl(this,cast(CityName)i));
        }
    }

  void UpdateCity(GameState state)
  {
    city++;
    auto c = cast(CityName)city;
    import std.conv : to;
    state.router.PostMessage(new Status(c.to!string));
  }
    override bool OnMouseClick(GameState state, bool handled, MouseButtonType button, int x, int y)
    {
          import std.conv : to;
          auto c = cast(CityName)city;
      import std.stdio; alias wl = writeln;
      wl(x, " " , y);
      wl("case ",c.to!string, ": r.x = ", state.mouseX, "; r.y = ", state.mouseY, "; break;\n");
      UpdateCity(state);
      return true;
    }
  
    override void Update(GameState state)
    {
      if(city == -1 ) UpdateCity(state);
    }
  //   {
  //     // if( state.IsKeyDown(7))
  //     //   {
  //     //     // d
	
  //     //     _xOffset += 12.0;
  //     //     if( _xOffset > _map_width * _zoomLevel)
  //     //       {
  //     //         _xOffset -= _map_width * _zoomLevel;
  //     //       }
  //     //   }
  //     // if (state.IsKeyDown(4))
  //     //   {
  //     //     // a
  //     //     _xOffset -= 12.0;
  //     //     if( _xOffset < 0.0)
  //     //       {
  //     //         _xOffset += _map_width * _zoomLevel;
  //     //       }
  //     //   }
  //     // if( state.IsKeyDown(26) && _zoomLevel < 1.0)
  //     //   {
  //     //     // w
  //     //     _yOffset -= 2.0;
  //     //   }
  //     // if( state.IsKeyDown(22) )
  //     //   {
  //     //     // s
  //     //     _yOffset += 2.0;
  //     //   }
  //     // if( state.IsKeyDown(48) && _zoomLevel < 1.0)
  //     //   {
  //     //     // [
  //     //     _zoomLevel += 0.1;
  //     //   }
  //     // if( state.IsKeyDown(47) )
  //     //   {
  //     //     // ]
  //     //     _zoomLevel -= 0.1;
  //     //   }
    
  //     return;
  //   }

  override void Render(GameState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    SDL_Rect src;
    SDL_Rect dst;
    SDL_Rect map;
    map.w = 1200;
    map.h =849;
    // int width = cast(int)(_map_width * _zoomLevel);
    // int height = cast(int)(_map_height * _zoomLevel);
    SDL_SetRenderTarget(renderer,TextureManager.GetTexture("map_target"));
    // copy the map
    SDL_RenderCopy(renderer,TextureManager.GetTexture("map"),&map,&map);
    // render children onto target texture
    foreach(c;_children) c.CoreRender(state,renderer,PerformOffset(c.bounds,0,0));
    // set the renderer back
    SDL_SetRenderTarget(renderer,null);
    // now we can render the correct portions of the map depending on scroll
    // and zoom (todo)
    SDL_RenderCopy(renderer,TextureManager.GetTexture("map_target"),&map,&map);

    SDL_Rect r;
    r.w = 32;
    r.h = 32;
    r.x = state.mouseX;
    r.y = state.mouseY;
    SDL_SetRenderDrawColor(renderer,255,255,255,0);
    SDL_RenderDrawRect(renderer,&r);
    
    // src.x = cast(int)_xOffset;
    // src.y = cast(int)_yOffset;
    // //src.w =cast(int)( _map_width - _xOffset);
    // src.w =cast(int)( width - _xOffset);
    // src.h =cast(int)( height -_yOffset);

    // double wpct = 0.0;
    // if( _xOffset > 0.0 )
    //   {
    //     //	wpct = _xOffset / _map_width;
    //    	wpct = _xOffset / width;
    //   }
    
    // //dst.x = cast(int)( _state.width * wpct);

    // dst.x = 0;
    // dst.y = 0;
    // dst.h = cast(int)state.height - 50;
    // dst.w = cast(int)(state.width * (1.0 - wpct));
    // SDL_RenderCopy(renderer, TextureManager.GetTexture("map"), &src, &dst);
    // src.x = 0;
    // src.y = 0;
    // src.w = cast(int)_xOffset;
    // //src.h = cast(int)_yOffset;
    // dst.x =  cast(int)(state.width * (1.0 - wpct));
    // dst.y =  0;
    // dst.w = cast(int)(state.width * wpct);
    // dst.h = cast(int)state.height;
    // SDL_RenderCopy(renderer, TextureManager.GetTexture("map"), &src, &dst);

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
    int w, h ;
    SDL_GetWindowSize(_window,&w,&h);
    wl("window state : ", w, " ", h);
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
    
    TextureManager.EnsureLoaded("roletcards","images\\rolecards.jpg");
    TextureManager.EnsureLoaded("eventcards","images\\eventcards.jpg");
    TextureManager.EnsureLoaded("epidemics","images\\epidemics.jpg");
    TextureManager.EnsureLoaded("infectioncards","images\\infectioncards.jpg");
    TextureManager.EnsureLoaded("title","images\\title.jpg");
    TextureManager.EnsureLoaded("playercards","images\\playercards.jpg");
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
           r.w = 180;
           r.h = 254;
           // 255
           // 182
           if(face == DeckControl.Face.Front)
             {
               if(auto z = card.AsEpidemicCard)
                 {
                   int x = 49 % 25;
                   int y = 49 / 2;
                   r.x = r.w*x;
                   r.y = r.h*y;
                 }
               else if(auto z = card.AsCityCard)
                 {
                   int c = (cast(int)z.city);
                   int x = c % 25;
                   int y = c % 2;
                   r.x = r.w*x;
                   r.y = r.h*y;

                 }
             }
           else
             {
               r.x = r.w*48;
               r.y = 0;
             }
           SDL_RenderCopy(renderer, tex, &r, &dest);

                            
         }());
    auto d=
      new DeckControls!(GameState,InfectionCard)
      (_core,
       _state.pandemic.infectionCards.active_deck,
       SDL_Rect(200,0,255,182),
       (ref card,face,state, renderer, dest) =>
         {
           auto tex = TextureManager.GetTexture("infectioncards");
           assert(tex !is null);
           SDL_Rect r;
           r.w = 255;
           r.h = 182;
           // 255
           // 182
           if(face == DeckControl.Face.Front)
             {
               if(auto z = card.AsCityInfectionCard)
                 {
                   int c = (cast(int)z.city);
                   int x = c % 25;
                   int y = c / 25;
                   r.x = r.w*x;
                   r.y = r.h*y;
                 }

             }
           else
             {
               r.x = r.w*23;
               r.y = r.h;
             }
           SDL_RenderCopy(renderer, tex, &r, &dest);

                            
         }());
 
    // _core.AddControl(c);
    // _core.AddControl(d);
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

