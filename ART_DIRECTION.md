# ART_DIRECTION.md: how it looks

> **Governs every visual choice**, including things drawn in code: shaders,
> particles, UI, the lava. Not only generated PNGs. Companion to `ANIMATION.md`.

## The anchor

**Painted fantasy lit by fire and by electricity.** Visible brushwork, soft
edges, real depth. Think the painted backgrounds of a hand-animated feature
rather than a modern flat-vector indie platformer, and specifically **not** the
warm cozy register of the fishing game: this is a castle with a lava pit in it.

Two named references, to argue against rather than to copy: **Mignola's
silhouettes**, where a figure is a shape first and detail second, given a
**painted** treatment rather than flat blacks. Where those two pull apart, take
Mignola's shape and the painting's surface.

## The one rule everything else hangs off

**Every dark is a coloured dark. There is no neutral black and no neutral grey
anywhere.**

This is not a style preference carried over from the last project, it is
structural. Every light source in this game is coloured: firelight is amber,
lava is orange, the generator is cyan. A neutral black cannot receive coloured
light, so a scene painted with neutral darks goes muddy the instant a lava glow
falls across it, and the glow reads as a filter laid on top rather than as the
thing lighting the room.

Deep darks are **cold violet-blue** in stone and shadow, **warm umber** in wood
and leather. If a value is below about 15% luminance and its saturation is under
about 0.12, it is wrong. Automate this check the way the last project did.

## Palette

Descriptive first, because the generator responds to prose and not to hex. The
hex values are for the code side: shaders, UI, particles.

**Cold stone.** Everything not on fire. Blue-violet greys, damp and slightly
green in the moat, drier and more purple inside the castle.
`#3a3550` deep, `#565073` mid, `#7d7a99` lit.

**Firelight.** Braziers, torches, the hero's rim light. Amber going to
honey-cream at the source, never to white.
`#f0a63c` core, `#ffd98a` hot, `#a35a22` falloff.

**Lava.** The one saturated thing in the game and it should feel like it. A
deep clotted red crust with orange fissures and a yellow-white core where it
bubbles.
`#6b1f14` crust, `#d94f1e` flow, `#ffb64a` fissure, `#fff0c2` core.

**Steam.** A geyser's column, and the only pale thing in the game. Cool and
desaturated, because a geyser is the one hazard in the game that does not kill
you: the rule below reserves warm and saturated for what does, and a jet painted
in it would be a lie told at a glance. It must not be taken for the arc either,
which is cool but saturated and hard-edged where this is soft and low in chroma.
Lit from the lava it rises out of, so it keeps a little warmth at the vent and
loses it going up.
`#7e9bb0` body, `#cfe4ea` core.

**Spikes.** Iron, not rock. Warm and saturated, because the rule below says
anything that can kill you is, but held clearly under lava at the bright end:
lava is the one saturated thing in the game and a spike bed must not compete
with it. A dark warm body with a lit point, and the row of points carries the
reading before the hue does.
`#7a2434` iron, `#e0956f` tip.

**Electricity.** The only cool bright, and it belongs to Act 3 and to Volta.
Cyan going to white, thin and hard-edged against everything else being soft.
`#5fe0e8` arc, `#eafcff` core, `#2a6f8a` residue.

**Gold.** Gems, keys, the sword's edge, anything the player collects or uses.
Reserved. If it is gold, it is interactive.
`#e8c25a` face, `#a37c26` shade.

## Contrast is a gameplay system, not a look

In a game where one hazard kills you instantly, **readability is a rule and not
an aesthetic**. Two hard constraints:

1. **Silhouette first.** The hero, every enemy, and every interactive object must
   be identifiable as a black shape on a white field. Test it: render the room,
   threshold it, and look. If two things become one shape, one of them changes.
2. **Backgrounds lose.** Backgrounds are darker and less saturated than anything
   the player can touch. A background element may never be as bright as a
   brazier or as saturated as lava. When a room looks flat because the background
   is receding correctly, the fix is more depth in the background, never more
   brightness.

**Anything that can kill you is warm and saturated. Anything you can stand on is
cold and matte.** A player should be able to answer "can I touch that" from
colour alone, at speed, in peripheral vision.

3. **A mechanism reads as a mechanism before it is used.** Gold is reserved for
   what the player interacts with, and that reservation buys nothing if the gold
   only arrives once the thing has been operated. A switch, a brazier, a gem
   holder: each has to say what it wants while the player is still deciding, not
   confirm it afterwards. Shape carries as much of this as colour, so a
   mechanism gets a silhouette that names the verb: a slot takes a blade.

   Found by playing. M2's switch was a brown box that turned gold once a sword
   was in it, and the person who built the room could not find it.

## Outline and edge

Painted, so no uniform outline. Form is separated by **value and by edge
quality**: hard edges where a shape matters (the hero against stone), soft edges
where it does not (a distant arch). Where a shape genuinely will not separate,
the fix is a **rim light from the nearest real light source**, not a stroke.

## Scale and resolution

Design resolution 640x360, rendered at integer multiples, with the viewport
stretch set so the game is playable at 1280x720 and 1920x1080 without reflow.
Art is authored at **4x** (2560x1440 for a full-screen background) and imported
down, because the generator ignores requested pixel dimensions anyway and
downscaling a painterly asset is free while upscaling is not.

**Characters are small.** The hero is around 40 design px tall. This is the
number most likely to be wrong and it should be settled in M0 with a grey
capsule, before a single piece of art is generated against it.

## What this direction forbids

- Pure black and pure white, anywhere, including UI text and particle cores.
- Neutral greys in shadow.
- A uniform outline stroke on characters.
- Bloom as a substitute for painted light. A little is fine. Reaching for it to
  make a scene read means the values are wrong.
- Screen shake on anything except the generator boss and lava impacts. It is a
  spice and this game has a lot of impacts.
- Any UI element that competes with gold. Gold means interactive and nothing else
  gets to use it.
