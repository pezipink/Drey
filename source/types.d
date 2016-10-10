import du;
import deck;
enum CityName
{
	Algiers,	
	Atlanta,	
	Baghdad,	
	Bangkok,	
	Beijing,	
	Bogota,	
	BuenosAires,	
	Cairo,	
	Chennai,	
	Chicago,	
	Delhi,	
	Essen,	
	HoChiMinhCity,	
	HongKong,	
	Istanbul,	
	Jakarta,	
	Johannesburg,	
	Karachi,	
	Khartoum,	
	Kinshasa,	
	Kolkata,	
	Lagos,	
	Lima,	
	London,	
	LosAngeles,	
	Madrid,	
	Manila,	
	MexicoCity,	
	Miami,	
	Milan,	
	Montreal,
	Moscow,	
	Mumbai,	
	NewYork,	
	Osaka,	
	Paris,	
	Riyadh,	
	SanFrancisco,	
	Santiago,	
	SaoPaulo,	
	Seoul,	
	Shanghai,	
	StPetersburg,	
	Sydney,	
	Taipei,	
	Tehran,	
	Tokyo,	
	Washington,	
}

enum Disease
{
	Red,
	Blue,
	Black,
	Yellow,
	Purple
}

enum EpidemicType
{
	Standard
	// todo: for On The Brink expansion
}

mixin(DU!q{


Union Role =
| Medic
| Scientist
| Researcher
| Dispatcher
| OperationsExpert of usedSpecial : bool # false
 // ... etc

Union Event =
| Forecast of newCards : CityName[]	// the new order of the top 5 cards of the infection pile
| HelicopterLift of role : Role.Tags * target : CityName
| QuietNight
| ResilientPopulation of toRemove : CityName // city to perma remove from the infection pile
| GovernmentGrant of target : CityName 		 // city to build research station at

Union PlayerCard =
| EpidemicCard of type : EpidemicType # EpidemicType.Standard
| CityCard of city : CityName
| EventCard of event : Event

Union InfectionCard =
| CityInfectionCard of city : CityName
| MutationCard	

Union EpidemicState of card : EpidemicCard = // we don't really need the card yet but will for the expansion epidemics
| EpidemicIncrease  // infection rate ++ 
| EpidemicInfect	// bottom card gets 3 disease 
| EpidemicIntensify // shuffle infection discard and place ontop of infection deck
      
Union PlayerAction =
// Movement requires an explict role since the dispatcher can move other players
| Drive of role : Role.Tags * target : CityName 
| Fly  of role : Role.Tags * target : CityName * card : CityName 
| Heal of disease : Disease
| Cure of disease : Disease * cards : CityName[]
| Give of card : CityName * role : Role.Tags
| Take of card : CityName * role : Role.Tags
| BuildResearchStation
| ProgressEpidemic of state : EpidemicState
// events can be used by anyone not just the current player
| UseEvent of role : Role.Tags * data : Event
| DrawPlayerCard
| DrawInfectionCard
| Discard of card : PlayerCard

});


struct City
{
  CityName name;
  CityName[] connectedCities;
  Disease disease;
  int[Disease] infection;
  bool hasResearchStation;
}

struct Player
{
  Role role;
  CityName location;
  Deck!PlayerCard cards;
  int actionsRemaining = 4;
  int playerCardsToDraw = 2;
  int infectionCardsToDraw = 2;
}

enum DiseaseState
  {
    Active,
    Cured,
    Eradicated
  }

enum GameState
  {
    Playing,
    Won,
    Lost
  }
