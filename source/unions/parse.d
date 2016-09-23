module parse;
import lex;
import std.typecons;
import std.stdio : writeln;
alias wl = writeln;

struct Parameter
{
        string name;
        string type;
        string defaultValue;
}

struct AttributeData
{
        string name;
        string args;
}

struct UnionCaseData
{
        string name;
        AttributeData[] attributes;
        Parameter[] parameters;
}

struct UnionData
{
        string name;
        AttributeData[] attributes;
        UnionCaseData[] caseData;
        string[] functions;
        Parameter[] baseParameters;
}


struct Parser
{
  import std.stdio:writeln;
  alias wl = writeln;
  Scanner s;

  this(string unions)
  {
    
    s = Scanner(unions,true);
  }

  @property ref Tok tok()
  {
    return s.front.token;
  }

  @property ref string data()
  {
    return s.front.data;
  }

  Parameter ParseParameter()
  {
    Parameter res;
    // name : type
    // name : type # default
    assert(tok == Tok.IDENT);
    res.name = data;
    s.popFront();
    assert(tok == Tok.COLON,"a union parameter must be followed by : and a type, not " ~ s.front.AsString);
    s.popFront();
    assert(tok == Tok.IDENT,"a union parameter must be followed by : and a type");
    res.type = data;
    s.popFront();
    while(!s.empty && tok == Tok.LBRACKET || tok == Tok.RBRACKET
          || tok == Tok.DOT || tok == Tok.IDENT)
     {
        res.type ~= data;
        s.popFront();
      }
    
    if(tok == Tok.HASH)
      {
        s.popFront();
        assert(tok == Tok.IDENT || tok == Tok.STRING,"default values for parameters follow the form \"# value\"");
        res.defaultValue = data;
        s.popFront();
        while(!s.empty && tok == Tok.LBRACKET || tok == Tok.RBRACKET
              || tok == Tok.DOT || tok == Tok.IDENT)
          {
            res.defaultValue ~= data;
            s.popFront();
          }

      }
    return res;
  }

  Parameter[] ParseParameters()
  {
    // param
    // param * param * param ...
    Parameter[] res;    
    assert(tok == Tok.IDENT,"parameter expected to start with an identifier");
    while(!s.empty && tok == Tok.IDENT)
      {
        res ~= ParseParameter();

        if(!s.empty && tok == Tok.STAR)
          {
            s.popFront();
          }
        else
          {
            break;
          }
      }

    return res;
    
  }

  AttributeData ParseAttribute()
  {
    AttributeData res;
    // take any amount of identifiers and other things, putting spaces between them,
    // stopping when brackets are balances and we hit a comma or ident
    int bc = 0;

    while(!s.empty)
      {
        if(tok == Tok.LBRACKET) bc++;


        if(bc < 1)
          {
            if(res.name == "" || tok == Tok.DOT || res.name[$-1] == '.')
              {
                res.name ~= data;
              }
            else
              {
                res.name ~= " " ~ data;
              }
            
          }
        else
          {
            if(res.args == "" || tok == Tok.DOT || res.args[$-1] == '.')
              {
                res.args ~= data;
              }
            else
              {
                res.args ~= " " ~ data;
              }
            
          }

        if(tok == Tok.RBRACKET) bc--;
        s.popFront();
        if(bc == 0 && (tok == Tok.RBRACKET || tok == Tok.COMMA))
          {
            break;
          }
      }
    
    return res;
  }

  AttributeData[] ParseAttributes()
  {
    AttributeData[] res;
     //@(x(123,456))
    //@(x(4),y,z)

    assert(tok == Tok.LBRACKET, "attributes must be surrounded with parens");
      
    s.popFront();

    while(!s.empty && tok != Tok.RBRACKET)
      {
        res ~= ParseAttribute();
        if(tok == Tok.COMMA)
          {
            s.popFront();
          }
      }
  
    
    return res;
  }

