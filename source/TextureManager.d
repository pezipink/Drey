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
      import std.stdio;
    }
}

void ReplicateAsTargetTexture(string source, string dest)
{
  assert(source in textures, "source key " ~ source ~ " was not found in texture map");
  assert(dest !in textures, "dest key " ~ dest ~ " was not found in texture map");
  Uint32 format;
  int access;
  int w;
  int h;
  SDL_QueryTexture(textures[source],&format,&access,&w,&h);
  textures[dest] = SDL_CreateTexture(_renderer,format,SDL_TEXTUREACCESS_TARGET,w,h);
  return;
}

SDL_Texture* GetTexture(string key)
{
  assert(key in textures);
  return textures[key];
}

