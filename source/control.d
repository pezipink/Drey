
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

class Control
{
  import std.container : DList;

protected:

  this(Control parent)
  {
    this.parent = parent;
  }
  
  bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled) { return handled; }
  void Update(){ return; };
  void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds) { return; }
  bool OnMouseEnter(bool handled) { return handled; }
  bool OnMouseLeave(bool handled) { return handled; }
  bool OnMouseClick(bool handled, MouseButtonType button,int x, int y) { return handled; }
  
public:
  // the order of this list is the z-order
  // todo: probably change this to just an array for simplcity since
  // perf doesn't really matter
  DList!Control _children; 

  Control parent;

  SDL_Rect bounds;
  void AddControl(Control child)
  {
    _children.insertBack(child);
  }

  void PromoteZOrder (Control child)
  {
    import std.range;
    import std.algorithm : find;
    auto found = _children[].find!(x=>x==child);
    assert(!found.empty);
    _children.linearRemove(found.take(1));
    _children.insertBack(found.take(1));
  }
  void DemoteZOrder (Control child)
  {
    import std.range;
    import std.algorithm : find;
    auto found = _children[].find!(x=>x==child);
    assert(!found.empty);
    _children.linearRemove(found.take(1));
    _children.insertFront(found.take(1));
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

  Control mouseControl;
  @property Control parentMouseControl()
  {
    if(parent is null) return null;
    return parent.mouseControl;
  }
  void RefreshMouseControl(int x, int y)
  {
    parent.CoreHandleInput
      (new MouseMove(x,y),parent.bounds,false);
    
  }

  bool CoreHandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled)
  {
    import std.stdio : writeln; alias wl = writeln;
    auto r = relativeBounds;

    // always allow our children to attempt to handle something
    // this must be done from the top z-order level downwards.
    foreach_reverse(c;_children)
      {
        if(c is null) return true; // this can occur since we might modify this collection
        handled = c.CoreHandleInput(msg, PerformOffset(c.bounds,r.x, r.y),handled);
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
                        OnMouseEnter(handled);
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
                        OnMouseLeave(handled);
                      }
                  }
              }
            else if(auto x = msg.AsMouseButton)
              {
                OnMouseClick(handled,x.button,x.x,x.y);
              }
          }
     
      }
    else if(auto x = msg.AsKeyPress)

      {

      }

    

    return HandleInput(msg, r, handled);
  }

  void CoreUpdate()
  {
    Update();
    foreach(c;_children) c.CoreUpdate();
  }

  void CoreRender(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    // render yourself first then your children in ascending z-order
    
    Render(renderer,relativeBounds);
    foreach(c;_children) c.CoreRender(renderer,PerformOffset(c.bounds,relativeBounds.x, relativeBounds.y));
  }

  unittest
  {
    // assert(false);		
  }
}

