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
  // static immutable int width = 1200;
  // static immutable int height = 849;

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

        case Algiers: r.x = 571; r.y = 335; break;
        case Atlanta: r.x = 222; r.y = 309; break;
        case Baghdad: r.x = 703; r.y = 322; break;
        case Bangkok: r.x = 912; r.y = 413; break;
        case Beijing: r.x = 948; r.y = 252; break;
        case Bogota: r.x = 267; r.y = 463; break;
        case BuenosAires: r.x = 335; r.y = 625; break;
        case Cairo: r.x = 633; r.y = 351; break;
        case Chennai: r.x = 854; r.y = 453; break;
        case Chicago: r.x = 190; r.y = 249; break;
        case Delhi: r.x = 842; r.y = 325; break;
        case Essen: r.x = 574; r.y = 193; break;
        case HoChiMinhCity: r.x = 964; r.y = 473; break;
        case HongKong: r.x = 962; r.y = 378; break;
        case Istanbul: r.x = 643; r.y = 280; break;
        case Jakarta: r.x = 912; r.y = 526; break;
        case Johannesburg: r.x = 644; r.y = 587; break;
        case Karachi: r.x = 782; r.y = 349; break;
        case Khartoum: r.x = 649; r.y = 432; break;
        case Kinshasa: r.x = 597; r.y = 504; break;
        case Kolkata: r.x = 900; r.y = 345; break;
        case Lagos: r.x = 544; r.y = 447; break;
        case Lima: r.x = 236; r.y = 551; break;
        case London: r.x = 491; r.y = 206; break;
        case LosAngeles: r.x = 102; r.y = 361; break;
        case Madrid: r.x = 479; r.y = 289; break;
        case Manila: r.x = 1045; r.y = 469; break;
        case MexicoCity: r.x = 178; r.y = 391; break;
        case Miami: r.x = 274; r.y = 378; break;
        case Milan: r.x = 608; r.y = 232; break;
        case Montreal: r.x = 273; r.y = 248; break;
        case Moscow: r.x = 708; r.y = 229; break;
        case Mumbai: r.x = 791; r.y = 411; break;
        case NewYork: r.x = 335; r.y = 257; break;
        case Osaka: r.x = 1085; r.y = 342; break;
        case Paris: r.x = 551; r.y = 247; break;
        case Riyadh: r.x = 711; r.y = 397; break;
        case SanFrancisco: r.x = 84; r.y = 278; break;
        case Santiago: r.x = 248; r.y = 643; break;
        case SaoPaulo: r.x = 383; r.y = 565; break;
        case Seoul: r.x = 1020; r.y = 248; break;
        case Shanghai: r.x = 953; r.y = 309; break;
        case StPetersburg: r.x = 665; r.y = 175; break;
        case Sydney: r.x = 1091; r.y = 637; break;
        case Taipei: r.x = 1026; r.y = 368; break;
        case Tehran: r.x = 765; r.y = 271; break;
        case Tokyo: r.x = 1084; r.y = 282; break;
        case Washington: r.x = 308; r.y = 307; break;

        }
    return r;
  }

}
public class StatusControl : Control!GameState
{
  import Messages;
  string text = "hello world!";

