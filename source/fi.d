import std.algorithm;
import std.stdio;
import std.traits;
import std.array;  
import metafunc;
import deck;
import du;

enum GameState { Won, Lost, InProgress }
enum LocationStatus { Surface, Sinking,	Sunk }
enum Direction { North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest }

enum orthogonal = [Direction.North,Direction.South,Direction.East,Direction.West];
enum diagonal =  [Direction.NorthEast,Direction.NorthWest,Direction.SouthEast,Direction.SouthWest];
enum allDirections = orthogonal ~ diagonal;  
mixin(DU!q{
	@(SourceImage("fi.jpg",409,585))
	Role =	
	| @(FrontImage(3,4)) Diver
	| @(FrontImage(3,2)) Pilot
	| @(FrontImage(3,3)) Messenger
	| @(FrontImage(3,1)) Explorer
	| @(FrontImage(3,5)) Engineer
	| @(FrontImage(3,6)) Navigator
});

mixin(DU!q{
	Artifact =
	| WaterArtifact
	| EarthArtifact
	| WindArtifact
	| FireArtifact
});

// card attributes 
struct StartPosition { Role role; }
struct ArtifactLocation { Artifact artifact; }
struct SourceImage { string imageFile; int itemWidth; int itemHeight; }
struct FrontImage { int row; int col; }
struct BackImage { int row; int col; }

// card decks & metadata 
mixin(
DU!q{
	@(Quantity(5), SourceImage("fi.jpg",409,585), BackImage(3,8))
	Treasure =
  	| @(FrontImage(2,7)) 
  		Earth
  	| @(FrontImage(2,5)) 
		Fire
	| @(FrontImage(2,4)) 
		Water
	| @(FrontImage(2,6)) 
		Wind
  	| @(Quantity(3),
  		FrontImage(2,9)) 
  		HelicopterLift        
  	| @(Quantity(2),
  		FrontImage(2,8)) 
  		SandBag 
  	| @(Quantity(3),
  		FrontImage(3,0)) 
  		WatersRise	
});

mixin(
DU!q{
	@(Quantity(1),SourceImage("fi.jpg",409,585))
	Location of Status : LocationStatus # LocationStatus.Surface =
	| @(FrontImage(1,1),BackImage(5,1))
		BreakersBridge
	| @(FrontImage(1,0),BackImage(5,0))
		CliffsOfAbandon 
	| @(FrontImage(0,4),BackImage(4,4))
		CrimsonForest
	| @(FrontImage(2,0),BackImage(6,0))
		DunesOfDeception	
	| @(FrontImage(2,1),BackImage(6,1))
		LostLagoon
	| @(FrontImage(1,8),BackImage(5,8))
		MistyMarsh
	| @(FrontImage(1,9),BackImage(5,9))
		Observatory
	| @(FrontImage(2,2),BackImage(6,2))
		PhantomRock
	| @(FrontImage(0,5),BackImage(4,5))
		TwilightHollow
	| @(FrontImage(0,6),BackImage(4,6))
		Watchtower
	
	| @(StartPosition(new Engineer()),FrontImage(0,9),BackImage(4,9))
		BronzeGate
	| @(StartPosition(new Explorer()),FrontImage(1,5),BackImage(5,5))
		CopperGate
	| @(StartPosition(new Navigator()),FrontImage(0,2),BackImage(4,2))
		GoldGate
	| @(StartPosition(new Messenger()),FrontImage(1,7),BackImage(5,7))
		SilverGate
	| @(StartPosition(new Pilot()),FrontImage(0,0),BackImage(4,0)) 		
		FoolsLanding
 	| @(StartPosition(new Diver()),FrontImage(0,3),BackImage(4,3)) 		
 		IronGate

	| @(ArtifactLocation(new EarthArtifact()),FrontImage(0,1),BackImage(4,1)) 		
		TempleOfTheMoon
	| @(ArtifactLocation(new EarthArtifact()),FrontImage(1,6),BackImage(5,6))
		TempleOfTheSun
	| @(ArtifactLocation(new FireArtifact()),FrontImage(0,8),BackImage(4,8)) 		
		CaveOfEmbers
	| @(ArtifactLocation(new FireArtifact()),FrontImage(2,3),BackImage(6,3)) 		
		CaveOfShadows
	| @(ArtifactLocation(new WaterArtifact()),FrontImage(1,2),BackImage(5,2)) 		
		CoralPalace
	| @(ArtifactLocation(new WaterArtifact()),FrontImage(1,4),BackImage(5,4)) 		
		TidalPalace
	| @(ArtifactLocation(new WindArtifact()),FrontImage(1,3),BackImage(5,3)) 	
		HowlingGarden
	| @(ArtifactLocation(new WindArtifact()),FrontImage(0,7),BackImage(4,7)) 	
		WhisperingGarden

	});
	
