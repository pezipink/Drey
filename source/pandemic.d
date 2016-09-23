import std.stdio;
import std.typecons;
alias wl = writeln;
import deck;
import types;
// 1 8-Page Colour Rulebook
// 1 Folding single-side Gameboard
// 7 Role Cards
// 7 (plastic) Pawns (one colour for each role)
// 6 (plastic) Research Stations
// 96 (plastic) Disease Cubes (24 for each colour disease - black, blue, red, yellow)
// 6 Markers
// 1 Infection Rate Marker
// 1 Outbreaks Marker
// 4 Cure Markers with "Vial" and "Sunset" sides (one for each colour disease)
// 59 Player Cards
// 48 City Cards
// 6 Epidemic Cards
// 5 Special Event Cards
// 48 Infection Cards
// 4 Reference Cards


Tuple!(Disease,CityName[]) GetCityData(CityName name)
{
  final switch(name)
    with(CityName)
      {
      case Algiers : return tuple(Disease.Red,[Atlanta]);
      case Atlanta : return tuple(Disease.Blue,[Chicago,Miami,Washington]);
      case Baghdad : return tuple(Disease.Red,[Atlanta]);
      case Bangkok : return tuple(Disease.Red,[Atlanta]);
      case Beijing : return tuple(Disease.Red,[Atlanta]);
      case Bogotá : return tuple(Disease.Red,[Atlanta]);
      case BuenosAires : return tuple(Disease.Red,[Atlanta]);
      case Cairo : return tuple(Disease.Red,[Atlanta]);
      case Chennai : return tuple(Disease.Red,[Atlanta]);
      case Chicago : return tuple(Disease.Blue,[SanFrancisco,Atlanta,LosAngeles,SanFrancisco,Montréal]);
      case Delhi : return tuple(Disease.Red,[Atlanta]);
      case Essen : return tuple(Disease.Blue,[Atlanta]);
      case HoChiMinhCity : return tuple(Disease.Red,[Atlanta]);
      case HongKong : return tuple(Disease.Red,[Atlanta]);
      case Istanbul : return tuple(Disease.Red,[Atlanta]);
      case Jakarta : return tuple(Disease.Red,[Atlanta]);
      case Johannesburg : return tuple(Disease.Red,[Atlanta]);
      case Karachi : return tuple(Disease.Red,[Atlanta]);
      case Khartoum : return tuple(Disease.Red,[Atlanta]);
      case Kinshasa : return tuple(Disease.Red,[Atlanta]);
      case Kolkata : return tuple(Disease.Red,[Atlanta]);
      case Lagos : return tuple(Disease.Red,[Atlanta]);
      case Lima : return tuple(Disease.Red,[Atlanta]);
      case London : return tuple(Disease.Blue,[Atlanta]);
      case LosAngeles : return tuple(Disease.Yellow,[SanFrancisco,Chicago,MexicoCity]);         // todo
      case Madrid : return tuple(Disease.Blue,[Atlanta]);
      case Manila : return tuple(Disease.Red,[Atlanta]);
      case MexicoCity : return tuple(Disease.Yellow,[LosAngeles,Chicago,Miami,Bogotá,Lima]);
      case Miami : return tuple(Disease.Red,[Atlanta]);

      case Milan : return tuple(Disease.Blue,[Atlanta]);
      case Montréal : return tuple(Disease.Blue,[NewYork,Washington,Chicago]);
      case Moscow : return tuple(Disease.Red,[Atlanta]);
      case Mumbai : return tuple(Disease.Red,[Atlanta]);
      case NewYork : return tuple(Disease.Blue,[Atlanta]);
      case Osaka : return tuple(Disease.Red,[Atlanta]);
      case Paris : return tuple(Disease.Blue,[Atlanta]);
      case Riyadh : return tuple(Disease.Red,[Atlanta]);
      case SanFrancisco : return tuple(Disease.Blue,[Chicago,LosAngeles]); //todo
      case Santiago : return tuple(Disease.Red,[Atlanta]);
      case SaoPaulo : return tuple(Disease.Red,[Atlanta]);
      case Seoul : return tuple(Disease.Red,[Atlanta]);
      case Shanghai : return tuple(Disease.Red,[Atlanta]);
      case StPetersburg : return tuple(Disease.Blue,[Atlanta]);
      case Sydney : return tuple(Disease.Red,[Atlanta]);
      case Taipei : return tuple(Disease.Red,[Atlanta]);
      case Tehran : return tuple(Disease.Red,[Atlanta]);
      case Tokyo : return tuple(Disease.Red,[Atlanta]);
      case Washington : return tuple(Disease.Blue,[NewYork,Montréal,Atlanta,Miami]);
      }
}


