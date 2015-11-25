import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import derelict.sdl2.mixer;
import jazz;
import std.algorithm;
import std.string;
import std.array;
import std.stdio;
import std.typecons;
import core.thread;
import du;
alias std.stdio.writeln wl;
import fi;
import maths.vector;
const auto RGB_Yellow = SDL_Color(255, 255, 0, 0);
const auto RGB_Red = SDL_Color(255, 0, 0, 0);
const auto RGB_Green = SDL_Color(0, 255, 0, 0);
const auto RGB_Blue = SDL_Color(0, 0, 255, 0);
const auto RGB_White  = SDL_Color(255, 255, 255, 0);
const auto RGB_Black  = SDL_Color(0, 0, 0, 0);

T WRAPP(T)(T x, T max) { return x > max ? x-max : x; }

class CardFlipFiber : Fiber
{
    SDL_Renderer* renderer;
    SDL_Texture* tex;
    SDL_Rect srcr, destr;
    const ImageData imageData;
    int currentStep = 0;
    float x,y;
    float xd, yd;
    int duration = 60;
    int width = 409/4;
    int height = 585/4;
    float shrinkFactor;
    float wz;

    void delegate() callback;   
    
    this(
      SDL_Renderer* _renderer,
      SDL_Texture* _tex,
      const ImageData _imageData,
      vec2 source,
      vec2 dest,
      void delegate() _callback)
    {
      import std.conv : to;
      renderer = _renderer;
      assert(renderer);
      imageData = _imageData;
      tex = _tex;
      assert(tex);
      callback = _callback;
      
      srcr.y = imageData.BackRow * imageData.itemHeight;
      srcr.x = imageData.BackCol * imageData.itemWidth;
      srcr.w = imageData.itemWidth;
      srcr.h = imageData.itemHeight; 

      destr.y = to!int(source.y*height);
      destr.x = to!int(source.x*width);
      destr.w = width;
      destr.h = height; 
      // work out the direction we are going thats longest
      x = source.x * width;
      y = source.y * height;
      float xl, yl;
      xl = dest.x < source.x ? source.x - dest.x : dest.x - source.x;
      yl = dest.y < source.y ? source.y - dest.y : dest.y - source.y; 
      xl *= width;
      yl *= height;
      //assume we want the animation to take 1 second and we are running 60fps
      //work out the steps for the x and y axis to take that long
      xd = xl / duration;
      yd = yl / duration;
      shrinkFactor = (width  ) / (duration / 2);
      wz = width;
      if(dest.x < source.x) xd = -xd;
      if(dest.y < source.y) yd = -yd;
      super( &run );
    }

private :
    void run()
    {
      import std.conv : to;
      void update() 
      {
        currentStep++;
        SDL_RenderCopy(renderer, tex, &srcr, &destr);

        x += xd;
        y += yd;
        destr.w = to!int(wz);
        destr.x = to!int(x);
        destr.y = to!int(y);
        Fiber.yield();
      }
      while(currentStep < duration / 2)
      {
        
        wz -= shrinkFactor;
        update();
      }
      
      srcr.y = imageData.FrontRow * imageData.itemHeight;
      srcr.x = imageData.FrontCol * imageData.itemWidth;     
        
      while(currentStep < duration)
      {
        wz += shrinkFactor;
       update();
      }
     callback();
    }
}

mixin(DU!q{
  ActionMode =
  | NoneActionMode
  | DiscardActionMode
  | MoveActionMode of role : Role
  | ShoreUpActionMode
  | TradeActionMode 
  | ClaimActionMode  
});

private auto toText(ActionMode mode)  
{
  if(mode.IsNoneActionMode) return "None";
  if(mode.IsMoveActionMode) return "Move";
  if(mode.IsShoreUpActionMode) return "ShoreUp";
  if(mode.IsTradeActionMode) return "Trade";
  if(mode.IsClaimActionMode) return "Claim";
  assert(0);
}