mixin(
DU!q{
	Action of source : Role =
	| Skip 
	| Move of target : Role * destination : Location * isStranded : bool 
	| Shore of destination : Location 
	| Trade of dest : Role * item : Treasure
	| Claim of type : Artifact
	| Discard of item : Treasure
	| DrawTreasure 
	| DrawFlood 
	| WatersRiseAction of card : Treasure
	| TileFloods of destination : Location 
	| HelicopterLiftAction of target : Role * destination : Location * card : Treasure
	| SandbagAction of destination  : Location * card : Treasure
});

alias HasAttribute(Attribute,T) = hasUDA!(T,Attribute);

template GetAttribute(Attribute, T)
{
	enum GetAttribute()
	{
		import std.typetuple;
		foreach(attr; __traits(getAttributes, T))
		{
			static if(is(typeof(attr) == Attribute))
			{
				return attr;
			}
		}
		assert(0);
	}
}

struct ImageData
{
	string imageFile;
	int itemWidth;
	int itemHeight;
	int FrontCol;
	int FrontRow;
	int BackCol;
	int BackRow;
}


// generated discriminated unions all have a __derivedTypes alias on them
template DerivedTypes(T)
	if(__traits(compiles,T.__derivedTypes))
{
	alias DerivedTypes = T.__derivedTypes;
}

template createMap(Att,alias Mapper)
{
	auto createMap(T, U)(U acc)
	{
		alias att = GetAttribute!(Att,T);
		Mapper(acc,att,Make!T);
		return acc;	
	}	
}

template createImageData(T)
{
	auto createImageData()(ImageData[string] acc)
	{
		ImageData data;
		T t = Make!T;
		foreach(attr; __traits(getAttributes, T))
		{
			static if(is(typeof(attr) == FrontImage))
			{
				data.FrontRow = attr.row;
				data.FrontCol = attr.col;
			}
			else static if(is(typeof(attr) == BackImage))
			{
				data.BackRow = attr.row;
				data.BackCol = attr.col;
			}
			else static if(is(typeof(attr) == SourceImage))
			{
				data.imageFile = attr.imageFile;
				data.itemHeight = attr.itemHeight;
				data.itemWidth = attr.itemWidth;
			}
		}
		acc[t.__tag()] = data;
		return acc;
	}
}

private alias imageFolder = meta_fold!(ImageData[string],createImageData);

alias locationImageMap = imageFolder!(DerivedTypes!Location);
alias treasureImageMap = imageFolder!(DerivedTypes!Treasure);
alias roleImageMap = imageFolder!(DerivedTypes!Role);

alias startPositions =
	meta_pipe!(
		Location,
		DerivedTypes,
		meta_filter!(meta_partial!(HasAttribute,StartPosition)),
		meta_fold!(
			string[string],
			createMap!(
				StartPosition,
				(ref acc,att,item) => acc[att.role.__tag()] = item.__tag()) 
		));

alias artifactLocations =
	meta_pipe!(
		Location,
		DerivedTypes,
		meta_filter!(meta_partial!(HasAttribute,ArtifactLocation)),
		meta_fold!(
			Artifact[Location],
			createMap!(
				ArtifactLocation,
				(ref acc,att,item) => acc[item] = att.artifact 				
		)));