final class Pandemic
{
  const numCities = 48;

  // player list and lookup by role
  Player[] players;
  Player[Role.Tags] playerLookup;
  int activePlayer;

  // the player and infection deck / discard decks
  DeckPair!PlayerCard playerCards;
  DeckPair!InfectionCard infectionCards;

  // counters / misc flags
  int outbreaks;
  int infectionRate = 2;
  int remainingResearchStations = 6;
  bool isQuietNight;
  GameState state = GameState.Playing;

  // disease cure / eradiction status and pools
  DiseaseState[Disease] diseaseStates;
  int[Disease] diseasePools;

  // city data
  City[CityName] cities;

  // current epidemic in progress status
  EpidemicState epidemicState;

  // we don't care about the value here,
  // just using this as a set to control outbreak chain reactions
  bool[CityName] currentOutbreak;

  this(Role.Tags[] roles,  int epidemicCards)
  {
    assert(roles.length > 1 && roles.length < 5);
    CreateCitiesAndCards();
    CreatePlayersAndEpidemics(roles,epidemicCards);
    InitialInfection();
    // the game is now ready to play !
  }

  private @property Player currentPlayer() { return players[activePlayer]; }

  private void CreatePlayersAndEpidemics(Role.Tags[] roles, int epidemicCards)
  {
    int startingHand = 2;

    if(roles.length == 3 )
      {
        startingHand = 3;
      }
    else if(roles.length == 2)
      {
        startingHand = 4;
      }

    foreach(r;roles)
      {
        Player p;
        
        p.location = CityName.Atlanta;
        final switch(r)
          {
          case Role.Tags.Medic : p.role = new Medic();  break;
          case Role.Tags.Scientist : p.role = new Scientist(); break;
          case Role.Tags.Researcher : p.role = new Researcher(); break;
          case Role.Tags.Dispatcher : p.role = new Dispatcher(); break;
          case Role.Tags.OperationsExpert : p.role = new OperationsExpert(false); break;
          case Role.Tags.Role : throw new Exception("Role is not a valid player type");
          }
        // give each player n cards
        p.cards.placeTop(playerCards.draw(startingHand));
        players ~= p;

        playerLookup[p.role.Tag] = p;
      }

    // divide the rest of the cards into n piles, add an epidemic to each one,
    // shuffle the mini piles then merge them together into one deck.
    int perPile = numCities / epidemicCards; // this might round off
    Deck!(PlayerCard)[] decks;
    for(int x = 0; x < epidemicCards; x++)
      {
        Deck!PlayerCard deck;
        if( x == epidemicCards-1)
          {
            // the last deck, give it the remaining cards incase of rounding errors
            deck.placeTop(playerCards.active_deck);
          }
        else
          {
            deck.placeTop(playerCards.draw(perPile));
          }
        deck.placeTop(new EpidemicCard());
        deck.shuffle();
        decks ~= deck;
      }
    foreach(d;decks)
      {
        playerCards.active_deck.placeTop(d);
      }
  }

  private void CreateCitiesAndCards()
  {
    cities.clear();
    playerCards.active_deck.items.length=0;
    playerCards.discard_deck.items.length=0;
    infectionCards.active_deck.items.length=0;
    infectionCards.discard_deck.items.length=0;

    import std.traits;
    foreach(const cn; EnumMembers!CityName)
      {
        auto data = GetCityData(cn);
        City c;
        c.name = cn;
        c.connectedCities = data[1];
        c.disease = data[0];
        foreach(const d; EnumMembers!Disease)
          {
            c.infection[d] = 0;
          }
        cities[cn] = c;

        playerCards.active_deck.placeTop(new CityCard(cn));
        infectionCards.active_deck.placeTop(new CityInfectionCard(cn));
      }

    playerCards.active_deck.shuffle();
    infectionCards.active_deck.shuffle();

  }

  private void InitialInfection()
  {
    
    // outer counts the amount of disease to
    // add and also makes the cycle happen 3 times.
    // we start with 3 cards with 3 diseases, then 3 cards
    // with 2 diseases and finally 3 cards with one disease
    for(int outer = 3; outer > 0; outer--)
      {
        for(int x = 0; x < 3; x++)
          {
            auto c = infectionCards.drawSingle();
            for(int y = 0; y < outer; y++)
              {
                if(auto city = c.AsCityInfectionCard)
                  {
                    InfectCity(city.city,cities[city.city].disease);
                  }
                else
                  {
                    // mutation cards, not dealing with these yet (expansion)
                  }
              }
            infectionCards.discard(c);
          }
      }
  }