  UnionCaseData ParseUnionCase()
  {
    // Name
    // Name(T,U)
    // @((x,y,z)) Name(T,U)
    // Name of (param list)
    UnionCaseData res;

    if(tok == Tok.AT)
      {
        while(!s.empty && tok == Tok.AT)
          {
            s.popFront();
            res.attributes ~= ParseAttributes();
            s.popFront();
          }
      }

    assert(tok == Tok.IDENT, "Expected identifier for union case, not " ~ s.front.AsString);

    res.name = data;

    s.popFront();
    // handle template parameters
    if(tok == Tok.LBRACKET)
      {
        int bc = 1;
        res.name ~= data;
        s.popFront();
        while(bc > 0 && !s.empty)
          {
            switch(tok)
              {
              case Tok.LBRACKET:
                bc++;
                break;
              case Tok.RBRACKET:
                bc--;
                break;
              default:
                break;
              }
            res.name ~= s.front.data;
            s.popFront();
          }
      }

    // handle union parameters
    if(tok == Tok.OF)
      {
        s.popFront();
        res.parameters = ParseParameters();
      }
    return res;
  }


  UnionData ParseUnion()
  {
    UnionData res;
    
    // unions might start with some attributes
    if(tok == Tok.AT)
      {
        while(!s.empty && tok == Tok.AT)
          {
            s.popFront();
            res.attributes ~= ParseAttributes();
            s.popFront();
          }
      }


    assert(tok == Tok.IDENT, s.front.AsString);

    // otherwise we are looking for an identfier, possibly with
    // template parameters, and an =
    res.name = s.front.data;
    s.popFront();
    
    if(tok == Tok.LBRACKET)
      {
        // we don't really care what these are since they will just be
        // added to the name verbatim, just check parens are balanced.
        int bc = 1;
        res.name ~= s.front.data;
        s.popFront();
        while(bc > 0 && !s.empty)
          {
            switch(tok)
              {
              case Tok.LBRACKET:
                bc++;
                break;
              case Tok.RBRACKET:
                bc--;
                break;
              default:
                break;
              }
            res.name ~= data;
            s.popFront();
          }
      }

    if(tok == Tok.OF)
      {
        s.popFront();
        res.baseParameters ~= ParseParameters();
      }

    
    assert(tok == Tok.EQUALS,"Exptected = after union name and template params, not " ~ s.front.AsString);

    s.popFront();

    // parse all union cases
    while(tok == Tok.PIPE)
      {
        s.popFront();
        res.caseData ~= ParseUnionCase();
      }
      
    
    return res;
  }

  UnionData[] ParseUnions()
  {
    import std.stdio : writeln;
    alias wl = writeln;
      
    UnionData[] res;
    while(!s.empty)
      {
        // the start of a union must be the keyword Union.      
        switch(tok)
          {
          case Tok.UNION:
            s.popFront();
            res ~= ParseUnion();
            break;
          case Tok.EOF:
            return res;
          default:
            throw new Exception(data ~ ": Invalid input. Expected Union (attributes) Name = (cases),  not" ~ s.front.AsString);
          }

      }
    
    assert(0);
  }
  
}
unittest
{
  import std.stdio : writeln;
  auto res = Parser(q{Union Role =
| Medic
| Scientist
| Researcher
| Dispatcher
| OperationsExpert of usedSpecial : bool

 // ... etc
    }).ParseUnions();

  writeln(res);

}

unittest
{
  import std.stdio : writeln; alias wl = writeln;
  auto p = Parser("  \t( Test(3 ),   \nnew Test2 (3,  \"5\"))");
  auto ret = p.ParseAttributes();
  auto att = ret;
  wl("!!!",att);
  assert(att.length == 2);
  assert(att[0].name == "Test");
  assert(att[0].args == "( 3 )");
  assert(att[1].name == "new Test2");
  assert(att[1].args == "( 3 , \"5\" )");
}