template createDeck(DU)
	if(isAbstractClass!DU)
{
	auto createDeck() 
	{
		alias types = DerivedTypes!DU;
		Deck!DU results;
		foreach(T;types)
		{			
			static if(HasAttribute!(Quantity,T))
			{
				for(int i=0; i<GetQuantity!T; i++)
				{
		 	 		results.placeTop(new T());
				}
			}
		}

		return results;
	}
}

template flatten(alias mapper = "a") 
{
	auto flatten(Range)(Range r) 
	{
		import std.algorithm : map;
		import std.range : join;
		return r.map!(mapper).join;
	}
}

template choose(alias mapper, alias filter = "a !is null") 
{
	auto flatten(Range)(Range r) 
	{
		import std.algorithm : map, filter;
		return r.filter!(filter).map!(mapper);
	}
}



class Player
{
	Role role;
	Deck!Treasure treasureHand;	
	bool usedAbility = false;
	Location location;
	int actionsTaken;
	int floodCardsDrawn;
	int treasureCardsDrawn;
	this(Role _role)
	{
		role = _role;
		treasureHand = Deck!Treasure();
	}
}

class ForbiddenIsland 
{
	import std.typecons : tuple, Tuple;
	GameState state;
	Player[] players;
	immutable maxTreasureHand = 5;
	int currentPlayer = 0;
	auto treasureDeck = DeckPair!Treasure(createDeck!Treasure,Deck!Treasure());
	auto islandTiles =createDeck!Location;
	auto floodDeck = DeckPair!Location(createDeck!Location,Deck!Location());
	Location lastFlood;  

	Location[6][6] island;

	Action[] previousActions;
	Action[] currentActions;

	Artifact[] claimedArtifacts;

	int waterLevel = 1;
	
	private void nextPlayer()
	{
		if(currentPlayer < players.length - 1)
		{
			currentPlayer++;
		}
		else
		{
			currentPlayer = 0;
		}
		with(players[currentPlayer])
		{
			actionsTaken = 0;
			treasureCardsDrawn = 0;
			floodCardsDrawn = 0;
			usedAbility = false;
		}
	}

	private @property int floodCardsPerTurn()
	{
		if( waterLevel < 3) 
		{
			return 2;
		}
		else if(waterLevel < 6)
		{
			return 3;
		}
		else if(waterLevel < 8)
		{
			return 4;
		}
		else
		{
			return 5;
		}
	}

	private Location getLocation(Location floodCard)
	{
		foreach(tile;islandTiles.items)
		{
			if(tile.__tag() == floodCard.__tag())
			{
				return tile;
			}
		}
		assert(0);
	}

	private void resolveFloodCard(Location card)
	{
		lastFlood = card;
		if(card.Status == LocationStatus.Surface)
		{
			card.Status = LocationStatus.Sinking;
			floodDeck.discard(card);
		}
		else if(card.Status == LocationStatus.Sinking)
		{
			card.Status = LocationStatus.Sunk;
			// this card is lost for good!
		}
		else
		{
			assert(0);
		}		
	}

	private void watersRise()
	{
		waterLevel++;
		floodDeck.discard_deck.shuffle;
		// put the discard flood cards onto the top of the active deck
		floodDeck.merge();
	}

	Tuple!(int,int) FindPosition(Location location)
	{
		for(int x = 0; x < 6; x++)
		{
			for(int y = 0; y < 6; y++)
			{
				if( island[y][x] ! is null && island[y][x].__tag() == location.__tag())
				{
					return tuple(x,y);
				}
			}
		}
		assert(0);
	}
	
