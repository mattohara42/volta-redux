# ART.md: the asset pipeline

> `ART_DIRECTION.md` owns what the art should look like. `ANIMATION.md` owns what
> moves and how. **This file owns how a picture gets from a prompt into the
> game**, and the open requests. `GEMINI_NOTES.md` owns how the generator
> behaves, and is **required reading before writing any prompt**.

## The pipeline, five steps

1. **Claude writes the prompt and the filename.** Matt generates the PNG in the
   Gemini UI and downloads it. This is the round trip and it is the expensive
   step, so a prompt that saves a generation is worth more than a tool that
   saves an hour.
2. **Key it.** Deliveries arrive as an opaque painting on a flat backdrop colour.
   `tools/key.py` floods the backdrop and writes a transparent PNG.
3. **Cut it.** One painting becomes many pieces: a sheet becomes six enemies, a
   character becomes the parts of a rig. `tools/cut-sheet.py` and
   `tools/cut-rig.py`.
4. **Rig it.** Parts become a `Skeleton2D` scene in Godot. Manual, once per
   character, and then every animation is free.
5. **Check it.** `tools/palette-check.py` against `ART_DIRECTION.md`, and a
   screenshot of the thing in the actual game.

## The four rules that came from the last project, and what they cost to learn

These were paid for in real generations on Hook, Line and Sentence. They are not
theory.

**Don't generate a piece you could cut.** A character painted holding a sword
already contains the arm, the body and the sword. Asking for three images that
then have to register with each other invents a problem the one painting does not
have. Pieces cut from one source register by construction. The whole cutting
family of tools exists for this one sentence.

**Several subjects on one canvas works, and it is the only way to ask for a
difference.** Thirty-three fish came out of eight sheets in nine generations
against an opening estimate of ninety-nine pieces. Six subjects on one canvas
worked as reliably as four. **Put the two things hardest to tell apart on the same
sheet**: a rainbow trout and a steelhead were separated correctly first attempt
when drawn against each other, having been unseparable in words.

For this project that means: **the six enemies are one sheet, not six
generations.** The scorpion and the giant ant are the pair that needs to be on it
together.

**Ask for an edit when there is already a painting to edit.** Attach the existing
painting, name the one thing that changes, and registration comes free: the
pixels that did not change are the reference's own. Nine hat deliveries came back
as faithful edits, nine times out of nine, agreement 0.945 to 0.991 below the
neck. This is how the hero gets a second costume, or an enemy gets a variant.

**Art that does not fit is a reroll, not an offset tweak.** If a delivery is
wrong in its drawn content, reroll. Salvage only featureless content: a flat
backdrop, a straight shaft, a gradient.

## The tools to build, and the four to port

The last project ended with fifteen pipeline tools and a rule about not writing a
sixteenth without reading the index. Start this one with **five**, and port what
transfers rather than rewriting it.

| tool | port or new | does |
|---|---|---|
| `key.py` | **port** the flood-fill and despill from `cut-fish.py` | delivery on a flat backdrop, out comes a transparent PNG |
| `palette-check.py` | **port whole** | judges a delivery against `ART_DIRECTION.md`. Its darks rule needs rewriting for the coloured-dark rule, its structure does not |
| `cut-sheet.py` | **port** `cut-fish.py` | one sheet, N connected components, out come N tight crops |
| `cut-rig.py` | new | one character painting, out come the rig parts. The hard one, and the closest analogue is `cut-angler.py` |
| `pose-sheet.py` | new | one 3x2 pose sheet, out come six aligned frames for a `SpriteFrames` resource. Alignment is by the figure's own bounding box, not by the grid |

**In a pipeline tool, the destructive mode is the flag.** The last project got
this backwards on `cut-angler.py` and paid for it three times: the frequent safe
cut needed an argument while the rare cut that overwrote four committed paintings
was what you got by forgetting one. Make the path that destroys work the one you
have to ask for, and let the tool refuse when nobody asked.

## Godot import settings, and the one that will bite

- **Filter: on. Mipmaps: off.** This is painterly art at 4x, downscaled. It is
  not pixel art and nearest-neighbour will make it crunchy.
- **A cut part must keep its source canvas offset**, not be trimmed to its own
  bounding box, or the rig parts will not register when they are parented. Turn
  **off** "trim alpha" in the importer for anything from `cut-rig.py`, and leave
  it on for sheet crops, which are placed by hand anyway.
- Set these in the **import defaults for the folder** (`.godot` presets), not per
  file. Three hundred assets in and a per-file setting is unfixable.

