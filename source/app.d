import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;
static immutable int fps = 60;
static immutable float delay_time = 1000.0 / fps;
static immutable screen_width = 640;
static immutable screen_height = 480;
SDL_Window* _window;
SDL_Renderer* _renderer;
SDL_Surface* _scr;
SDL_Texture* _scrTex;

void main()
{
	 
	  DerelictSDL2.load();
  	DerelictSDL2Image.load();
  
	  SDL_Init(SDL_INIT_EVERYTHING);  
    auto _window = SDL_CreateWindow("Drey", SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_SHOWN);



    _scr = SDL_CreateRGBSurface(0, 640, 480, 32,
                                        0x00FF0000,
                                        0x0000FF00,
                                        0x000000FF,
                                        0xFF000000);
    _scrTex = SDL_CreateTexture(_renderer,
                                            SDL_PIXELFORMAT_ARGB8888,
                                            SDL_TEXTUREACCESS_STREAMING,
                                            640, 480);
  
	//readln();
}

void render(){
  SDL_UpdateTexture(_scrTex, null, _scr.pixels, _scr.pitch);
  SDL_RenderClear(_renderer);
  SDL_RenderCopy(_renderer, _scrTex, null, null);
  
  // the rest of the shit is drawn via the renderer like normal
 
   SDL_RenderPresent(_renderer);
}