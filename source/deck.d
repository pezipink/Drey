module deck;
import std.traits : isAbstractClass, isFinalClass;
import std.typetuple;

struct Quantity { int amount; }

alias helper(alias T) = T;

// template Parent(Class) if (is(Class == class))
// {
//     static if (is(Class Parent == super))
//         alias Parent = TypeTuple!(Parent);
//     else 
//     	alias Parent = TypeTuple!();
// }

template GetQuantity(T) 
{
	enum GetQuantity()
	{
		foreach(attr; __traits(getAttributes, T))
			static if(is(typeof(attr) == Quantity))
				return attr.amount;
		assert(0);
	}
}

struct Deck(T)
{
	import std.array : insertInPlace;
	import std.random : randomShuffle;
	import std.algorithm : filter;
	import std.traits : isIterable;

	T[] items;

	@property int length() { return items.length; }

	this(T[] items)
	{
		this.items = items;
	}

	this(Range)(Range r)
		if (isIterable!Range) 
	{
		foreach(i;r) items ~= i;
	}

	void shuffle() 
	{
		items.randomShuffle();
	}

	void placeTop(T item) 
	{
		items ~= item;
	}

	void placeTop(T[] items) 
	{
		this.items ~= items;
	}

	void placeBottom(T item)
	{
		items.insertInPlace(0,item);
	}

	void placeBottom(T[] items)
	{
		this.items.insertInPlace(0,items);
	}


	auto draw(int n) 
	in { assert(n <= items.length); } body
	{
		auto ret = items[0..n];
		items = items[n..$];
		return ret;
	}

	auto drawSingle(T toFind) 
	{
		int index = -1;
		for(index=0; index<items.length; index++)
		{
			if(items[index] == toFind)
			{
				break;
			}
		}

		assert(index > -1);
		assert(index < items.length);

		T item = items[index];

		if(index == 0)
		{
			items = items[1..$];
			
		}
		else if(index == items.length -1)
		{
			items = items[0..$-1];
		}
		else
		{
			items = items[0..index] ~ items[index+1..$];
		}
		return item;
	}
	auto drawSingle() 
	in { assert(1 <= items.length); } body
	{
		auto ret = items[0];
		items = items[1..$];
		return ret;
	}

	alias items this;
}

unittest 
{
	import std.stdio;
	import std.random;

	auto d = Deck!string();
	d.placeBottom("hello");
	assert(d.items == ["hello"]);
	d.placeTop("world");
	assert(d.items == ["hello","world"]);
	assert(d.draw(1) == ["hello"]);
	assert(d.items == ["world"]);
	d.placeTop("john");
	d.placeTop("dave");
	assert(d.draw(d.items.length) == ["world","john","dave"]);
	d.placeTop("john");
	d.placeTop("dave");	
	d.placeTop("john");
	assert(d.drawSingle("john") != null );
	assert(d.items.length == 2);
	d.placeTop("john");
	d.placeTop("dave");	
	d.placeTop("john");
	d.placeTop("dave");	
	assert(d.drawSingle("dave") != null);

}	



struct DeckPair(T)
{
	Deck!T active_deck;
	Deck!T discard_deck;

	auto draw(int n) 
	in { assert(n <= active_deck.length + discard_deck.length); } body
	{
		if(active_deck.length >= n)
		{
			return active_deck.draw(n);
		}
		else
		{
			auto temp = active_deck.draw(active_deck.length);
			auto swap = active_deck;
			active_deck = discard_deck;
			discard_deck = active_deck;
			discard_deck.shuffle();
			return temp ~ active_deck.draw(n-temp.length);
		}
	}

	auto shuffle()
	{
		active_deck.shuffle();
	}

	auto shuffle_discard()
	{
		discard_deck.shuffle();
	}

	auto drawSingle() 	
	{
		return draw(1)[0];
	}

	auto merge()
	{
		active_deck.items =  discard_deck.items ~= active_deck.items;
		discard_deck.items = [];
		return this;
	}

	auto discard(T item)
	{
		discard_deck.placeTop(item);
	}


}

