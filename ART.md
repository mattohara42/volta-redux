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

**The background and the tileset carry different jobs, and only one of them
is the player's path.** Found the hard way on M5's background: `SPEC.md`
rooms scroll, "a room you move through, not a screen you memorise," so a
background that paints one specific, unrepeatable view (a torch here, a
bridge there) has nothing to its left or right for the camera to pan into.
**The background is atmosphere only, designed to repeat.** The floor, the
ledge, the causeway, whatever the hero actually stands on, is tileset
geometry, placed as real Godot tiles with collision wherever a room needs
one, independent of what the background painting shows underneath it. A
background prompt should never describe a piece of walkable geometry; that
question belongs to the tileset and to room design (M10).

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

**Attempt 1, rejected.** The prompt described the wall as filling "the right
two-thirds of the frame," which is the hedged-fraction phrasing
`hook-line-and-sentence`'s `GEMINI_NOTES.md` already found unreliable for a
full scene: **"expect the prior to win on scenes."** It also never stated a
camera angle. What came back was a well-painted but dramatic three-quarter
view of a castle corner, two turrets receding into depth, a second gatehouse
visible behind them. Right palette, right mood, wrong shot for a side
scroller: nothing here reads as a flat plane a camera can pan along. A miss
in drawn content, per that same doc's rule 5, is a reroll, not a salvage.

The fix that repo already paid for: state the camera framing positively and
explicitly, "a flat side view like a stage backdrop," then name what it is
not, and anchor the wall and the waterline to the canvas edges rather than to
a fraction of the frame. `background-stream-far.png` in that repo is the
worked example this borrows from almost verbatim.

**Attempt 2, rejected.** The camera framing landed: a flat plane, no more
three-quarter corner. Measured clean against `ART_DIRECTION.md`'s
neutral-dark rule too (`palette-check.py`, 0.01% of opaque pixels). But
Matt's question cut deeper than the picture: "how is the player going to
move across the scene?" The prompt had painted a specific causeway crossing
the moat and a specific torch bracket, a single fixed view of one spot, with
nothing either side of it for a scrolling camera to pan into. That is the
mistake the new subsection above names: the background had taken on a job
that belongs to the tileset. A crenellated top edge with sky showing above
it, contradicting "rising out of frame," was a second, smaller miss in the
same delivery.

**Attempt 3, current.** Drops the causeway and the torch (both become
tileset or level-design decisions, not atmosphere), and asks for the same
wall bay to repeat three times across the canvas so the strip already reads
as a continuous run rather than one place, which is also what removes the
single-vignette framing that invited a corner view in attempt 1:

> [preamble] A wide painted background for a side-scrolling platformer: a
> long horizontal strip of a castle's outer wall, in flat side view like a
> stage backdrop, camera perpendicular to the wall, with no vanishing point.
> It is NOT a three-quarter view and NOT seen from above. The same bay of
> masonry repeats three times across the width of the canvas: a stretch of
> plain wall-face, then a narrow arrow-slit window lit faintly from within by
> warm firelight, then plain wall-face again, evenly spaced, so the whole
> strip reads as a continuous run of wall rather than one unique view of one
> spot. The wall spans the full width of the canvas and rises out of frame at
> the top: no crenellations, no visible roofline, no sky anywhere in the
> frame. A band along the very bottom of the canvas is the moat's water, its
> edge a straight horizontal line running the full width of the canvas, not
> a diagonal band and not a curve. No characters, no creatures, no causeway,
> no bridge, no torch bracket, no foreground platform geometry, no second
> building or gatehouse: this is pure atmosphere meant to repeat, not a
> picture of one specific place. Cold stone areas are blue-violet grey, damp
> and slightly green near the water, drier and more purple higher up the
> wall. Firelight in the windows is amber going to a honey-cream at its
> hottest point, never to white. The image is 2560 by 1440 pixels, aspect
> ratio 16:9.

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

**Status:** background on attempt 3, prompts 2 to 5 not yet sent. Reading
`hook-line-and-sentence` (read access, not attached, cloned locally to check
against) confirmed the fix above and turned up no other reusable technique
this project's `GEMINI_NOTES.md` didn't already carry. Prompts 2 to 5 are all
a single subject or a set of discrete modules on a flat backdrop rather than
a scene, which is the case that doc says the compositional prior has nothing
to push against, so they were left as written. Matt runs each in the Gemini
UI, saves the delivery to the path named above, and this section gets filled
in with what came back, what was measured, and whether it landed first
attempt, per generation. `tools/key.py` and `tools/palette-check.py` exist
and are smoke tested against synthetic images, ready for the first real
delivery. `tools/cut-sheet.py`, `tools/cut-rig.py` and `tools/pose-sheet.py`
are not built yet: their exact shape depends on what a real sheet actually
looks like, and building them against a guess risks getting it wrong twice.
Porting from `hook-line-and-sentence` needs that repo attached to this
session with push access, which this session's own permissions denied; Matt
can grant it directly if porting
is worth doing before a real delivery forces the question anyway.