  private void UpdateGameState()
  {
    // check for win and lose conditions

    // if all diseases are cured, the players win
    bool hasWon = true;
    foreach(s;diseaseStates.values)
      {
        if(s == DiseaseState.Active)
          {
            hasWon = false;
            break;
          }
      }

    if(hasWon)
      {
        state = GameState.Won;
        // if the players won, even if at the same time they lose
        // for some reason, let them win to be nice ..
        return;
      }

    // if there have been 8 + outbreaks, it is game over
    if(outbreaks >= 8)
      {
        state = GameState.Lost;
        return;
      }

    // less than 0 of any disease is game over
    foreach(v;diseasePools.values)
      {
        if(v < 0)
          {
            state = GameState.Lost;
            return;
          }
      }

    // if there are no player cards left, it is game over
    if(playerCards.active_deck.length == 0)
      {
        state = GameState.Lost;
        return;
      }
  }

  private void InfectCity(CityName name, Disease disease)
  {
    if(cities[name].infection[disease] < 3)
      {
        cities[name].infection[disease]++;
      }
    else
      {
        if(name !in currentOutbreak)
          {
            // Outbreak!
            outbreaks++;
            currentOutbreak[name] = 1; // this int is meaningless, just using as a set
            // recursively call for all connected cities
            foreach(c;cities[name].connectedCities)
              {
                InfectCity(c,disease);
              }
          }
      }
  }

  public PlayerAction[] GetAvailableActions(Role.Tags playerTag)
  {
    PlayerAction[] res;

    // prevent the player making any actions if an epidemic is going
    // and deal with the cases where the player draws player / infection cards

    if(currentPlayer.actionsRemaining == 0)
      {
        // todo: which event cards can be played and when during an epidemic?
        if(epidemicState !is null)
          {
            import std.algorithm : find;
            // the player must have a epidemic card already being played
            auto card = currentPlayer.cards.find!(x=>x.Tag==PlayerCard.Tags.EpidemicCard)[0];

            switch(epidemicState.Tag)
              {
              case(EpidemicState.Tags.EpidemicIncrease):
                {
                  // res ~= new ProgressEpidemic(new EpidemicInfect(new EpidemicCard(card.Tag)));
                  break;
                }
              default:
                break;
              }
          }
      }
    else
      {
        // work out the common actions

        foreach(p;players)
          {
            // player can heal any present disease
            foreach(kvp;cities[p.location].infection.byKeyValue)
              {
                if(kvp.value > 0)
                  {
                    res ~= new Heal(kvp.key);
                  }
              }
            // firstly anyone can drive/ferry to a connected city
            foreach(c;cities[p.location].connectedCities)
              {
                res ~= new Drive(p.role.Tag,c);
              }

            if(cities[p.location].hasResearchStation)
              {
                // 5 cards of the same colour means disease can be cured
                int[Disease] counters;
                foreach(c;p.cards)
                  {
                    if(auto c2 = c.AsCityCard)
                      {
                        counters[c2.city.GetCityData[0]]++;
                      }
                  }
                foreach(kvp;counters.byKeyValue)
                  {
                    // only one of these can really be possible but whatevs
                    if(kvp.value >= 5)
                      {
                        // leave the client to tell us the cards
                        // since they might have more than 5 of that colour
                        res ~= new Cure(kvp.key,[]);
                      }
                  }
              }

            // anyone on this city who has that city card can have it taken
            foreach(p2;players)
              {
                if(p2 == p)
                  {
                    continue;
                  }
                if(p2.location == p.location)
                  {
                    foreach(c2;p2.cards)
                      {
                        if(auto x = c2.AsCityCard)
                          {
                            if(x.city == p2.location)
                              {
                                res ~= new Take(p.location,p2.role.Tag);
                                break;
                              }
                          }
                      }
                  }
              }

            foreach(c;p.cards)
              {
                if(auto x = c.AsCityCard)
                  {
                    if(x.city != p.location)
                      {
                        // a player can fly to any city they have the card
                        res ~= new Fly(p.role.Tag,x.city,x.city);
                      }
                    else
                      {
                        import std.traits : EnumMembers;
                        // if the player has the card of the city they are on,
                        // they can use it to fly anywhere
                        foreach(c2;EnumMembers!CityName)
                          {
                            if(c2 != x.city)
                              {
                                res ~= new Fly(p.role.Tag,c2,x.city);
                                // they can also create a research station
                                if(!cities[x.city].hasResearchStation)
                                  {
                                    res ~= new BuildResearchStation();
                                  }
                              }
                          }

                        // if any other player is on this city, the card can be given
                        foreach(p2;players)
                          {
                            if(p2==p)
                              {
                                continue;
                              }
                            if(p2.location == p.location)
                              {
                                res ~= new Give(x.city,p2.role.Tag);
                              }

                          }
                      }
                  }
              }
          }
      }

    // now add any special actions

    return res;
  }