  void HandleUpdate(Status message)
  {
    text = message.message;
  }
  this(CoreControl parent, GameState state)
  {
    super(parent);
    state.router.Subscribe!Status(&HandleUpdate);
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
  immutable _map_width = 1200;
  immutable _map_height = 849;

 public:

  int city  = -1;
  this(Control!GameState parent)
    {
      import std.path;
      import std.string;

      super(parent);
      // the map handles rendering its own childrne onto a separate texture
      //autoRenderChildren = false;
      TextureManager.EnsureLoaded("map","images\\pandemicMap.jpg");
      TextureManager.ReplicateAsTargetTexture("map","map_target");
      bounds.x = (GameState.width - _map_width) / 2 ;
      bounds.y = 0;
      bounds.w =_map_width;
      bounds.h= _map_height;

      // infection deck
      // 914, 45
      // 177, 126
      // auto c =

      for(int i =0; i<48; i++)
        {
          AddControl(new CityControl(this,cast(CityName)i));
        }
    }

  override void Initialize(GameState state)
  {
    // infection deck
    // 914, 45
    // 177, 126
    auto c =
      new DeckControls!(GameState,PlayerCard)
      (this,
       state.pandemic.playerCards.active_deck,
       SDL_Rect(357,310,129,180),
       (ref card,face,state, renderer, dest) =>
         {
           auto tex = TextureManager.GetTexture("playercards");
           assert(tex !is null);
           SDL_Rect r;
           r.w = 180;
           r.h = 254;
           if(face == DeckControl.Face.Front)             
             {
               if(auto z = card.AsEpidemicCard)
                 {
                   int x = 49 % 25;
                   int y = 49 / 25;
                   r.x = r.w*x;
                   r.y = r.h*y;
                 }
               else if(auto z = card.AsCityCard)
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
               int x = 48 % 25;
               int y = 48 / 25;
               r.x = r.w*x;
               r.y = r.h*y;
             }
           SDL_RenderCopy(renderer, tex, &r, &dest);

                            
         }());
    auto c2 =
      new DeckControls!(GameState,PlayerCard)
      (this,
       state.pandemic.playerCards.discard_deck,
       SDL_Rect(400,310,129,180),
       (ref card,face,state, renderer, dest) =>
         {
           auto tex = TextureManager.GetTexture("playercards");
           assert(tex !is null);
           SDL_Rect r;
           r.w = 180;
           r.h = 254;
           if(face == DeckControl.Face.Front)             
             {
               if(auto z = card.AsEpidemicCard)
                 {
                   int x = 49 % 25;
                   int y = 49 / 25;
                   r.x = r.w*x;
                   r.y = r.h*y;
                 }
               else if(auto z = card.AsCityCard)
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
               int x = 48 % 25;
               int y = 48 / 25;
               r.x = r.w*x;
               r.y = r.h*y;
             }
           SDL_RenderCopy(renderer, tex, &r, &dest);

                            
         }());


    auto d=
      new DeckControls!(GameState,InfectionCard)
      (this,
       state.pandemic.infectionCards.active_deck,
       SDL_Rect(355,25,177,126),
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

    c.EnsureFaces(Face.Back);
    d.EnsureFaces(Face.Back);
    AddControl(c);
    AddControl(c2);
    AddControl(d);
    wl("here");
  }
  
  void UpdateCity(GameState state)
  {
    city++;
    auto c = cast(CityName)city;
    import std.conv : to;

  }
  override bool OnMouseClick(GameState state, bool handled, MouseButtonType button, int x, int y)
  {
    import std.conv : to;
    auto c = cast(CityName)city;
    import std.stdio; alias wl = writeln;
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
    map.w = 600;
    map.h = 424;

    // int width = cast(int)(_map_width * _zoomLevel);
    // int height = cast(int)(_map_height * _zoomLevel);
    //SDL_SetRenderTarget(renderer,TextureManager.GetTexture("map_target"));
    // copy the map
    SDL_RenderCopy(renderer,TextureManager.GetTexture("map"),null,&relativeBounds);
    // render children onto target texture
    //foreach(c;_children) c.CoreRender(state,renderer,bounds);
    // set the renderer back
    //SDL_SetRenderTarget(renderer,null);
    // now we can render the correct portions of the map depending on scroll
    // and zoom (todo)
    //SDL_RenderCopy(renderer,TextureManager.GetTexture("map_target"),null,&bounds);

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

    //SDL_SetWindowFullscreen(_window,SDL_WINDOW_FULLSCREEN);
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
    _core.CoreInitialize(_state);
    _state.gameRunning = true;
    //    _state.router.Subscribe!ControlMessages.Tags.Test(HandleUpdate);

  }
  void HandleUpdate(Test message)
  {
    wl("here!!");
    _state.pandemic.playerCards.discard(_state.pandemic.playerCards.drawSingle());
    wl("cc ", _state.pandemic.playerCards.active_deck.length);

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