	void initialize(Role[] roles, int initialWaterLevel, bool shuffle = true)
	{
		state = GameState.InProgress;
		if(shuffle)
		{
			treasureDeck.shuffle;
			islandTiles.shuffle;
			floodDeck.shuffle;
		}
		// distribute 2 treasure cards to each player
		foreach(role; roles)
		{
			auto p = new Player(role);

			while(p.treasureHand.length < 2)
			{		
				auto t = treasureDeck.drawSingle;
				// don't give out waters rise cards at the start!
				if(auto w = cast(WatersRise)t)
				{
					treasureDeck.discard(t);
				}
				else
				{
					p.treasureHand.placeTop(t);
				}
			}

			players ~= p;
		}

		treasureDeck.merge.shuffle;

		// assign starting locations
		foreach(p; players)
		{
			auto loc =  startPositions[p.role.__tag()] ;
			foreach(t;islandTiles)
			{
				if(t.__tag() == loc)
				{
					p.location = t;
					break;
				}
			}
		}

		// layout the island in a 6x6 grid like so
		// [row][col] (change this in the future to allow other shapes!)
		// 		0	1	2	3	4	5
		// 	0			X	X
		//	1		X	X	X	X
		//  2	X	X	X	X	X	X
		//  3	X	X	X	X	X	X
		//	4		X	X	X	X
		// 	5			X	X

		int j = 0;
		for(int i = 0; i < 3; i ++)
		{
			final switch(i)
			{
				case 0:
					island[0][2] = islandTiles.items[j++];
					island[0][3] = islandTiles.items[j++];
					
					island[5][2] = islandTiles.items[j++];
					island[5][3] = islandTiles.items[j++];
				break;
				case 1:
					island[1][1] = islandTiles.items[j++];
					island[1][2] = islandTiles.items[j++];
					island[1][3] = islandTiles.items[j++];
					island[1][4] = islandTiles.items[j++];

					island[4][1] = islandTiles.items[j++];
					island[4][2] = islandTiles.items[j++];
					island[4][3] = islandTiles.items[j++];
					island[4][4] = islandTiles.items[j++];
				break;
				case 2:
					island[2][0] = islandTiles.items[j++];
					island[2][1] = islandTiles.items[j++];
					island[2][2] = islandTiles.items[j++];
					island[2][3] = islandTiles.items[j++];
					island[2][4] = islandTiles.items[j++];
					island[2][5] = islandTiles.items[j++];


					island[3][0] = islandTiles.items[j++];
					island[3][1] = islandTiles.items[j++];
					island[3][2] = islandTiles.items[j++];
					island[3][3] = islandTiles.items[j++];
					island[3][4] = islandTiles.items[j++];
					island[3][5] = islandTiles.items[j++];
				break;
			}
		}
		islandTiles.items.each!(x=>x.Status = LocationStatus.Surface);
		// draw and resolve the first 6 flood cards
		floodDeck.draw(6).each!(card=>resolveFloodCard(getLocation(card)));

	}

	void checkWinLoseConditions()
	{
		
		if(	   claimedArtifacts.length == 4 
			&& players.all!(x => x.location.IsFoolsLanding)
			&& players.flatten!(x=>x.treasureHand.items).any!(x=>x.IsHelicopterLift))
		{
			state = GameState.Won;
			return;
		}

		if(waterLevel > 10)
		{
			version(Debug)
			{
				writeln("water > 10 loss");
			}
			state = GameState.Lost;
			return;
		}

		int[Artifact] sunkTemples;

		foreach(tile; islandTiles.items)
		{
			if(tile.Status == LocationStatus.Sunk)
			{
				if(auto fl = cast(FoolsLanding)tile)
				{
					state = GameState.Lost;
					return;						
				}
				else if(tile in artifactLocations)
				{
					sunkTemples[artifactLocations[tile]]++;
				}
			}
		}

		foreach(kvp; sunkTemples.byKeyValue)
		{
			if(kvp.value == 2 && !claimedArtifacts.any!(x=>x==kvp.key))
			{
				version(Debug)
				{
					writeln("template/artifact lose");
				}
				state = GameState.Lost;
				return;
			}
		}
	}

	auto FindLocationCoordinates(Location loc)
	{
		for(int y = 0; y < island.length; y++)
		{
			for(int x = 0; x < island[y].length; x++)
			{
				if((island[y][x]) == loc)
				{
					return tuple(y,x);
				}
			}
		}
		assert(0);
	}