  private void AdvancePlayerTurn()
  {
    activePlayer++;
    if(activePlayer>players.length-1)
      {
        activePlayer = 0;
      }
    currentPlayer.actionsRemaining = 4;
    currentPlayer.playerCardsToDraw = 2;
    currentPlayer.infectionCardsToDraw = 2;
  }

  private void EndPlayerAction()
  {
    currentPlayer.actionsRemaining--;
  }

  public void ProcessAction(PlayerAction action)
  {
    // todo: we probably want this to return some kind of response that will
    // enable animations of things the client can't predict eg infections via outbreaks
    if(auto x = action.AsDrive)
      {
        playerLookup[x.role].location = x.target;
        OnEnterCity(x.role,x.target);
        EndPlayerAction();
      }
    else if(auto x = action.AsFly)
      {
        playerLookup[x.role].location = x.target;
        playerCards.discard
          (playerLookup[x.role].cards.drawSingle
           ((ref y) =>y.IsCityCard && y.AsCityCard.Tag == x.target));

        OnEnterCity(x.role,x.target);
        EndPlayerAction();
      }
    else if(auto x = action.AsHeal)
      {
        bool isEradicated = diseaseStates[x.disease] == DiseaseState.Eradicated;
        if(cities[currentPlayer.location].infection[x.disease] > 1)
          {
            if(isEradicated || currentPlayer.role.Tag == Role.Tags.Medic)
              {
                // remove all cubes if eradicated or medic
                diseasePools[x.disease] += cities[currentPlayer.location].infection[x.disease];
                cities[currentPlayer.location].infection[x.disease] = 0;
              }
            else
              {
                diseasePools[x.disease]++;
                cities[currentPlayer.location].infection[x.disease]--;
              }

          }
        else
          {
            debug{assert(0,"! heal");}
          }
        EndPlayerAction();
      }
    else if(auto x = action.AsCure)
      {
        assert(
               x.cards.length == 5 ||
               (currentPlayer.role.Tag == Role.Tags.Scientist && x.cards.length == 4), "!cure");

        Disease d;
        for(int i = 0; i < x.cards.length; i++)
          {
            if( i == 0)
              {
                d = x.cards[i].GetCityData[0];
              }
            else
              {
                assert(d == x.cards[i].GetCityData[0], "cure passed different disease cards");
              }
          }

        diseaseStates[x.disease] = DiseaseState.Cured;

        foreach(c;x.cards)
          {
            playerCards.discard
              (currentPlayer.cards.drawSingle
               ((ref y)=> y.IsCityCard && y.AsCityCard.Tag == c));
          }
        EndPlayerAction();
      }
    else if(auto x = action.AsGive)
      {
        players[x.role].cards.placeTop
          (currentPlayer.cards.drawSingle
           ((ref y)=>y.IsCityCard && y.AsCityCard.Tag == x.card));

        EndPlayerAction();
      }
    else if(auto x = action.AsTake)
      {
        currentPlayer.cards.placeTop
          (players[x.role].cards.drawSingle
           ((ref y)=>y.IsCityCard && y.AsCityCard.Tag == x.card));

        EndPlayerAction();
      }
    else if(auto x = action.AsBuildResearchStation)
      {
        if(remainingResearchStations > 0)
          {
            cities[currentPlayer.location].hasResearchStation = true;
          }
        else
          {
            debug{assert(0,"! rs");}
          }
        playerCards.discard
          (currentPlayer.cards.drawSingle
           ((ref y)=>y.IsCityCard &&y.AsCityCard.city == currentPlayer.location));

        EndPlayerAction();
      }
    else if(auto x = action.AsProgressEpidemic)
      {
        // todo: some asserts here to check bad states
        ProcessEpidemic(x.state);
      }
    else if(auto x = action.AsUseEvent)
      {
        if(auto y = x.data.AsForecast)
          {
            assert(y.newCards.length == 5);
            // remove top 5 and create new ones in the same order
            // todo: we should probably check the cards are the same here
            // and just re-arrange them
   
        infectionCards.draw(5);
            foreach(c;y.newCards)
              infectionCards.active_deck.placeTop(new CityInfectionCard(c));
          }
        if(auto y = x.data.AsHelicopterLift)
          {
            players[y.role].location = y.target;
            OnEnterCity(y.role,y.target);
          }
        if(auto y = x.data.AsQuietNight)
          {
            isQuietNight = true;
          }
        if(auto y = x.data.AsResilientPopulation)
          {
            infectionCards.discard_deck.drawSingle
              ((ref z)=>z.IsCityInfectionCard && z.AsCityInfectionCard.city == y.toRemove );
          }
        if(auto y = x.data.AsGovernmentGrant)
          {
            cities[y.target].hasResearchStation = true;
          }
        //discard event card
        playerCards.discard
          (playerLookup[x.role]
           .cards
           .drawSingle
           ((ref z)=>z.IsEventCard && z.AsEventCard.Tag == x.data.Tag));
      }
    else if(auto x = action.AsDrawPlayerCard)
      {
        if(currentPlayer.playerCardsToDraw == 0 || playerCards.active_deck.length == 0)
          {
            assert(0,"draw");
          }
        currentPlayer.cards.placeTop(playerCards.drawSingle());
        currentPlayer.playerCardsToDraw--;
      }
    else if(auto x = action.AsDrawInfectionCard)
      {
        if(currentPlayer.infectionCardsToDraw == 0 || playerCards.active_deck.length == 0)
          {
            assert(0,"draw inf");
          }
        auto c = infectionCards.drawSingle();
        assert(!c.IsMutationCard," mutation not implemented yet");
        auto card = c.AsCityInfectionCard;
        currentOutbreak.clear();
        InfectCity(card.city,cities[card.city].disease);
        infectionCards.discard(c);
        currentPlayer.infectionCardsToDraw--;
      }
    else if(auto x = action.AsDiscard)
      {
        // you can't willingly discard an epidemic!
        assert(!x.card.IsEpidemicCard);
        auto c = currentPlayer.cards.drawSingle((ref card) =>
            {
              if(x.card.IsCityCard && card.IsCityCard)
                {
                  return x.card.Tag == card.AsCityCard.Tag;
                }
              else if(x.card.IsEventCard && card.IsEventCard)
                {
                  return x.card.AsEventCard.Tag == card.AsEventCard.Tag;
                }
              return false;
            }());
        assert(c !is null, "!discard");
      }

  }

