# More world shaders

0.1.0 ships three: `dive-to-heart`, `destiny-islands`, `twilight-town`.
The `kh-shader auto` world map references several other worlds that fall
through to defaults. Each could have its own shader with a unique motif.

## Worlds with proposed concepts

### Hollow Bastion

The classic "fortress of darkness" — castle in the middle of a swirling void.

- **Concept**: imposing castle silhouette against a dark teal/violet sky
  with slow swirling negative-space (vortex) effect
- **Motion**: gentle clockwise rotation of background streaks suggesting
  the swirling void
- **Key visual**: the castle's central spire with the heartless symbol

### Traverse Town

Cozy, lit-up town at night with rain. The "first world" feel.

- **Concept**: warm cobblestone street with shop signs glowing softly. Or
  alternative: silhouetted rooftops with a few warmly-lit windows
- **Motion**: subtle window-light flicker, occasional drifting flake/spark
- **Key visual**: a hanging lantern or shop sign as the focal point

### Radiant Garden

Bright daytime castle gardens. The most peaceful KH world.

- **Concept**: sky-blue gradient with a distant white castle silhouette,
  rolling green hills suggested at the bottom edge
- **Motion**: drifting clouds (similar technique to twilight-town's cloud
  bands but cooler palette)
- **Key visual**: castle spires + cloud drift

### Space Paranoids

The Tron-inspired digital world.

- **Concept**: pure black with a vivid cyan/magenta grid receding into
  perspective. Lines on the floor suggest the digital plane
- **Motion**: grid lines pulse / scan from horizon to viewer
- **Key visual**: the geometric grid itself as the dominant element

### Other worlds worth considering

| World | Visual hook |
|-------|-------------|
| Beast's Castle | Stained-glass rose petals drifting |
| Halloween Town | Misty graveyard with jack-o'-lantern glow |
| Atlantica | Underwater caustics + floating bubbles |
| Wonderland | Whimsical playing-card silhouettes drifting |
| Olympus Coliseum | Greek columns silhouetted against orange sunset |
| Pride Lands | Savanna sunset with acacia tree silhouettes |
| Deep Jungle | Dense foliage + slow rain through canopy |
| Agrabah | Desert dunes + starry sky |

## Recipe (apply to all)

Same recipe that worked for 0.1.0:

> **One motif. Pure (or near-pure) dark base. High-contrast accent. Sparse density.**

Each shader should:
- Have ONE clearly identifiable visual that says "this world"
- NOT compete with text — keep ambient brightness low
- Animate continuously but subtly (one slow motion, not several at once)
- Be recognizable in <1 second of glance

## Implementation notes

- Reuse the helper functions from existing shaders: `hash()`, `noise()`,
  `segDist()`, `bezierDist()`, `horizonBand()`, `rectMask()`
- Always include `uv.y = 1.0 - uv.y;` at the top to flip to y-bottom convention
- Use Gaussian falloffs (`exp(-(x*x)/sigma)`), not `pow()` (Metal pipeline issue)
- No early returns inside helper functions — use `step()` masks (Metal again)
- Use canonical-arg `smoothstep` (edge0 < edge1)

## Update points

When adding a new shader, update:
- `shaders/<name>.glsl` itself
- `install.sh` SHADERS array
- `uninstall.sh` SHADERS array
- `bin/kh-shader` `WORLD_TO_SHADER` map (if applicable)
- `README.md` shader table + world map
