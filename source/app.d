import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;

void main()
{
	//writeln("Edit source/app.d to start your project.");
	DerelictSDL2.load();
  	DerelictSDL2Image.load();
  
	SDL_Init(SDL_INIT_EVERYTHING);  
    //auto _window = SDL_CreateWindow("Squirrelatron", SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_SHOWN);

	//readln();
}


