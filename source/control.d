import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.stdio;
import std.path;
import std.string;
import du;

enum MouseButtonType
  {
    Left,
    Right,
    Middle
  }

enum KeyType
  {
    Up,
    Down
  }

mixin(DU!q{
    Union InputMessage =
      | MouseMove of x : int * y : int 
      | MouseButton of button : MouseButtonType * x : int * y : int
      | KeyPress of key : SDL_Keycode * action : KeyType
  });

bool InBounds(SDL_Rect* rect, int x, int y)
{
  return(x > rect.x && x < rect.x + rect.w
         && y > rect.y && y < rect.y + rect.h);
}

class Control(TState)
{
  import std.container : DList;

protected:
  bool autoRenderChildren = true;
  this(Control parent)
  {
    this.parent = parent;
  }
  
  bool HandleInput(TState state, InputMessage msg, SDL_Rect relativeBounds, bool handled) { return handled; }
  void Update(TState state, ){ return; };
  void Render(TState state, SDL_Renderer* renderer, SDL_Rect relativeBounds) { return; }
  bool OnMouseEnter(TState state, bool handled) { return handled; }
  bool OnMouseLeave(TState state, bool handled) { return handled; }
  bool OnMouseClick(TState state, bool handled, MouseButtonType button,int x, int y) { return handled; }
  // void OnRecieveMessage(T message) { return; }
  
public:
  // the order of this list is the z-order
  // todo: probably change this to just an array for simplcity since
  // perf doesn't really matter
  Control[] _children; 

  Control parent;
  // this is the control the mouse is currently on
  Control mouseControl;
  SDL_Rect bounds;

  void CoreInitialize(TState state)
  {
    Initialize(state);
    foreach(c;_children)c.CoreInitialize(state);
  }
  
  void Initialize(TState state)
  {
    return;
  }
  
  void AddControl(Control child)
  {
    _children ~= child;
  }

  void PromoteZOrder (Control child)
  {
    import std.range;
    import std.algorithm : find;
    if(_children.length == 2)
      {
        _children = [_children[1],_children[0]];
          return;
      }
    int index = 0;
    for(index = 0; index < _children.length; index++)
      {
        if(_children[index] == child)
          break;
      }
    if(index == _children.length-1) return;
    
    _children = _children[0..index] ~  _children[index+1..$] ~ _children[index];
  }
  void DemoteZOrder (Control child)
  {
    import std.range;
    if(_children.length == 2)
      {
        _children = [_children[1],_children[0]];
        return;
      }

    int index = 0;
    for(index = 0; index < _children.length; index++)
      {
        if(_children[index] == child)
          break;
      }
    if(index == 0) return;
    _children = [_children[index]] ~ _children[0..index] ~ _children[index+1..$];
  }

  void SetZOrder(Control child, int position)
  {
    import std.range;
    int index = 0;
    if(position == 0)
      {
        DemoteZOrder(child);
      }
    else if(position == _children.length-1)
      {
        PromoteZOrder(child);
      }
    else
      {
        for(index = 0; index < _children.length; index++)
          {
            if(_children[index] == child)
              break;
          }
        if(index == 0) return;
        if(index == position) return;
        
        if(index < position)
          {
            _children = _children[0..index] ~ _children[index+1..position] ~ _children[index] ~ _children[position..$];
          }
        else
          {
            _children = _children[0..position] ~ _children[index] ~ _children[position.. index] ~ _children[index+1..$];

          }

      }
    
  }
  
  SDL_Rect PerformOffset(SDL_Rect original,int xOffset, int yOffset)
  {
    SDL_Rect r;
    r.x = original.x + xOffset;
    r.y = original.y + yOffset;
    r.w = original.w;
    r.h = original.h;
    return r;
  }


  @property Control parentMouseControl()
  {
    if(parent is null) return null;
    return parent.mouseControl;
  }
  void RefreshMouseControl(TState state,int x, int y)
  {
    parent.CoreHandleInput
      (state, new MouseMove(x,y),parent.bounds,false);
    
  }

  bool CoreHandleInput(TState state,InputMessage msg, SDL_Rect relativeBounds, bool handled)
  {
    import std.stdio : writeln; alias wl = writeln;
    auto r = relativeBounds;

    // always allow our children to attempt to handle something
    // this must be done from the top z-order level downwards.
    foreach_reverse(c;_children)
      {
        if(c is null) return true; // this can occur since we might modify this collection
        handled = c.CoreHandleInput(state,msg, PerformOffset(c.bounds,r.x, r.y),handled);
      }

    if(msg.IsMouseMove || msg.IsMouseButton)
      {
        if( parentMouseControl is null)
          {
            if(auto x = msg.AsMouseMove)
              {
                if(InBounds(&r,x.x,x.y))
                  {
                    if(parent !is null)
                      {
                        parent.mouseControl = this;
                        OnMouseEnter(state,handled);
                      }
                  }
              }
          }
        else if(parentMouseControl == this)
          {
            if(auto x = msg.AsMouseMove)
              {
                if(!InBounds(&r,x.x,x.y))
                  {
                    if(parent !is null)
                      {
                        parent.mouseControl = null;
                        OnMouseLeave(state,handled);
                      }
                  }
              }
            else if(auto x = msg.AsMouseButton)
              {
                OnMouseClick(state,handled,x.button,x.x,x.y);
              }
          }
     
      }
    else if(auto x = msg.AsKeyPress)

      {

      }

    

    return HandleInput(state, msg, r, handled);
  }

  void CoreUpdate(TState state)
  {
    Update(state);
    foreach(c;_children) c.CoreUpdate(state);
  }

  void CoreRender(TState state,SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    // render yourself first then your children in ascending z-order
    
    Render(state,renderer,relativeBounds);
    if(autoRenderChildren)
      {
        foreach(c;_children) c.CoreRender(state,renderer,PerformOffset(c.bounds,relativeBounds.x, relativeBounds.y));
      }
  }

  unittest
  {
    // assert(false);		
  }
}

