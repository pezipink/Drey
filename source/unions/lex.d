module lex;
enum Tok
  {
    WS,
    IDENT,
    OF,
    UNION,
    PIPE,
    STAR,
    COLON,
    HASH,
    DOT,
    STRING,
    COMMENT,
    ERROR,
    EQUALS,
    LBRACKET,
    RBRACKET,
    AT,
    COMMA,
    EOF
  }

struct Token
{
  Tok token;
  string data;
  alias token this;
  @property string AsString()
  {
    import std.string : format;
    return format("{%s, %s}", token, data);
  }
}

struct Scanner
{
  import std.ascii : isWhite, isAlpha, isAlphaNum;
  import std.string;
  import std.array;

  private
  {
    bool finished = false;
    string s;
    Token current;
    bool ignoreCruft;
  }
  
  this(string toScan, bool ignoreCruft)
  {
    s = toScan;
    this.ignoreCruft = ignoreCruft;
    popFront();
  }

  @property bool empty() const { return finished; }
  @property ref Token front()
  {
    if(finished)
      {
        throw new Exception("there are no tokens left");
      }
    else
      {
        return current;
      } 
  }

  @property dchar ch()
  {
    return s.front;
  }
  
  void popFront()
  {

    import std.conv : to;
    import std.stdio : writeln;
    alias wl = writeln;
    if(current.token == Tok.EOF)
      {
        finished = true;
        return;
      }
    if(s.empty)
      {
        current = Token(Tok.EOF,"");
        return;
      }
    auto c = s.front;
    if(c.isWhite)
      {
        while(c.isWhite && !s.empty)
          {
            s.popFront();
            if(!s.empty)
              {
                c = s.front;
              }
          }
        current = Token(Tok.WS,"");
      }
    else if(c.isAlphaNum || c == '_')
      {
        string ident;
        while((c.isAlphaNum || c == '_') && !s.empty)
          {
            ident ~= c;
            s.popFront();
            if(!s.empty)
              {
                c = s.front;
              }
            
          }
        switch(ident.toUpper)
          {
          case "OF" :
            current = Token(Tok.OF,ident);
            break;
          case "UNION" :
            current = Token(Tok.UNION,ident);
            break;
          default:
            current = Token(Tok.IDENT,ident);
            break;
          }
        
      }
    else
      {
        switch(c)
          {
          case '|' :
            current = Token(Tok.PIPE,to!string(c));
            s.popFront();
            break;
          case ',' :
            current = Token(Tok.COMMA,to!string(c));
            s.popFront();
            break;
          case '.' :
            current = Token(Tok.DOT,to!string(c));
            s.popFront();
            break;
          case '@' :
            current = Token(Tok.AT,to!string(c));
            s.popFront();
            break;
          case '=' :
            current = Token(Tok.EQUALS,to!string(c));
            s.popFront();
            break;
          case '(': 
          case '[':
          case '{':
            current = Token(Tok.LBRACKET,to!string(c));
            s.popFront();
            break;
          case ')':
          case ']':
          case '}':
            current = Token(Tok.RBRACKET,to!string(c));
            s.popFront();
            break;
          case '*' :
            current = Token(Tok.STAR,to!string(c));
            s.popFront();
            break;
          case ':':
            current = Token(Tok.COLON,to!string(c));
            s.popFront();
            break;
          case '#' :
            current = Token(Tok.HASH,to!string(c));
            s.popFront();
            break;
          case '"' :
            string str = "\"";
            s.popFront();
            while(!s.empty && ch != '"')
              {
                str ~= ch;
                s.popFront();
              }
            str ~= "\"";
            s.popFront();
            current = Token(Tok.STRING,str);
            break;
          case '/' :
            s.popFront();
            c = s.front;
            if(c == '/')
              {
                string comment;
                s.popFront();
                c = s.front;
                while(c != '\n' && !s.empty)
                  {
                    comment ~= c;
                    s.popFront();
                    if(!s.empty)
                      {
                        c = s.front;
                      }
                  }

                if(!s.empty)
                  {
                    s.popFront();
                  }
                current = Token(Tok.COMMENT,comment);
              }
            else if( c == '*')
              {
                auto cp = c;
                string comment;
                while(true)
                  {
                    s.popFront();
                    if(s.empty())
                      {
                        current = Token(Tok.ERROR,comment);
                        break;
                      }
                    c = s.front;
                    if(cp == '*' && c == '/')
                      {
                        current = Token(Tok.COMMENT, comment);
                        s.popFront();
                        break;
                      }
                    comment ~= cp;
                    cp = c;
                
                  }
              }
            else
              {
                current = Token(Tok.ERROR,"invalid comment");
              }
            break;
        
          default:
            current = Token(Tok.ERROR,"");
            break;
          }
      }
    if(ignoreCruft && ( current.token == Tok.WS || current.token == Tok.COMMENT || current.token == Tok.EOF))
      {
        popFront();
      }
  } 
}

unittest
{
  import std.array;
  import std.algorithm;
  import std.stdio : writeln;
  bool cs(string s, Tok[]t ) { auto r = Scanner(s,false).map!(x=>x.token).array; /*writeln(r);*/ return r == t; } 
  bool csi(string s, Tok[]t )
  {
    auto s2 = Scanner(s,true);
    s2.ignoreCruft = true;
    auto r = s2.map!(x=>x.token).array;
    //writeln(r);
    return r == t;
  } 

  assert(cs("    ",[Tok.WS, Tok.EOF]));
  assert(cs(" \n \t   ",[Tok.WS, Tok.EOF]));
  assert(cs(" \n \t hello ",[Tok.WS,Tok.IDENT,Tok.WS, Tok.EOF]));

  assert(cs("Role = \n |",[Tok.IDENT,Tok.WS,Tok.EQUALS,Tok.WS,Tok.PIPE,Tok.EOF]));

  assert(cs("hello // this is a comment \n hello /* this is also a comment */ ( )",
            [Tok.IDENT,Tok.WS,Tok.COMMENT,Tok.WS,Tok.IDENT,Tok.WS,Tok.COMMENT,Tok.WS,Tok.LBRACKET,Tok.WS,Tok.RBRACKET,Tok.EOF]));

  assert(csi("hello // this is a comment \n hello /* this is also a comment */ ( )",
            [Tok.IDENT,Tok.IDENT,Tok.LBRACKET,Tok.RBRACKET,Tok.EOF]));

  // todo: string and comment tests
  
}