private auto toText(Role role)  
{
  if(role.IsDiver) return "Diver";
  if(role.IsPilot) return "Pilot";
  if(role.IsMessenger) return "Messenger";
  if(role.IsExplorer) return "Explorer";
  if(role.IsEngineer) return "Engineer";
  if(role.IsNavigator) return "Navigator";
  assert(0);
}


private auto toColour(Role role)  
{
  if(role.IsDiver) return RGB_Black;
  if(role.IsPilot) return RGB_Blue;
  if(role.IsMessenger) return RGB_White;
  if(role.IsExplorer) return RGB_Green;
  if(role.IsEngineer) return RGB_Red;
  if(role.IsNavigator) return RGB_Yellow;
  assert(0);
}

class Game
{    
private:  
  // statics / constants
  static immutable int fps = 60;
  static immutable float delay_time = 1000.0 / fps;
  static immutable screen_width = 640;
  static immutable screen_height = 480;
  static immutable island_x_offset = 5;
  static treasure_deck_location = tuple(2,13);
  static flood_deck_location = tuple(3,13);
  static flood_deck_discard_location = tuple(3,12);
  static immutable trasureBackImage = treasureImageMap["Earth"];
  
  // SDL stuff
  SDL_Window* _window;
  SDL_Renderer* _renderer;
  SDL_Surface* _scr;
  SDL_Surface* _fi_surf, _fi_title_surf;
  SDL_Texture* _fi_tex, _fi_title_tex;
  SDL_Texture* _scrTex;
  TTF_Font* _font;

  Mix_Chunk* swoosh, sinking, sunk, alert, background, move, shoreup;

  // game state / flags etc 
  auto _fi = new ForbiddenIsland();
  int mouseX, mouseY;
  int waitingOnUser = false;
  int pulseTimer;
  int playerIndex = 0; // so we can detect when players change
  bool pulse;
  bool gameRunning = false;
  // current user selected action mode
  ActionMode currentMode = new NoneActionMode();
  // list of current available actions from the server
  Action[] currentActions;
  // x/y grid map of stuff that is currently flashing and can be clicked on
  Tuple!(int, int, const SDL_Color)[] actionIndicators;
  // map from flashing thing above into the action to be processed
  Action[Tuple!( int, int)] locationActionMap;
  // map of x/y grid coords to player's treasure items
  Tuple!(int, int)[Treasure] locationTreasureMap;
  // some actions are stateful, if one is progressing then this is it!
  Action currentAction;