  private void OnEnterCity(Role.Tags role, CityName city)
  {
    // special actions for some roles.
    if(role == Role.Tags.Medic)
      {
        // medic auto wipes out any eradicated diseases from the CityName
        foreach(kvp;diseaseStates.byKeyValue)
          {
            if(kvp.value == DiseaseState.Eradicated)
              {
                diseasePools[kvp.key] += cities[city].infection[kvp.key];
                cities[city].infection[kvp.key] = 0;
              }
          }
      }
  }

  private void ProcessEpidemic(EpidemicState state)
  {
    if(auto x = state.AsEpidemicIncrease)
      {
        infectionRate++;
        epidemicState = state;
      }
    if(auto x = state.AsEpidemicInfect)
      {
        // take the bottom city
        // todo: need to implement drawSingle(Bottom) properly for deck pair
        // auto c = infectionCards.drawSingle(DrawType.Bottom);
        auto c = infectionCards.active_deck.drawSingle(DrawType.Bottom);
        //todo: handle mutation cards when implemented
        assert(c.IsCityInfectionCard);
        auto card = c.AsCityInfectionCard;
        // infect it with 3
        currentOutbreak.clear();
        for(int y = 0; y < 3; y++)
          {
            InfectCity(card.city, cities[card.city].disease);
          }
        // add to discard pile
        infectionCards.discard(c);
        epidemicState = state;
      }
    if(auto x = state.AsEpidemicIntensify)
      {
        infectionCards.discard_deck.shuffle();
        infectionCards.merge_back();
        // discard epidemic
        playerCards.discard
          (currentPlayer
           .cards
           .drawSingle((ref y) =>
                       y.IsEpidemicCard && y.AsEpidemicCard.Tag == state.card.Tag));

        epidemicState = null;
      }
  }

}

unittest
{
  import std.traits;
  auto p = new Pandemic([Role.Tags.Medic,Role.Tags.Dispatcher],4);
  p.wl;
  assert(true);
}