	auto GetMovement(Location currentLocation, Direction[] directions)
	{
		auto coords = FindLocationCoordinates(currentLocation);
		Tuple!(Direction,Location)[] results;
		int y = coords[0];
		int x = coords[1];
		bool canNorth =  y > 0;
		bool canSouth = y < 5;
		bool canEast = x < 5;
		bool canWest = x > 0;
		bool isNorth =  canNorth && island[y-1][x] !is null;
		bool isSouth = canSouth && island[y+1][x] !is null;
		bool isEast = canEast && island[y][x+1] !is null;
		bool isWest = canWest && island[y][x-1] !is null;
		bool IsNorthWest = canNorth && canWest && island[y-1][x-1] !is null;
		bool IsSouthWest = canSouth && canWest && island[y+1][x-1] !is null;
		bool IsNorthEast = canNorth && canEast && island[y-1][x+1] !is null;
		bool IsSouthEast = canSouth && canEast && island[y+1][x+1] !is null;
		foreach(d;directions)
		{
			if( d == Direction.North && isNorth) results ~= tuple(Direction.North, island[y-1][x]);
			if( d == Direction.South && isSouth) results ~= tuple(Direction.South, island[y+1][x]);
			if( d == Direction.East && isEast) results ~= tuple(Direction.East, island[y][x+1]);
			if( d == Direction.West && isWest) results ~= tuple(Direction.West, island[y][x-1]);
			if( d == Direction.NorthWest && IsNorthWest) results ~= tuple(Direction.NorthWest, island[y-1][x-1]);
			if( d == Direction.NorthEast && IsNorthEast) results ~= tuple(Direction.NorthEast, island[y-1][x+1]);
			if( d == Direction.SouthWest && IsSouthWest) results ~= tuple(Direction.SouthWest, island[y+1][x-1]);
			if( d == Direction.SouthEast && IsSouthEast) results ~= tuple(Direction.SouthEast, island[y+1][x+1]);
		}
		return results;
	}

	Player GetByRole(Role role)
	{
		foreach(p; players)
		{
			if(p.role.__tag == role.__tag)
			{
				return p;
			}
		}
		assert(0);
	}

	private auto getAvailableTiles(Player p) 
	{			
		return
			GetMovement(
				p.location,
				p.role.IsExplorer 
					? allDirections
					: orthogonal
			);			
	}

