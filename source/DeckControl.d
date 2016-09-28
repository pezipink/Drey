import std.stdio : writeln; alias wl = writeln;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import core.thread;
import std.range;
import du;
import control;
import deck;
enum LayoutStyle
  {
    Stack,
    OverlappingHorizontal,
    OverlappingVertical
  }

enum Face
  {
    Front,
    Back
  }

class LayoutFiber : Fiber
{
  LayoutStyle style;
  Control c;
  int index;
  this(Control c, int index)
  {
    //this.style = style;
    this.index = index;
    this.c = c;
    super(&Run);
  }
  public void Run()
  {
    //    foreach(ref c;p._children)
    {
      c.bounds = c.parent.bounds;
    }
    int i = 0;
    //foreach(c;p._children)
    {
      //  p.PromoteZOrder(c);
      while(c.bounds.x < index * 20)
        {
          c.bounds.x +=index;
          Fiber.yield();
          Fiber.yield();
        }
      //i++;
      //        Fiber.yield();
    }
  }
}

class DeckControls(T) : Control
{
private:
  Deck!T deck;
  LayoutStyle style;
  Face[T] faces;
  void delegate(ref T,Face face, SDL_Renderer* renderer, SDL_Rect dest ) draw;
  Fiber[] f;
  class Card : Control
  {
    this(Control parent, T card)
    {
      super(parent);
      this.card = card;
    }
    T card;

    override bool OnMouseEnter(bool handled)
    {
      parent.PromoteZOrder(this);
      return true;

    }
    
    override bool OnMouseClick(bool handled, MouseButtonType button, int x, int y)
    {
      if(button == MouseButtonType.Left)
        {
          parent.DemoteZOrder(this);
          parent.mouseControl = null;
          RefreshMouseControl(x,y);
        }
      else
        {
          
          if(faces[card] == Face.Front)
            {
              faces[card] = Face.Back;
            }
          else
            {
              faces[card] = Face.Front;
            }
          
        }
      return true;
    }

  override bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled){ return true; }
    override bool OnMouseLeave(bool handled) { return true; }
    override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
    {
      draw(card,faces[card], renderer, relativeBounds);
    }
  }

  public override void Update()
  {
    foreach(ff;f)
   if(ff !is null && ff.state != Fiber.State.TERM)
    {
      ff.call();
    }
 
  }
  void ChangeStyle(LayoutStyle newStyle)
  {
    this.style = newStyle;
    _children.clear();
    final switch(this.style)
      {
      case LayoutStyle.Stack:
        AddControl(new Card(this,deck[0]));
        break;
      case LayoutStyle.OverlappingHorizontal:
        SDL_Rect b = bounds;
        
        foreach(ref c;deck)
          {
            auto card = new Card(this,c);
            card.bounds = b;
            AddControl(card);
            b.x += 20;
            b.y += 5;
          }
        break;
      case LayoutStyle.OverlappingVertical:
        SDL_Rect b = bounds;
        
        foreach(ref c;deck)
          {
            auto card = new Card(this,c);
            card.bounds = b;
            AddControl(card);
            b.y += 20;
          }
        break;
      }
    import std.array;
    import std.algorithm;
    int i = 0;
    foreach(c;_children)
      {
        f ~= new LayoutFiber(c,i);
        i++;
      }

  }
  
public:

  this(
       Control parent,
       Deck!T deck,
       SDL_Rect initialCardSize,
       void delegate(ref T,Face face, SDL_Renderer* renderer, SDL_Rect dest ) draw)
  {
    super(parent);
    this.deck = deck;
    foreach(card; this.deck)
      faces[card] = Face.Front;
    bounds = initialCardSize;
    this.draw = draw;
    ChangeStyle(LayoutStyle.OverlappingVertical);
    ChangeStyle(LayoutStyle.OverlappingHorizontal);
  }

  

protected:
  

  override bool HandleInput(InputMessage msg, SDL_Rect relativeBounds, bool handled)
  {
    return false;
  }


  override void Render(SDL_Renderer* renderer, SDL_Rect relativeBounds)
  {
    // final switch(style )
      // {
      // case LayoutStyle.Stack:
      //   // just render a single card at the current size
      //   draw(deck[0],renderer,relativeBounds);
      //   break;
      // case LayoutStyle.OverlappingHorizontal:
      //   foreach(ref c;deck)
      //     {
      //       draw(c,renderer,relativeBounds);
      //       relativeBounds.x += 10;
      //     }
      //   break;
      // case LayoutStyle.OverlappingVertical:
      //   foreach(ref c;deck)
      //     {
      //       draw(c,renderer,relativeBounds);
      //       relativeBounds.y += 20;
      //     }

      //   break;
      // }
    return;
  }
}
unittest
{
  SDL_Rect r;
  auto d = Deck!int();
  // auto c = new DeckControls!int(null,d,r,(ref x,y,z) => {}()); 

}