unittest
{
   import std.stdio : writeln; alias wl = writeln;
  auto ret = Parser("(5,\t\n 6\t,Juan.10)").ParseAttributes();
  assert(ret.length==3);
  wl(ret);
  assert(ret[0].name == "5");
  assert(ret[1].name == "6");
  assert(ret[2].name == "Juan.10");
}
        
unittest
{
  auto res = Parser("Email").ParseUnionCase();
  assert(res.name == "Email");
  assert(res.parameters.length == 0);
}

unittest
{
  auto res = Parser("Email of x : string[]").ParseUnionCase();
  assert(res.name == "Email");
  assert(res.parameters.length == 1);
  assert(res.parameters[0].name == "x");
  assert(res.parameters[0].type == "string[]");
}

unittest
{ 
  auto res = Parser("Base = ").ParseUnionCase;

  assert(res.name == "Base");
  assert(res.parameters.length == 0);   
}

unittest
{
  auto res = Parser("Base of x : int = ").ParseUnionCase();
  assert(res.name == "Base");
  assert(res.parameters.length == 1);
  assert(res.parameters[0].name == "x");
  assert(res.parameters[0].type == "int");
}


unittest
{
  auto res = Parser("Base of x : int # Constants.Juan = ").ParseUnionCase();
  wl(res);
  assert(res.name == "Base");
  assert(res.parameters.length == 1);
  assert(res.parameters[0].name == "x");
  assert(res.parameters[0].type == "int");
  assert(res.parameters[0].defaultValue == "Constants.Juan");
}

unittest
{
  auto res = Parser("Base of \nx : \tint # Constants.Juan \t* y :string= ").ParseUnionCase();
  assert(res.name == "Base");
  assert(res.parameters.length == 2);
  assert(res.parameters[0].name == "x");
  assert(res.parameters[0].type == "int");
  assert(res.parameters[0].defaultValue == "Constants.Juan");
  assert(res.parameters[1].name == "y");
  assert(res.parameters[1].type == "string");

}

unittest
{
  auto res = Parser(q{
      UNion
      Vehicle =
      | Plane

      Union
      @(new John())
      Test = | Test2
    }).ParseUnions();

  assert(res[0].name == "Vehicle");
  assert(res[0].caseData.length == 1);
  assert(res[0].caseData[0].name == "Plane");
  assert(res.length == 2);
 
}

unittest
{
  auto res = Parser(q{
      Union
      Vehicle =
      | Plane
      |Car
    }).ParseUnions();
  assert(res[0].name == "Vehicle");
  assert(res[0].caseData.length == 2);
  assert(res[0].caseData[0].name == "Plane");
  assert(res[0].caseData[1].name == "Car");

}

unittest
{
  auto res = Parser(q{

      //comments
      Union
      Vehicle of fuelCap : int=
      | Plane   of seats: int # 4 // moar comments
      |Car of plate : string # "na" * seats : int
    }).ParseUnions();
        
  with(res[0])
    {
      assert(name == "Vehicle");
      assert(baseParameters.length  == 1);
      with(baseParameters[0])
        {
          assert(name == "fuelCap");
          assert(type == "int");
        }
      assert(caseData.length == 2);
      with(caseData[0])
        {
          assert(name == "Plane");
          assert(parameters.length == 1);
          with(parameters[0])
            {
              assert(name == "seats");
              assert(type == "int");
              assert(defaultValue == "4");
            }
        }
      with(caseData[1])
        {
          assert(name == "Car");        
          assert(parameters.length == 2);
          with(parameters[0])
            {
              assert(name == "plate");
              assert(type == "string");
              assert(defaultValue == "\"na\"");
            }
          with(parameters[1])
            {
              assert(name == "seats");
              assert(type == "int");
              assert(defaultValue == "");
            }
        }
    }
}


unittest
{
  auto res = Parser(q{
      Union @("hello")@(Constants.10)First = |X|Y|        Z

      Union Second = | @(5,new Xyz(10)) A of x : int | B of y : string
      Union Third of s:string= | John of x : int
      Union Fourth= | Juan 
    }).ParseUnions();

  assert(res.length == 4);
}