	private auto indexOfAction(Action action)
	{
		for(int i =0; i < currentActions.length; i++)
		{
			if(currentActions[i]==action)
			{
				return i;
			}
		}
		assert(0);
	}
	auto ProcessAction(Action action)
	{
		previousActions ~= action;

		action.castSwitch!(
			(Skip x) => {
				auto player = GetByRole(x.source);
				player.actionsTaken++;
			}(),
			(Move x) => {
				// the navigator can move other people so the source is the person taking the action
				// and the target is the person being moved
				auto sourcePlayer = GetByRole(x.source);
				auto targetPlayer = GetByRole(x.target);
				auto newLoc = getLocation(x.destination);
				// pilot's special ability
				if(x.source.IsPilot
					&& !x.isStranded 
					&& !sourcePlayer.usedAbility 
					// don't use the special ability if they are able to walk!
					&& !GetMovement(sourcePlayer.location, orthogonal).any!(t => t[1] == newLoc))
				{
					sourcePlayer.usedAbility = true;
				}
				targetPlayer.location = newLoc;	
				if( !x.isStranded)
				{
					sourcePlayer.actionsTaken++;
				}
				currentActions = [];
			}(),
			(Shore x) => {
				auto player = GetByRole(x.source);
				getLocation(x.destination).Status = LocationStatus.Surface;
				// engineer gets the second one free if his ability is "used"
				if(player.role.IsEngineer)
				{
					if(player.usedAbility)
					{
						player.usedAbility = false;
					}
					else
					{
						player.usedAbility = true;
						player.actionsTaken++;		
					}
				}
				else
				{
					player.actionsTaken++;
				}
				currentActions = [];
			}(),	
			(Trade x) => {
				auto source = GetByRole(x.source);
				auto dest = GetByRole(x.dest);
				auto card = source.treasureHand.drawSingle(x.item);
				dest.treasureHand.placeTop(card);
				source.actionsTaken++;			
				currentActions = [];
			}(),	
			(Claim x) => {
				auto source = GetByRole(x.source);
				claimedArtifacts ~= x.type;
				// remove treasure cards
				string card;
				final switch(x.type.__tag())
				{
					case "EarthArtifact": card = "Earth"; break;
					case "FireArtifact": card = "Fire"; break;
					case "WindArtifact": card = "Wind"; break;
					case "WaterArtifact": card = "Water"; break;
				}

				auto toDiscard = 
					source
						.treasureHand
						.items
						.filter!(x=>x.__tag()==card)
						.array;
				
				foreach(discard;toDiscard)
				{
					treasureDeck.discard(source.treasureHand.drawSingle(discard));	
				}
				
				source.actionsTaken++;
				currentActions = [];
			}(),	
			(Discard x) => {
				auto source = GetByRole(x.source);
				treasureDeck.discard(source.treasureHand.drawSingle(x.item));
				currentActions = [];
			}(),	
			(DrawTreasure x) => {
				auto source = GetByRole(x.source);
				source.treasureHand.placeTop(treasureDeck.drawSingle);
				source.treasureCardsDrawn++;
				currentActions = [];
			}(),	
			(DrawFlood x) => {
				auto source = GetByRole(x.source);
				auto card = floodDeck.drawSingle;
				// force the tile to flood, no chance to use sandbags!
				currentActions = [];
				currentActions ~= new TileFloods(x.source,card);
				source.floodCardsDrawn++;
			}(),	
			(WatersRiseAction x) => {
				watersRise();
				auto source = GetByRole(x.source);
				auto card = source.treasureHand.drawSingle(x.card);
				treasureDeck.discard(card);
				currentActions = [];
			}(),	
			(TileFloods x) => {
				auto source = GetByRole(x.source);
				resolveFloodCard(getLocation(x.destination));
				if(source.floodCardsDrawn == floodCardsPerTurn)
				{
					nextPlayer();
				}
				currentActions = [];
			}(),	
			(HelicopterLiftAction x) => {
				auto source = GetByRole(x.source);
				auto target = GetByRole(x.target);
				target.location = getLocation(x.destination);
				treasureDeck.discard(source.treasureHand.drawSingle(x.card));
				currentActions = [];
			}(),	
			(SandbagAction x) => {
				auto source = GetByRole(x.source);
				getLocation(x.destination).Status = LocationStatus.Surface;
				treasureDeck.discard(source.treasureHand.drawSingle(x.card));
				currentActions = [];
			}()
		)
		;

	}

	@property auto CurrentRole()
	{
		return players[currentPlayer].role;
	}

	auto GetPlayerActions()
	{
		return GetAvailableActions(CurrentRole);
	}

