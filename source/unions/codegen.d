
module du;
import parse;

string Generate(UnionData[] unions)
{
  import std.string;
  import std.algorithm;
  import std.range;
  string baseClassTemplate = q{
    public abstract class %s
    {
      public enum Tags
      {
        %s
      }

      %s
                        
      private Tags _tag;

      @property Tags Tag() {return _tag;}

      this(%s)
      {
        %s
      }

      @property bool opDispatch(string s)() if(s[0..2] == "Is")
        {
          mixin("return _tag == Tags." ~ s[2..$] ~ ";");
        }
      @property auto opDispatch(string s)() if(s[0..2] == "As")
        {
          enum type = s[2..$];
          mixin("
                                if(_tag == Tags." ~ type ~ ")
                                {
                                        return cast("~type~") cast(void*) this;
                                }
                                else
                                {
                                        return null;
                                }");
                                
        }  

      %s
    }
        
  };


  string classTemplate = q{
    %s
    final class %s : %s
    {
      %s
      this(%s)
      {
        %s
      }
    }
  };
  string ret;
  foreach(data;unions)
    {
      string[string] baseAttributes;
      foreach(a;data.attributes)
        {
          baseAttributes[a.name] = a.args;
        }
      auto baseFields = 
        data
        .baseParameters
        .map!(x=>"\t\t" ~ x.type ~ " " ~ x.name ~ ";" )
        .join("\n");
        
      auto baseConstrcutorArgs = 
        data
        .baseParameters
        .map!(x=>
              x.defaultValue == "" 
              ? x.type ~ " " ~  x.name ~ " = " ~ x.name ~ ".init" 
              : x.type ~ " " ~ x.name ~ " = " ~ x.defaultValue)
        .join(", ");
        
      auto baseConstructor =
        data
        .baseParameters
        .map!(x=>"\t\t\tthis." ~ x.name ~ "=" ~ x.name ~ ";" )
        .join("\n");
        
      baseConstructor ~= "\n\t\t\tthis._tag = Tags." ~ data.name ~ ";";         
        
      string tags = "\t" ~ data.name ~ ",\n" ~  data.caseData.map!(x=>"\t\t"~x.name).join(",\n");

      string derivedTypes =
        format("import std.meta : AliasSeq; alias __derivedTypes = AliasSeq!(%s);",
               data.caseData.map!(x=>x.name).join(","));

      auto baseClassDef = 
        baseClassTemplate.format(data.name,tags,baseFields,baseConstrcutorArgs,baseConstructor,derivedTypes);
        
      ret ~= baseClassDef;
      ret ~= "\n";
        
      foreach(c;data.caseData)
        {
          string[string] atts;
          foreach(a;baseAttributes.keys)
            {
              atts[a] = baseAttributes[a];
            }
          foreach(a;c.attributes)
            {
              atts[a.name] = a.args;
            }
          string derivedAtts = "";
          foreach(a;atts.keys)
            {
              derivedAtts ~= "@("~a~atts[a]~")\n";      
            }
                        

          auto derivedFields = 
            c
            .parameters
            .map!(x=>"\t\t" ~ x.type ~ " " ~ x.name ~ ";" )
            .join("\n");
                        
          auto derivedConstrcutorArgs = 
            c
            .parameters
            .map!(x=>
                  x.defaultValue == "" 
                  ? x.type ~ " " ~  x.name ~ " = " ~ x.name ~ ".init" 
                  : x.type ~ " " ~ x.name ~ " = " ~ x.defaultValue)
            .join(", ");

          if(baseConstrcutorArgs != "")
            {
              derivedConstrcutorArgs = baseConstrcutorArgs ~ ", " ~ derivedConstrcutorArgs;     
            }
          // .join("\n")
          auto derivedConstructor =
            data
            .baseParameters
            .map!(x=>"\t\t\tthis." ~ x.name ~ "=" ~ x.name ~ ";" )
            .chain(
                   c.parameters
                   .map!(x=>"\t\t\tthis." ~ x.name ~ "=" ~ x.name ~ ";" ))
            .join("\n");
                        
          derivedConstructor ~= "\n\t\t\tthis._tag = Tags." ~ c.name ~ ";";     
                        
          auto derivedClassDef = classTemplate.format(derivedAtts,c.name,data.name,derivedFields,derivedConstrcutorArgs,derivedConstructor);
          ret ~= derivedClassDef;
          ret ~= "\n";
        }
    }

  return ret;
}


template DU(string S)
{
  enum DU = Parser(S).ParseUnions.Generate;
}

template IsUnion(UnionType)
{
  const IsUnion = __traits(compiles, {
      UnionType.Tags t;
      alias a = UnionType.__derivedTypes;
    });
}
