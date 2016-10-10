import du;
import std.stdio;
alias wl = writeln;

struct MessageRouter(KeyType, MessageType)
{
private:
  MessageType[][KeyType] pendingMessages;
  // this would be better as a linked list but perf is not really an issue..
  void delegate(MessageType)[][KeyType] subscribers;
  
public:
  /// note that you cannot unsubscribe if you pass a lambda!
  void Subscribe(KeyType key, void delegate(MessageType) action)
  {
    subscribers[key] ~= action;
    return ;
  }

  void Unsubscribe(KeyType key, void delegate(MessageType) action)
  {
    import std.algorithm : filter;
    import std.array;
    subscribers[key] = subscribers[key].filter!(x=>x!=action).array;
  }

  void PostMessage(KeyType key, MessageType value)
  {
    pendingMessages[key] ~= value;
  }
  
  void ProcessMessages()
  {
    foreach(m;pendingMessages.byKeyValue)
      {
        if(m.key in subscribers)
          {
            foreach(a;subscribers[m.key])
              {
                foreach(v;m.value)
                  {
                    a(v);
                  }
              }
          }
      }
    pendingMessages.clear();
  }
}

struct UnionMessageRouter(UnionType)
  if(IsUnion!UnionType)
{
  MessageRouter!(UnionType.Tags, UnionType) router;

  void ProcessMessages() 
  {
    return router.ProcessMessages();
  }

  void PostMessage(UnionType t)
  {
    router.PostMessage(t.Tag, t);
    
  }

  void Subscribe(UnionCaseType)(void delegate(UnionCaseType) action)
    if(IsDescendantFromUnion!(UnionType,UnionCaseType))
  {
    mixin("router.Subscribe(UnionCaseType.__compileTimeTag,x=>action(x.As"~UnionCaseType.stringof~"));");
  }
  
  void Unsubscribe(UnionType.Tags key, void delegate(UnionType) action)
  {
    router.Unsubscribe(key, action);
  }

  
}

unittest
{
  wl("**",IsUnion!TestMessage);
  auto r = UnionMessageRouter!TestMessage();
  r.Subscribe(TestMessage.Tags.Status, x=> wl(x.AsStatus.message));
  r.PostMessage(new Status("hello world!"));
  r.ProcessMessages();
  assert(IsDescendantFromUnion!(TestMessage, Status));
  //assert(IsDescendantFromUnion!(TestMessage, PlayerCard));
}


version(unittest)
{

  import du;
  import types;
  
  mixin(DU!q{
      union TestMessage =
        | Status of message : string
        | ZoomToCity of city : CityName * time : double
        | Etc
  });

}

unittest
{

  auto x = new Status("Hello");
  auto router = MessageRouter!(TestMessage.Tags, TestMessage)();

  router.Subscribe(TestMessage.Tags.Status, x => wl(x.AsStatus.message));

  router.PostMessage(TestMessage.Tags.Status, new Status("hello world"));
  
  router.ProcessMessages();

  
}



unittest
{
  void test(string s) { wl(s);return; }
  auto x = MessageRouter!(int,string)();
  
  x.Subscribe(1,&test);

  assert(x.subscribers.length == 1);
  assert(x.subscribers[1].length == 1);
  x.Subscribe(1, x=>{ wl(x);return; }());

  assert(x.subscribers[1].length == 2);

  x.PostMessage(1,"hello");
  x.ProcessMessages();

  x.Unsubscribe(1,&test);
  assert(x.subscribers[1].length == 1);

  x.PostMessage(1,"hello");
  x.ProcessMessages();

}