	auto GetAvailableActions(Role role)
	{
		if(currentActions.length>0)
		{
			return currentActions;
		}

		//TODO: The diver can move orthogonally across any amount of sinking or sunk tiles to land 
		// on a sinking or surfaced tiles  for 1 action

		//TODO: the navigator can move anyone up to *2* orthogonal tiles for 1 action
		// represent this as a single choice.
		// exceptions : if moving the explorer then include all directions 
		// if moving the diver then the first tile may be sunk.

		//TODO: Engineer when used last move but used special = true, can still shore something up if possible 

		auto allNotSunkTiles = islandTiles.items.filter!(t=>t.Status != LocationStatus.Sunk);
		auto allSinkingTiles = islandTiles.items.filter!(t=>t.Status == LocationStatus.Sinking);
		
		// check for stranded players. this must be resolve as a move action where possible,
		// or its game over! in this case you cannot use helicopter lifts to save you!
		foreach(p;players)
		{
			if(p.location.Status == LocationStatus.Sunk)
			{
				if(p.role.IsPilot)
				{
					// pilot can always fly out to any tile
					allNotSunkTiles.each!(loc => currentActions ~= new Move(p.role,p.role,loc,true));
				}
				else
				{
					// explorer and diver can use their usual movement rules
					// everyone else orthogonal
					foreach(tup;getAvailableTiles(p))
					{
						// everyone can move and shore up adjacent if the tile is not sunk
						// TODO: Diver's movement....						
						if(tup[1].Status != LocationStatus.Sunk) currentActions ~= new Move(p.role,p.role,tup[1],true);
					}	
				}
				if(currentActions.length == 0)
				{
					state = GameState.Lost;
				}
				return currentActions;
			}
		}

		// all sandbag / helicopter cards can be played at any time from any player 
		// this includes when forced to discard, the only time this does not apply
		// is when drawing a flood card that would sink
		foreach(p1;players)
		{
			foreach(c;p1.treasureHand.items)
			{
				if(c.IsSandBag)
				{
					allSinkingTiles.each!(t => currentActions ~= new SandbagAction(p1.role,t,c));
				}
				else if(c.IsHelicopterLift)
				{
					foreach(p2;players)
					{
						allNotSunkTiles.each!(t => currentActions ~= new HelicopterLiftAction(p1.role,p2.role,t,c));
					}
				}
			}
		}				

		Player p = GetByRole(role);

		foreach(card;p.treasureHand.items)
		{
			 // if a player has a waters rise card, they cannot do anything else but play it
			 if(auto water = cast(WatersRise)card)
			 {
			 	currentActions ~= new WatersRiseAction(p.role,water);
			 	return currentActions;
			 }
		}

		// no player can have more than 5 treasure cards. stop everything until this is addressed.
		foreach(p1;players)
		{
			if(p1.treasureHand.items.length > 5)
			{
				//this player can do nothing until they have discarded treasure cards.
				// (or used a special card)
				foreach(x;p1.treasureHand.items)
				{
					// todo: add sandbags and heli
					currentActions~= new Discard(p1.role,x);
				}
				return currentActions;
			}	
		}
		
		if(p.actionsTaken < 3 )
		{
			currentActions ~= new Skip(p.role);

			// special case for shoring up tile player is standing on
			if(p.location.Status == LocationStatus.Sinking)
			{
				currentActions ~= new Shore(p.role, p.location);
			}

			foreach(tup;getAvailableTiles(p))
			{
				// everyone can move and shore up adjacent if the tile is not sunk
				// TODO: Diver's movement....
				if(tup[1].Status != LocationStatus.Sunk) currentActions ~= new Move(p.role,p.role,tup[1],false);
				if(tup[1].Status == LocationStatus.Sinking) currentActions ~= new Shore(p.role,tup[1]);
			}

			//navigator can also move everyone else 2 spaces using their normal moves eg not the pilot speical
			//but can move the explorer in diagonals and the diver with this movement (todo)
			if(p.role.IsNavigator)
			{
				// rewrote this whole thing from functional to imperatively as its way easier and makes more sense!

				int[Tuple!(Location,Role)] processedTiles;

				foreach(player;players.filter!(x=>!x.role.IsNavigator))
				{
					Location[] firstTiles;
					foreach(tile;getAvailableTiles(player))
					{
						auto pair = tuple(tile[1],player.role);
						if(pair in processedTiles) continue;
						
						if(pair[0].Status == LocationStatus.Sunk && !player.role.IsDiver)
							continue;

						currentActions ~= new Move(p.role,player.role,pair[0],false);

						firstTiles ~= pair[0];

						processedTiles[pair] = 1;
					}

					foreach(loc;firstTiles)
					{
						foreach(tile;GetMovement(loc,player.role.IsExplorer ? allDirections : orthogonal))
						{
							auto pair = tuple(tile[1],player.role);
							
							if(		pair in processedTiles 
								 || pair[0].Status == LocationStatus.Sunk 
								 || pair[0] == player.location)
								continue;

							currentActions ~= new Move(p.role,player.role,pair[0],false);
							processedTiles[pair] = 1;
						}
					}
				}
			}

			if(p.role.IsPilot && !p.usedAbility)
			{
				// pilot can fly anywhere once per turn
				allNotSunkTiles.each!(loc => currentActions ~= new Move(p.role,p.role,loc,false));
			}

			foreach(other;players)
			{
				// everyone can give any of their artifact cards to another player if they are on the same tile	
				// (messenger can always give to anyone)
				if( p != other && (p.location == other.location || p.role.IsMessenger))
				{
					p.treasureHand
						.items
						.filter!(x=> !x.IsSandBag && !x.IsHelicopterLift)
						.each!(x=> currentActions ~= new Trade(p.role,other.role,x));
				}
			}
			
			foreach(kvp;artifactLocations.byKeyValue)
			{ 
				// have to loop here as no structural eq on DUs yet
				if(kvp.key.__tag() == p.location.__tag())
				{
					// can claim artifact if have 4 cards an on temple
					auto arti = kvp.value;
					
					string card;
					final switch(arti.__tag())
					{
						case "EarthArtifact": card = "Earth"; break;
						case "FireArtifact": card = "Fire"; break;
						case "WindArtifact": card = "Wind"; break;
						case "WaterArtifact": card = "Water"; break;
					}

					auto treasures = p.treasureHand.items.filter!(x=>x.__tag() == card).array;
					if(treasures.length >= 4)
					{
						currentActions ~= new Claim(p.role,arti);
					}
				}
			}
		}
		else
		{
			if( p.treasureCardsDrawn < 2 )
			{
				currentActions ~= new DrawTreasure(p.role);
			}
			else if(p.floodCardsDrawn < floodCardsPerTurn)
			{
				currentActions ~= new DrawFlood(p.role);
			}
		}
		return currentActions;

	}

}




