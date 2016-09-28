
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.path;
import std.string;

private:
  SDL_Texture*[string] textures;

  SDL_Renderer* _renderer;
  
public:
  void SetRenderer(SDL_Renderer* renderer)
  {
    _renderer = renderer;
  }
  
  void EnsureLoaded(string key, string imagePath)
  {
     if(key !in textures)
      {
        auto surf = IMG_Load(relativePath(imagePath).toStringz);
        textures[key] = SDL_CreateTextureFromSurface(_renderer,surf);
        SDL_FreeSurface(surf);
      }
  }

  SDL_Texture* GetTexture(string key)
  {
    assert(key in textures);
    return textures[key];
  }

