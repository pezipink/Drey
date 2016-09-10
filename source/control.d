import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.stdio;
import std.path;
import std.string;

class Control
{
  import std.container : DList;
protected:
  // the order of this list is the z-order
  DList!Control _children;
	
  void PromoteZOrder (Control child)
  {
    import std.range;
    import std.algorithm : find;
    auto found = _children[].find!(x=>x==child);
    assert(!found.empty);
    _children.linearRemove(found.take(1));
    _children.insertBack(found.take(1));
  }

  abstract bool HandleInput(bool thing);
  abstract void Update();
  abstract void Render(SDL_Renderer* renderer, int xOffset, int yOffset);
  
public:
  bool CoreHandleInput(bool thing)
  {
    // always allow our children to attempt to handle something and block us
    // this must be done from the top z-order level downwards.
    foreach_reverse(c;_children)
      {
	if(c.CoreHandleInput(thing))
	  {
	    // stop processing here
	    return true;
	  }
      }

    return HandleInput(thing);
  }

  void CoreUpdate()
  {
    Update();
    foreach(c;_children) c.CoreUpdate();
  }

  void CoreRender(SDL_Renderer* renderer, int xOffset, int yOffset)
  {
    // render yourself first then your children in ascending z-order
    Render(renderer,xOffset,yOffset);
    foreach(c;_children) c.CoreRender(renderer,xOffset,yOffset);
  }

  unittest
  {
    // assert(false);		
  }
}