## Budget, from the last project's real numbers

The fishing game's refresh delivered 33 fish in 9 generations, 21 gear pieces in
16, and 10 junk items in 2. Sheets carried all of it.

For this game, the honest estimate:

| what | sheets | generations |
|---|---|---|
| Hero, one painting to cut into a rig | 1 | 1 to 3 (characters reroll more than objects) |
| Hero pose sheets: somersault, dive, death | 3 | 3 to 5 |
| Six enemies | 1 to 2 | 2 to 4 |
| Two bosses | 2 | 2 to 4 |
| Tilesets and props, four acts | 4 to 6 | 6 to 10 |
| Parallax backgrounds, four acts | 4 | 4 to 8 |
| **Total** | | **roughly 20 to 35** |

That is the number to sanity-check M5 against. **If the art spike takes more than
five generations for one room, the estimate is wrong and the plan needs revising
before Phase 2 continues**, not after it.

## What `assets/reference/` is for, and what it is not

53 screenshots of the 1984 original, inherited from the first attempt
(`SPEC.md` → *What the repo inherits*). **It is research, not source art.**

Use it to answer "what was actually in that board" and "what did the floating
eyeball look like" before writing a prompt. `apple2/cast-of-characters.png` and
`apple2/objects.png` are the two most useful single files.

**Never trace it, never rip from it, and never attach one of these images to a
generation request.** Attaching one asks the generator to reproduce someone
else's art, which is both the wrong output for `ART_DIRECTION.md` and the wrong
thing to do. Describe what you learned from it in words instead. The attach
mechanic in `GEMINI_NOTES.md` is for editing **our own** paintings.

## Open requests

**Where deliveries live.** Matt saves exactly what Gemini's download UI gives
him into `assets/art_raw/`, one file per generation, untouched. Pipeline output
(keyed, cut, ready to import) goes in `assets/art/`, organised by what it is
(`act1/`, `hero/`, `enemies/`). A generation that is only a technical test,
never meant to ship, stays under `assets/art_raw/_experiments/` and is never
promoted into `assets/art/`.

### M5's room: the moat and the outer wall

`SPEC.md`'s Act 1 is still "the moat and the outer wall" as of this writing.
`LEVELS.md` has an open question about whether a forest sits before or
replaces it, unresolved and explicitly not blocking anything (`HANDOFF.md`).
Painting to the settled description now is the safe call: if that question
resolves toward the forest later, this is a repaint, not wasted pipeline
learning, and `SPEC.md` is the doc that wins until it says otherwise.

Five prompts below: a background, a tileset, the hero (`SPEC.md`: "M5 paints
him"), one enemy (the bat, an Act 1-appropriate ramparts creature and the
simplest of the six to grey-box), and a throwaway test of `GEMINI_NOTES.md`'s
open question on whether a pose sheet holds one subject consistent across
frames. That question uses a placeholder subject on purpose, so a bad result
costs nothing real.

Shared preamble, prefixed to every prompt below:

> Painted fantasy game art lit by fire and by electricity, in the style of
> hand-painted backgrounds from a hand-animated feature: visible brushwork,
> soft edges, real depth. Character and creature shapes read as a strong
> silhouette first, in the way of Mike Mignola's comic art, but rendered with
> full painterly surface and value, not flat black shapes. Every dark area of
> the painting is a coloured dark: cold violet-blue in stone and shadow, warm
> umber in wood and leather. Never use a neutral black or a neutral grey
> anywhere in the image, including in shadow. Forms are separated by value and
> by edge quality, hard edges where a shape matters, soft edges where it
> recedes, never a uniform ink outline.

**1. Background**, `assets/art_raw/act1_wall_moat_bg.png`:

> [preamble] A wide painted background for a side-scrolling platformer,
> showing the base of a castle's outer wall rising from a moat, seen from
> outside at ground level. The wall's stonework fills the right two-thirds of
> the frame and rises out of frame at the top; dark, still moat water with a
> faint green tinge occupies the bottom third of the frame at the left and
> centre. A stone causeway crosses the moat from the lower-left corner toward
> the wall's base. Two or three narrow arrow-slit windows sit high on the
> wall, each lit faintly from within by warm firelight. No characters, no
> creatures, no foreground platform geometry: this is a background layer
> only, painted with atmospheric depth, coldest and least detailed furthest
> from the viewer, warmest and most detailed nearest a torch bracket at the
> wall's base. Cold stone areas are blue-violet grey, damp and slightly green
> near the water, drier and more purple higher up. Firelight is amber going
> to a honey-cream at its hottest point, never to white. The image is 2560 by
> 1440 pixels, aspect ratio 16:9.

