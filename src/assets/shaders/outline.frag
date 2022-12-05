extern int width;
extern vec4 color;

vec4 effect(vec4 vcolor, Image texture, vec2 tc, vec2 pc) {
  vec4 t = Texel(texture, tc);
  float x = 1/love_ScreenSize.x;
  float y = 1/love_ScreenSize.y;

  float a = 0.0;
  for (int i = -width; i <= width; i++) {
    for (int j = -width; j <= width; j++) {
      a += Texel(texture, vec2(tc.x + i*x, tc.y + j*y)).a;
    }
  }
  a = min(a, 1.0);

  return vec4(color.rgb, color.a*a);
}
