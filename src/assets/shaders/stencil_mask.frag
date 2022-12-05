vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
  vec4 t = Texel(texture, tc);
  if (t.a == 0.0) {
    discard;
  }
  return t;
}