**2. Tileset**, `assets/art_raw/act1_wall_tileset.png`:

> [preamble] A tileset sheet for a side-scrolling platformer: a flat grid of
> individual stone wall and floor modules, painted on a flat solid magenta
> (#FF00FF) backdrop, with generous even spacing between each module so they
> can be cut apart individually. Include: one wide stone floor and ledge
> module seen from the side, one narrower stone floor module about half the
> width of the first, one wall-corner module, one plain wall-face module, and
> one short iron-runged ladder set into the stone, all matching the same
> castle-exterior stonework, all painted at the same scale. Every module
> except the ladder is roughly twice as wide as it is tall; the ladder is
> roughly three times as tall as it is wide. No characters, no creatures, no
> directional lighting effects beyond the stone's own surface colour and
> texture: flat, even light on every module so they tile predictably in
> engine. Cold stone areas are blue-violet grey, drier and more purple than
> the moat's edge. The image is 2560 by 1440 pixels, aspect ratio 16:9.

**3. Hero**, `assets/art_raw/hero_lothar_idle.png`:

> [preamble] A single full-body character painting of a lone warrior for a
> side-scrolling platformer, standing in a relaxed idle pose facing right,
> viewed straight on from the side. He is a lean, broad-shouldered adult man
> in his early thirties, ordinary human proportions rather than an
> exaggerated musclebound giant or a lanky youth: a practical fighter's
> build, not a bodybuilder's. He wears simple, weathered leather and fur
> clothing in warm umber and dark hide tones, a plain rather than a heroic
> silhouette, dark shoulder-length hair, no helmet, no cape, no ornamentation
> beyond a leather belt. He holds a straight double-edged sword with a plain
> crossguard, gripped naturally in his right hand, blade pointing down and
> slightly back, exactly as someone actually holds a sword at rest, not
> presented to camera. A warm rim light catches his left side, as if lit by
> a torch just out of frame. Painted on a flat solid magenta (#FF00FF)
> backdrop, full body visible with a small even margin of backdrop on all
> four sides, nothing cropped by the frame. The image is 1536 by 2048
> pixels, aspect ratio 3:4.

**4. The bat**, `assets/art_raw/enemy_bat.png`:

> [preamble] A single creature painting of a large cave bat for a
> side-scrolling platformer, shown mid-flight with both wings spread wide,
> viewed straight on from the side, facing right. Larger than a real bat,
> roughly the size of a human torso, with a lean leathery body, clawed
> wingtips, and small sharp teeth bared. Because this creature kills on
> contact in the game, it is warm-toned and saturated rather than cold and
> matte: dark, matte, warm reddish-brown fur and a warm-brown wing membrane,
> not black, not grey. Painted on a flat solid magenta (#FF00FF) backdrop,
> full body and both wingtips visible with a small even margin of backdrop
> on all sides, nothing cropped by the frame. The image is 1536 by 1152
> pixels, aspect ratio 4:3.

**5. Pose-sheet test, throwaway**,
`assets/art_raw/_experiments/pose_sheet_test_mannequin.png`:

> A test sheet: the same plain jointed wooden practice mannequin, unpainted
> pale wood, shown in six different rotated poses, arranged in a 3-column by
> 2-row grid on a flat solid magenta (#FF00FF) backdrop, generous even
> spacing between frames so each can be cut apart individually. Each frame is
> the same figure at the same scale and the same camera distance, side view
> throughout, rotating through a full tumble from standing to inverted to
> standing. This is a technical test of whether a multi-pose sheet holds one
> consistent subject across frames, not a final asset: no scenery, no
> colour beyond the wood itself. The image is 2048 by 1365 pixels, aspect
> ratio 3:2.

**Status:** written, not yet sent. Matt runs these in the Gemini UI, saves
each delivery to the path named above, and this section gets filled in with
what came back, what was measured, and whether it landed first attempt, per
generation. `tools/key.py` and `tools/palette-check.py` exist and are smoke
tested against synthetic images, ready for the first real delivery.
`tools/cut-sheet.py`, `tools/cut-rig.py` and `tools/pose-sheet.py` are not
built yet: their exact shape depends on what a real sheet actually looks
like, and building them against a guess risks getting it wrong twice. Porting
from `hook-line-and-sentence` needs that repo attached to this session, which
this session's own permissions denied; Matt can grant it directly if porting
is worth doing before a real delivery forces the question anyway.