  //animation fibers
  Fiber flipper;

public:
  this( ) 
  {         
  }
  void Init()
  {
    import std.file;
    import std.path;
    SDL_Init(SDL_INIT_EVERYTHING);  
    TTF_Init();
    
    _font = TTF_OpenFont(relativePath(r"..\kalinga.ttf").toStringz,24);
    assert(_font);
    
    _window = SDL_CreateWindow("Forbidden Island", SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,1600,900,SDL_WINDOW_SHOWN);
    // SDL_SetWindowFullscreen(_window,SDL_WINDOW_FULLSCREEN);
    _renderer = SDL_CreateRenderer(_window,-1,0);

    _fi_surf = IMG_Load(relativePath(r"images\fi.jpg").toStringz);
    _fi_title_surf = IMG_Load(relativePath(r"images\fi_title.jpg").toStringz);
    assert(_fi_surf);

    _scr = SDL_CreateRGBSurface(0, 1600, 900, 32,
                                        0x00FF0000,
                                        0x0000FF00,
                                        0x000000FF,
                                        0xFF000000);
    _scrTex = SDL_CreateTexture(_renderer,
                                            SDL_PIXELFORMAT_ARGB8888,
                                            SDL_TEXTUREACCESS_STREAMING,
                                            640, 480);

    _fi_tex = SDL_CreateTextureFromSurface(_renderer,_fi_surf);
    assert(_fi_tex);
    _fi_title_tex = SDL_CreateTextureFromSurface(_renderer,_fi_title_surf);

    Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 4096);
    swoosh = Mix_LoadWAV(r"sounds\swoosh.wav");
    sinking  = Mix_LoadWAV(r"sounds\sinking.wav");
    sunk  = Mix_LoadWAV(r"sounds\sunk.wav");
    alert   = Mix_LoadWAV(r"sounds\alert.wav");
    background   = Mix_LoadWAV(r"sounds\background.wav");
    move   = Mix_LoadWAV(r"sounds\move.wav");
    shoreup   = Mix_LoadWAV(r"sounds\shoreup.wav");
    assert(swoosh);
    _fi.initialize([new Navigator(),  new Diver(), new Pilot(), new Engineer()],3);
    gameRunning = true;
    Mix_PlayChannel(-1,background,-1);
    SDL_FreeSurface(_fi_surf);
  };
  
  @system
  private void pset(int x, int y, const SDL_Color color)
  {
    // set individual pixels
    if(x < 0 || y < 0 || x >= screen_width || y >= screen_height) return;
    uint colorSDL = SDL_MapRGB(_scr.format, color.r, color.g, color.b);
    uint* bufp;
    bufp = cast(uint*)_scr.pixels + y * _scr.pitch / 4 + x;
    *bufp = colorSDL;
  }


  auto getPlayerTreasureCardGrid(int player, int card)
  {
    import std.conv : to;
    int x,y;
    if(player == 0)
    {
      x = 0;
      y = 0;
    }
    else if(player == 1)
    {
      x = 14;
      y = 0;
    }
    else if(player == 2)
    {
      x = 0;
      y = 5;
    }
    else
    {
      x = 14;
      y = 5;
    }

    if(player == 0 || player == 2)
    {
      x += card;
    }
    else
    {
      x -= card;
    }

    return vec2(to!float(x),to!float(y));
  }
  
  void Render(){
    SDL_FillRect(_scr, null, 0x000000);
      
    SDL_UpdateTexture(_scrTex, null, _scr.pixels, _scr.pitch);
    SDL_RenderClear(_renderer);    
    SDL_RenderCopy(_renderer, _scrTex, null, null);

    // draw the background
    // SDL_RenderCopy(_renderer, )

    // draw the island tiles
    SDL_Rect src;
    src.x=0;
    src.y=0;
    src.w=409;
    src.h=585;

    SDL_Rect dest;
    dest.x=0;
    dest.y=0;
    dest.w=src.w/4;
    dest.h=src.h/4;

    int width = 409/4;
    int height = 585/4;
    int xOffset = width * 5;
    for(int y = 0; y < 6; y++)
    {
      for(int x = 0; x < 6; x++)
      {
        if(auto tile = _fi.island[y][x])
        {
          auto data = locationImageMap[tile.__tag()];
          if( tile.Status == LocationStatus.Surface)
          {
            src.x = data.FrontCol * data.itemWidth;
            src.y = data.FrontRow * data.itemHeight;
            dest.x = x * width + xOffset;
            dest.y = y * height;
            SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);
          }
          else if( tile.Status == LocationStatus.Sinking)
          {
            src.x = data.BackCol * data.itemWidth;
            src.y = data.BackRow * data.itemHeight;
            dest.x = x * width + xOffset;
            dest.y = y * height;
            SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);
          }
        }
      }
    }

    import std.conv;
    import std.string;

    string s;
  
    if( _fi.state == GameState.Lost )
    {
      ShowText("YOU LOSE!",50,420,255,200,200);
    }
    else if( _fi.state == GameState.Won)
    {
     ShowText("YOU WIN!",50,420,255,200,200); 
    }
    else
    {
      s = "Mode : " ~currentMode.toText;
      ShowText(s.toStringz,50,420,255,200,200);

      s = "Moves Left : " ~ (3 - _fi.players[_fi.currentPlayer].actionsTaken).to!string;    
      ShowText(s.toStringz,50,450,255,200,200);

      s = "Artifacts Claimed : " ~ (_fi.claimedArtifacts.length).to!string;
      ShowText(s.toStringz,50,480,255,200,200);

      s = "Water Level : " ~ (_fi.waterLevel).to!string;
      ShowText(s.toStringz,50,510,255,200,200);
    }

    // draw player graphics
    foreach(i,p;_fi.players)
    {

      // first draw the player card indicator
      auto data = roleImageMap[p.role.__tag()];
      if(i == 0)
      {
        dest.x=0; dest.y=height;      
      }
      else if(i == 1)
      {
       dest.x=14 * width; dest.y=height; 
      }
      else if(i == 2)
      {
       dest.x=0;dest.y= 4 * height; 
      }
      else if(i == 3)
      {
       dest.x= 14 * width; dest.y= 4 * height; 
      }
      src.y = data.FrontRow * data.itemHeight;
      src.x = data.FrontCol * data.itemWidth;
      SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);

      // if this is the current player, draw a red rectangle around them
      if(i==_fi.currentPlayer)
      {
        SDL_SetRenderDrawColor(_renderer,255,0,0,0);
        SDL_RenderDrawRect(_renderer,&dest);
      }

      // reset initial positions for drawing treasure card hands
      if ( i == 0)
      {
        dest.y -= height; 
      }
      else if(i == 1)
      {
        dest.y -= height;
      }
      else if ( i == 2)
      {
        dest.y += height; 
      }
      else if ( i == 3)
      {
        dest.y += height; 
      }
      
      int offset = width;
      if(i==1 || i == 3)
      {
        offset = -offset;
      }

      // draw treasure cards
      foreach(c;p.treasureHand.items)
      {
        auto treasureData = treasureImageMap[c.__tag()];

        src.y = treasureData.FrontRow * treasureData.itemHeight;
        src.x = treasureData.FrontCol * treasureData.itemWidth;
        
        SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);
        dest.x += offset;
      }

      auto playerCoords = _fi.FindLocationCoordinates(p.location);
      dest.x =(playerCoords[1] + 5) * width;
      dest.y = playerCoords[0] * height;
      dest.w = width/4;
      dest.h = height/4;

      auto colour = toColour(p.role);
      SDL_SetRenderDrawColor(_renderer,colour.r,colour.g,colour.b,0);
      SDL_RenderFillRect(_renderer, &dest);

      dest.w=src.w/4;
      dest.h=src.h/4;
    }    

    // draw the flood and treasure decks / discard 
    // treasure
    dest.y = treasure_deck_location[0] * height;
    dest.x = treasure_deck_location[1] * width;
    src.y = trasureBackImage.BackRow * trasureBackImage.itemHeight;
    src.x = trasureBackImage.BackCol * trasureBackImage.itemWidth;
    SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);

    if(_fi.treasureDeck.discard_deck.items.length > 0)
    {
      auto data = treasureImageMap[_fi.treasureDeck.discard_deck.items[$-1].__tag()];
      dest.y = treasure_deck_location[0] * height;
      dest.x = (treasure_deck_location[1]-1) * width;
      src.y = data.FrontRow * data.itemHeight;
      src.x = data.FrontCol * data.itemWidth;
      SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);
    }
    
    // flood - this is one to the left of the treasure back in the source image
    // dest.x -= width;
    dest.y = flood_deck_location[0] * height;
    dest.x = flood_deck_location[1] * width;  
    src.y = trasureBackImage.BackRow * trasureBackImage.itemHeight;
    src.x = trasureBackImage.BackCol * trasureBackImage.itemWidth - trasureBackImage.itemWidth;
    SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);

    if(_fi.lastFlood)
    {
      auto data = locationImageMap[_fi.lastFlood.__tag()];
      dest.y = flood_deck_location[0] * height;
      dest.x = (flood_deck_location[1]-1) * width;
      src.y = data.FrontRow * data.itemHeight;
      src.x = data.FrontCol * data.itemWidth;
      SDL_RenderCopy(_renderer, _fi_tex, &src, &dest);
    }

    // show available moves depending on mode
    if(pulse)
    {
      foreach(item; actionIndicators)
      {
        dest.y = item[0] * height;
        dest.x = item[1] * width;
        SDL_SetRenderDrawColor(_renderer,item[2].r,item[2].g,item[2].b,0);  
        SDL_RenderDrawRect(_renderer,&dest);
      }
    }   

    // draw current card highlight
    dest.x = (mouseX / width) * width;
    dest.y = (mouseY / height) * height;
    SDL_SetRenderDrawColor(_renderer,255,0,255,0);
    SDL_RenderDrawRect(_renderer,&dest);

    if(flipper !is null && flipper.state != Fiber.State.TERM)
    {
      flipper.call();
    }
    
    SDL_RenderPresent(_renderer);
  }


  private void updateTreasureLocationMaps()
  {
    foreach(k;locationTreasureMap.keys)
    {
      locationTreasureMap.remove(k);
    }
    int width = 409/4;
    int height = 585/4;
    
    foreach(i,p;_fi.players)
    {
      int x,y;
      if(i == 0)
      {
        x=0; y=0;
      }
      else if(i == 1)
      {
       x=14 * width; y=0; 
      }
      else if(i == 2)
      {
       x=0;y= 5 * height; 
      }
      else if(i == 3)
      {
       x= 14 * width; y= 5 * height; 
      }

      foreach(t;p.treasureHand)
      {
        int offset = width;
        bool isOdd = i==1 || i == 3;
        int gridOffset = -1;
        if(isOdd)
        {
          offset = -offset;
          gridOffset = -gridOffset;
        }

        x+=offset;

        locationTreasureMap[t] = tuple(y/height,(x/width)+gridOffset);
      }
    }
  }

  private void updateLocationActionMap()
  {
    foreach(key;locationActionMap.keys)
    {
      locationActionMap.remove(key);
    }
    
    actionIndicators = [];

    if( currentAction !is null)
    {
      // a stateful action is in progress, deal with it instead of normal processing
      // would like to have a better way to do this stuff but it will do for now
      if(auto action = currentAction.AsTrade)
      {
        assert(!(action.dest !is null && action.item !is null));
        // card will already be selected, pick the person to give it to
        foreach(currentAction; currentActions)
        {
          if(auto trade = currentAction.AsTrade)
          {
            if(trade.source == action.source && trade.item == action.item)
            {
              auto coords = getPlayerCardLocation(trade.dest);
              locationActionMap[coords] = trade;
              actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
            }
          }
        }
        currentAction = null;
      }
      else if (auto action = currentAction.AsHelicopterLiftAction)
      {
        assert(action.card !is null);
        assert(!(action.target !is null && action.destination !is null));
        if(action.target is null)
        {
          // first we choose the person to move
          foreach(currentAction; currentActions)
          {
            if(auto heli = currentAction.AsHelicopterLiftAction)
            {
              if(heli.source == action.source)
              {
                auto coords = getPlayerCardLocation(heli.target);
                locationActionMap[coords] = new HelicopterLiftAction(heli.source,heli.target,null,heli.card);
                actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
              }
            }
          }
        }
        else
        {
          // and then the place to move to
          foreach(currentAction; currentActions)
          {
            if(auto heli = currentAction.AsHelicopterLiftAction)
            {
              if(heli.source == action.source && heli.target== action.target)
              {
                auto coords = _fi.FindLocationCoordinates(heli.destination);
                coords[1] += island_x_offset;
                locationActionMap[coords] = heli;
                actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);                 
              } 
            }
          }
          currentAction = null;
        }
      }
      else if(auto action = currentAction.AsSandbagAction)
      {
        assert(action.card !is null);
        assert(action.destination is null);
        foreach(currentAction; currentActions)
        {
          // simply pick the location to shore 
          if(auto sandbag = currentAction.AsSandbagAction)
          { 
            if(sandbag.source == action.source && sandbag.card == action.card )
            {
              auto coords = _fi.FindLocationCoordinates(sandbag.destination);
              coords[1] += island_x_offset;
              locationActionMap[coords] = sandbag;
              actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);              
            }
          }
        }        
        currentAction = null;
      }
      else
      {
        assert(0);
      }

      //end here, we never show global actions in the middle of a stateful action.
      return;
    }

    void addGlobalActions()
    {
      foreach(action;currentActions)
      {
        if(auto x = action.AsDiscard)
        {
          auto coords = locationTreasureMap[x.item];
          locationActionMap[coords] = x;
          actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
        }
        else if(auto x = action.AsDrawTreasure)
        {
          locationActionMap[treasure_deck_location] = x;
          actionIndicators ~= tuple(treasure_deck_location[0],treasure_deck_location[1],RGB_Green);
        }
        else if(auto x = action.AsDrawFlood) 
        {
          locationActionMap[flood_deck_location] = x;
          actionIndicators ~= tuple(flood_deck_location[0],flood_deck_location[1],RGB_Green);
        }
        else if(auto x = action.AsWatersRiseAction)
        {
          auto coords = locationTreasureMap[x.card];
          locationActionMap[coords] = x;
          actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
        }
        else if(auto x = action.AsTileFloods)
        {
          locationActionMap[flood_deck_discard_location] = x;
          actionIndicators ~= tuple(flood_deck_discard_location[0],flood_deck_discard_location[1],RGB_Green);
        }
        else if(auto x = action.AsHelicopterLiftAction )
        {
          if(!currentMode.IsDiscard )
          {
            auto coords = locationTreasureMap[x.card];
            if( coords !in locationActionMap)
            {
              locationActionMap[coords] = new HelicopterLiftAction(x.source,null,null,x.card);
              actionIndicators ~= tuple(coords[0],coords[1],RGB_Green); 
            }
          }
        }
        else if(auto x = action.AsSandbagAction)
        {
          if(!currentMode.IsDiscard)
          {
            auto coords = locationTreasureMap[x.card];
            if( coords !in locationActionMap)
            {
              locationActionMap[coords] = new SandbagAction(x.source,null,x.card);
              actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
            }
          }
        }
      }
    }

    // add mode specific action highlights and location map entries
    currentMode.castSwitch!(
      (MoveActionMode x) => {
        foreach(action;currentActions)
        {
          if(auto move = action.AsMove)
          {
            if(x.role == move.target)
            {
              auto coords = _fi.FindLocationCoordinates(move.destination);
              coords[1] += island_x_offset;
              locationActionMap[coords] = move;
              actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);              
            }
          }          
        }
        addGlobalActions();
      }(),

      (NoneActionMode x) => {
        addGlobalActions();
      }(),

      (ShoreUpActionMode x) => {
        foreach(action;currentActions)
        {
          if(auto move = action.AsShore)
          {
            auto coords = _fi.FindLocationCoordinates(move.destination);
            coords[1] += island_x_offset;
            locationActionMap[coords] = move;
            actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
          }
        }
        addGlobalActions();
      }(),

      (ClaimActionMode x) => {
        foreach(action;currentActions)
        {
          if(auto claim = action.AsClaim)
          {
            auto coords = _fi.FindLocationCoordinates(_fi.players[_fi.currentPlayer].location);
            coords[1] += island_x_offset;
            locationActionMap[coords] = claim;
          }
        }
        addGlobalActions();
      }(),
      
      (TradeActionMode x) => {
        foreach(action;currentActions)
        {
          if(auto trade = action.AsTrade)
          {
            auto coords = locationTreasureMap[trade.item];
            locationActionMap[coords] = new Trade(trade.source,null,trade.item);
            actionIndicators ~= tuple(coords[0],coords[1],RGB_Green);
          }
        }
      }()
    );
  }

  private void ShowText(const(char)* text, int x, int y, ubyte r, ubyte g, ubyte b)
  {
    SDL_Color text_colour = SDL_Color(r,g,b);
    SDL_Surface* surface;
    scope(exit) SDL_FreeSurface(surface);    
    surface = TTF_RenderText_Solid(_font,text,text_colour);
    SDL_Texture* font_tex = SDL_CreateTextureFromSurface(_renderer,surface);
    scope(exit) SDL_DestroyTexture(font_tex);
    SDL_Rect dest;
    dest.x=x;
    dest.y=y;
    SDL_QueryTexture(font_tex, null, null, &dest.w,&dest.h);
    SDL_RenderCopy(_renderer, font_tex, null, &dest);

  }

  void Update() {
    import std.algorithm : each;
    pulseTimer = WRAPP(pulseTimer+1,30);
    if(pulseTimer == 1)
    {
      pulse = !pulse;
    }

    if(!waitingOnUser)
    {
      if(_fi.currentPlayer != playerIndex)
      {
        // default to movement mode if the player has changed
        playerIndex = _fi.currentPlayer;
        currentMode = new MoveActionMode(_fi.CurrentRole);
        currentAction = null;
      }
      currentActions = _fi.GetPlayerActions();
      updateTreasureLocationMaps();
      updateLocationActionMap();
      _fi.checkWinLoseConditions();
      waitingOnUser = true;

    }
  
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
        case SDL_KEYDOWN:
          switch(event.key.keysym.sym)
          {
            case 'm':
            {
              currentMode = new MoveActionMode(_fi.CurrentRole);
              currentAction = null;
              updateLocationActionMap();
              break;
            }            
            case 's':
            {
              currentMode = new ShoreUpActionMode();
              currentAction = null;
              updateLocationActionMap();
              break;
            }  
            case 'c':
            {
              currentMode = new ClaimActionMode();
              currentAction = null;
              updateLocationActionMap();
              break;
            }  
            case 't':
            {
              currentMode = new TradeActionMode();
              currentAction = null;
              updateLocationActionMap();
              break;
            }  
            default:
            break;
          }
          break;
        case SDL_MOUSEMOTION:
          mouseX = event.motion.x;
          mouseY = event.motion.y;
          break;
        case SDL_MOUSEBUTTONUP:
          if(event.button.button == SDL_BUTTON_LEFT)
          {
            mouseX = event.button.x;
            mouseY = event.button.y;
            MouseClick();
          }
          break;
        case SDL_QUIT:
          gameRunning=false;
        break;

        default:
        break;  
      }
    }
    //InputHandler.Update();
  };


  @property private bool waitingOnFibers()
  {
    return flipper !is null && flipper.state != Fiber.State.TERM;
  }
  void MouseClick()
  {
    if(waitingOnUser && ! waitingOnFibers )
    {
      int x, y;
      int width = 409/4;
      int height = 585/4;
      int xOffset = width * 5;
      x = (mouseX / width) ;
      y = (mouseY / height);
      // writefln("mouse click at %s %s",x,y);
      if(auto action = tuple(y,x) in locationActionMap)
      {
        // totally need some pattern matching here!

        // ok if current action is something then we are mid way through a stateful action.
        // when a stateful action is complete, this will be null, so we know this is a still-processing action.
        // this means the only options to the user would be to continuue said action, so we can just assign it
        if(currentAction !is null)
        {
          currentAction = *action;
        }           
        else if(action.IsHelicopterLiftAction || action.IsSandbagAction || action.IsTrade ) 
        {
          //otherwise if this is one of the stateful actions, we either need to begin the 
          // state cycle or process the finished action
          if(auto z = action.AsHelicopterLiftAction)
          {
            if(z.target !is null && z.destination !is null)
            {
              _fi.ProcessAction(*action);     
            }
            else
            {
              currentAction = *action;
            }
          }
          else if(auto z = action.AsSandbagAction)
          {
            if(z.destination !is null)
            {
              _fi.ProcessAction(*action);     
            }
            else
            {
              currentAction = *action;
            }
          }
          if(auto z = action.AsTrade)
          {
            if(z.dest !is null && z.item !is null)
            {
              _fi.ProcessAction(*action);     
            }
            else
            {
              currentAction = *action;
            }
          }

        }
        else
        {
          
          if(auto flood = action.AsTileFloods)
          {
            if(flood.destination.Status == LocationStatus.Surface)
            {
              Mix_PlayChannel(-1,sinking,0);
            }
            else
            {
              Mix_PlayChannel(-1,sunk,0); 
            }
            _fi.ProcessAction(*action);
          }
          else if(action.IsDrawTreasure)
          {
            Mix_PlayChannel(-1,swoosh,0);
            // work out where this card is headed
            auto player = _fi.players[_fi.currentPlayer];
            auto loc = getPlayerTreasureCardGrid(_fi.currentPlayer,player.treasureHand.items.length);
            flipper = new CardFlipFiber(
              _renderer, 
              _fi_tex,
              treasureImageMap[_fi.treasureDeck.active_deck.items[0].__tag],
              vec2(treasure_deck_location[1],treasure_deck_location[0]), 
              loc,
              () => 
              {
                _fi.ProcessAction(*action);
                waitingOnUser = false;
                if(_fi.players.map!(x=>x.treasureHand.items).joiner.any!(x=>x.IsWatersRise))
                {
                  Mix_PlayChannel(-1,alert,0); 
                }}()
                          
            );             
          }
          else
          {
            if(action.IsMove)
            {
              Mix_PlayChannel(-1,move,0);
            }
            else if(action.IsShore)
            {
             Mix_PlayChannel(-1,shoreup,0); 
            }
            _fi.ProcessAction(*action);
          }
                  
        } 
        waitingOnUser = false;
      }
      // handle Navigator and stranded special cases here
      if(auto move = currentMode.AsMoveActionMode)
      {
        int playerIndex = -1;
        if(x == 0 && y == 1)
        {
          playerIndex = 0;
        }
        if(x == 14 && y == 1)
        {
          playerIndex = 1;
        }
        else if(x == 0 && y == 4)
        {
          playerIndex = 2;
        }
        else if(x == 14 && y == 4)
        {
          playerIndex = 3;
        }
        if(    playerIndex > -1
            && _fi.players.length > playerIndex  
            && _fi.players[playerIndex].role != move.role
            )          
        {  
          move.role = _fi.players[playerIndex].role;
          updateLocationActionMap();
        }
      }
      x = (mouseX / width) * width;
    }
  }

  private auto getPlayerCardLocation(Role role)
  {
    int i = 0;
    for(i = 0; i < _fi.players.length; i++)
    {
      if(_fi.players[i].role == role)
        break;
    }

    final switch(i)
    {
      case 0: return tuple(1,0);
      case 1: return tuple(1,14);      
      case 2: return tuple(4,0);
      case 3: return tuple(4,14);      
    }

  }

  void Clean()  {
    //InputHandler.Clean();
    SDL_DestroyWindow(_window);
    SDL_DestroyRenderer(_renderer);
    SDL_Quit();
  };

  @property bool running() { return gameRunning; }
}

void main(){
  DerelictSDL2.load();
  DerelictSDL2Image.load();
  DerelictSDL2ttf.load();
  DerelictSDL2Mixer.load();
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
    if( frameTime < Game.delay_time )
    {
      SDL_Delay(cast(int)Game.delay_time-frameTime);
    }
    else 
    {
      // writeln("ouch ", frameTime - Game.delay_time, " ", frameTime); 
    }
    
  }
  game.Clean();
}
   