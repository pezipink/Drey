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

// lexer is implemented as a D ForwardOnly range
// (empty, front, popFront)
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

    if(ch.isWhite)
      {
        // consume all subsequent whitespace
        while(!s.empty && ch.isWhite)
          {
            s.popFront();
          }
        current = Token(Tok.WS,"");
      }
    else if(ch.isAlphaNum || ch == '_')
      {
        // extract identifier
        string ident;
        while(!s.empty && (ch.isAlphaNum || ch == '_'))
          {
            ident ~= ch;
            s.popFront();
          }
        // return keyword or identifier
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
        switch(ch)
          {
          case '|' :
            current = Token(Tok.PIPE,to!string(ch));
            s.popFront();
            break;
          case ',' :
            current = Token(Tok.COMMA,to!string(ch));
            s.popFront();
            break;
          case '.' :
            current = Token(Tok.DOT,to!string(ch));
            s.popFront();
            break;
          case '@' :
            current = Token(Tok.AT,to!string(ch));
            s.popFront();
            break;
          case '=' :
            current = Token(Tok.EQUALS,to!string(ch));
            s.popFront();
            break;
          case '(': 
          case '[':
          case '{':
            current = Token(Tok.LBRACKET,to!string(ch));
            s.popFront();
            break;
          case ')':
          case ']':
          case '}':
            current = Token(Tok.RBRACKET,to!string(ch));
            s.popFront();
            break;
          case '*' :
            current = Token(Tok.STAR,to!string(ch));
            s.popFront();
            break;
          case ':':
            current = Token(Tok.COLON,to!string(ch));
            s.popFront();
            break;
          case '#' :
            current = Token(Tok.HASH,to!string(ch));
            s.popFront();
            break;
          case '"' :
            // consume until end of string
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
            if(ch == '/')
              {
                // single line comments, consume until \n
                string comment;
                s.popFront();
                while(!s.empty && ch != '\n')
                  {
                    comment ~= ch;
                    s.popFront();
                  }

                if(!s.empty)
                  {
                    s.popFront();
                  }
                current = Token(Tok.COMMENT,comment);
              }
            else if( ch == '*')
              {
                auto cp = ch;
                string comment;
                while(true)
                  {
                    // multi line comments, consume until */
                    s.popFront();
                    if(s.empty())
                      {
                        current = Token(Tok.ERROR,comment);
                        break;
                      }
                    if(cp == '*' && ch == '/')
                      {
                        current = Token(Tok.COMMENT, comment);
                        s.popFront();
                        break;
                      }
                    comment ~= cp;
                    cp = ch;
                
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
        // if ignoreCruft is true the lexer skips yielding comments and whitespace in the range 
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
