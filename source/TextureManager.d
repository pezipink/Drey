import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.path;
import std.string;

struct SDLTextureManager
{
private:
  SDL_Texture*[string] textures;

  SDL_Renderer* renderer;
  
public:
  this(SDL_Renderer* renderer)
  {
    this.renderer = renderer;
  }
  
  void EnsureLoaded(string key, string imagePath)
  {
     if(key !in textures)
      {
        auto surf = IMG_Load(relativePath(imagePath).toStringz);
        textures[key] = SDL_CreateTextureFromSurface(renderer,surf);
        SDL_FreeSurface(surf);
      }
  }

  SDL_Texture* GetTexture(string key)
  {
    assert(key in textures);
    return textures[key];
  }
}
