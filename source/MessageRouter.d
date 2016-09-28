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


version(unittest)
{

  import du;
  import types;
  
  mixin(DU!q{
      union ControlMessage =
        | Status of message : string
        | ZoomToCity of city : CityName * time : double
        | Etc
  });

}

unittest
{

  auto x = new Status("Hello");
  auto router = MessageRouter!(ControlMessage.Tags, ControlMessage)();

  router.Subscribe(ControlMessage.Tags.Status, x => wl(x.AsStatus.message));

  router.PostMessage(ControlMessage.Tags.Status, new Status("hello world"));
  
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
