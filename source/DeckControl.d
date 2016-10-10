import std.stdio : writeln; alias wl = writeln;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import core.thread;
import std.range;
import du;
import control;
import deck;
import types;

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

class LayoutFiber(TState) : Fiber
{
  LayoutStyle style;
  Control!TState c;
  int index;
  this(Control!TState c, int index, LayoutStyle style)
  {
    this.style = style;
    this.index = index;
    this.c = c;
    super(&Run);
  }
  public void Run()
  {
    
    c.bounds = c.parent.bounds;
    
    int i = 0;
    if(style == LayoutStyle.OverlappingHorizontal)
      {
        while(c.bounds.x < index * 20)
          {
            c.bounds.x +=index;
            Fiber.yield();
            Fiber.yield();
          }
      }
    else
      {
        while(c.bounds.y < index * 20)
          {
            c.bounds.y +=index;
            Fiber.yield();
            Fiber.yield();
          }

      }
  }
  
}

class DeckControls(TState, T) : Control!TState
{
  import Messages;
 private:
  Deck!T deck;
  LayoutStyle style;
  Face[T] faces;
  void delegate(ref T,Face face,TState state, SDL_Renderer* renderer, SDL_Rect dest ) draw;
  Fiber[] f;
  class Card : Control!TState
  {
    this(Control!TState parent, T card)
      {
        super(parent);
        this.card = card;
      }
    T card;

    int prevIndex = 0;
    override bool OnMouseEnter(TState state, bool handled)
    {
      import std.conv;
      prevIndex = 0;
      foreach(c; parent._children)
        {
          if(c == this)
            {
              break;
            }
          prevIndex++;
        }
      parent.PromoteZOrder(this);
      static if(is(T == PlayerCard))
        {
          if(auto x = card.AsCityCard)
            {
              state.router.PostMessage(new Status(x.city.to!string));
            }      
          else if(auto x = card.AsEpidemicCard)
            {
              state.router.PostMessage(new Status("Epidemic!"));
            }
        }
      else static if(is(T == InfectionCard))
        {
          if(auto x = card.AsCityInfectionCard)
            {
              state.router.PostMessage(new Status(x.city.to!string));
            }      
          else if(auto x = card.AsMutationCard)
            {
              state.router.PostMessage(new Status("Mutation!"));
            }
        }

      return true;

    }
    
    override bool OnMouseClick(TState state, bool handled, MouseButtonType button, int x, int y)
    {
      if(button == MouseButtonType.Left)
        {
          state.router.PostMessage(new Test());
          import std.conv : to;
          state.router.PostMessage(new Status("removing card " ~ to!string(card)));
          wl("card count : ", deck.length);
          ChangeStyle(LayoutStyle.Stack);
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

    override bool HandleInput(TState state, InputMessage msg, SDL_Rect relativeBounds, bool handled){ return true; }
    override bool OnMouseLeave(TState state, bool handled)
    {
      parent.SetZOrder(this,prevIndex);
      return true;
    }
    override void Render(TState state, SDL_Renderer* renderer, SDL_Rect relativeBounds)
    {
      draw(card,faces[card], state, renderer, relativeBounds);
    }

  }

  public void FixCards()
  {
    bool[T] found;
    foreach(c;deck)
      {
        if(c !in faces)
          {
            faces[c] = Face.Back;
          }
        found[c] = true;
      }

    T[] toRemove;
    foreach(kvp; faces.byKeyValue)
      {
        if(kvp.key !in found)
          {
            toRemove ~= kvp.key;
          }
      }
    foreach(c;toRemove)
      {
        faces.remove(c);
      }
  }
  public override void Update(TState state)
  {
    if(_children.length == 0 && deck.length > 0)
      {
        FixCards();
        ChangeStyle(LayoutStyle.Stack);
      }
          
         
    foreach(ff;f)
      if(ff !is null && ff.state != Fiber.State.TERM)
        {
          ff.call();
        }

    
  }
  void ChangeStyle(LayoutStyle newStyle)
  {
    this.style = newStyle;
    mouseControl = null;
    _children.length = 0;
    f.length = 0;
    if(deck.length == 0) return;
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
            b.x += 50;
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
        f ~= new LayoutFiber!TState(c,i,style);
        i++;
      }

  }
  
 public:

  this(
       Control!TState parent,
       Deck!T deck,
       SDL_Rect initialCardSize,
       void delegate(ref T,Face face, TState state, SDL_Renderer* renderer, SDL_Rect dest ) draw)
    {
      super(parent);
      this.deck = deck;
      foreach(card; this.deck)
        faces[card] = Face.Front;
      bounds = initialCardSize;
      this.draw = draw;
      ChangeStyle(LayoutStyle.Stack);
      //ChangeStyle(LayoutStyle.OverlappingVertical);
      //    ChangeStyle(LayoutStyle.OverlappingHorizontal);
    }

  void EnsureFaces(Face face)
  {
    foreach(card; this.deck)
      faces[card] = face;

  }

}
unittest
{
  SDL_Rect r;
  //  auto d = Deck!int();
  // auto c = new DeckControls!int(null,d,r,(ref x,y,z) => {}()); 

}