// woooooo tests!

// non-shuffled island layout : 
//[
//	[null, 						null, 				 		fi.BreakersBridge, fi.CliffsOfAbandon, null, 					 		 null], 
//	[null, 						fi.LostLagoon, 		fi.MistyMarsh, 			fi.Observatory, 	 fi.PhantomRock,	 	 null], 
//	[fi.GoldGate, 		fi.SilverGate, 		fi.FoolsLanding, 		fi.IronGate, 			 fi.TempleOfTheMoon, fi.TempleOfTheSun],
//  [fi.CaveOfEmbers, fi.CaveOfShadows, fi.CoralPalace, 		fi.TidalPalace, 	 fi.HowlingGarden, 	 fi.WhisperingGarden], 
//	[null, 						fi.TwilightHollow,fi.Watchtower, 			fi.BronzeGate, 		 fi.CopperGate, 		 null], 
//	[null, 						null, 						fi.CrimsonForest, 	fi.DunesOfDeception,null, 						 null]

//]
unittest // role start locations are correct 
{
	auto fi = new ForbiddenIsland();
	auto nav = new Navigator();
	auto eng =  new Engineer();
	auto pi = new Pilot();
	auto exp = new Explorer();
	auto mes = new Messenger();
	auto div = new Diver();
	fi.initialize([nav,eng,pi,exp,mes,div],3,false);
	assert(fi.players[0].location.__tag == GoldGate.stringof ,fi.players[0].location.__tag);
	assert(fi.players[1].location.__tag == BronzeGate.stringof,fi.players[1].location.__tag );
	assert(fi.players[2].location.__tag == FoolsLanding.stringof ,fi.players[2].location.__tag );
	assert(fi.players[3].location.__tag == CopperGate.stringof ,fi.players[3].location.__tag );
	assert(fi.players[4].location.__tag == SilverGate.stringof ,fi.players[4].location.__tag );
	assert(fi.players[5].location.__tag == IronGate.stringof ,fi.players[5].location.__tag );

}

unittest // navigators movement 
{
	auto fi = new ForbiddenIsland();
	auto nav = new Navigator();
	auto exp =  new Explorer();
	fi.initialize([nav,exp],3,false);
	// check the navigator can move the explorer twice in all directions
	auto expected =
		[BronzeGate.stringof,
		 CoralPalace.stringof,
		 CrimsonForest.stringof,
		 DunesOfDeception.stringof,
		 FoolsLanding.stringof,
		 HowlingGarden.stringof,
		 IronGate.stringof,
		 TempleOfTheMoon.stringof,
		 TempleOfTheSun.stringof,
		 TidalPalace.stringof,
		 Watchtower.stringof,
		 WhisperingGarden.stringof];
	assert(
			fi.GetAvailableActions(nav)
			.filter!(x=>x.IsMove)
			.map!(x=>x.AsMove)
			.filter!(x=>x.target.IsExplorer)
			.map!(x=>x.destination)
			.array
			.sort!((x,y)=>x.__tag < y.__tag)
			.array
			.equal!((x,y)=>x.__tag == y)(expected));

}