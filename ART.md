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

**Landed.** Three even bays, flat plane, no vanishing point, no crenellations,
no sky, no causeway, no torch. `palette-check.py`: 0.01% of opaque pixels
neutral-dark, clean. Delivered 1376x768 (ratio 1.792 against the requested
1.778), the usual pixel-dimensions-ignored-ratio-held pattern. Saved as
`assets/art_raw/act1_wall_moat_bg.jpg` (the raw delivery) and
`assets/art/act1/wall_moat_bg.png` (converted, no keying needed since it's a
full opaque painting, nothing else to do to it).

**Generation count, this asset: 3.** That is three of the five `ART.md`'s
own budget rule allows for the *whole room* before it says stop and revise
the plan rather than push on. Tileset, hero, bat and the pose-sheet test are
still unsent; even a clean first-attempt landing on all four puts M5 at 7.
Flagging this now rather than after the fact: whether to keep going and
treat the trigger as informative-not-a-hard-stop, or pause here and think
about it, is Matt's call.

**Running total after the tileset: 4 generations, 2 of 5 assets landed.**
The tileset landed first attempt, so it added exactly 1. Two assets in, at
an average of 2 generations each; hero, bat and the pose-sheet test remain.

**Running total after the hero: 6 generations, 3 of 5 assets landed.** The
hero took 2 (one rejected on pose, one landed). That's past the budget
rule's own ceiling of 5 for the whole room, with the bat and the
pose-sheet test still to come. Still not treated as a hard stop, each of the
three misses so far bought a real, reusable lesson rather than being wasted,
but it's worth naming plainly rather than letting the count go unremarked.

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

**Landed first attempt, with a bonus.** Eight modules came back instead of
the five asked for (an extra plain wall-face, an extra window wall, and the
narrower floor module reads closer to the same width as the first than
"about half"), all consistent stonework, all clean on a flat magenta
backdrop with generous gutters. `palette-check.py` on the keyed sheet: 0.01%
neutral-dark. Saved as `assets/art_raw/act1_wall_tileset.jpg` (raw) and, once
cut, `assets/art/act1/tiles/wall_tile_1.png` through `_8.png`, in reading
order (top row left to right, then the next row).

**Found a real bug in `key.py` cutting this one.** The despill from M5's
first build only pulled colour back within a 3px ring, on the theory that
the antialiased seam was a thin fringe. It is not: measured on this real
delivery, backdrop colour was still visibly present 6 to 7px into the kept
pixels (pixel-by-pixel: `(169,5,146)` a single pixel in, still
unmistakably magenta at 6px, clean stone by 8 to 9px). A partial pull that
close to the seam left an obvious magenta halo around every module, visible
at a glance, exactly the "noisy backdrop bled into the subject" failure
`GEMINI_NOTES.md` calls the one kind of miss that is never fixable
downstream. Rewrote `key.py`'s decontamination: every kept pixel within
`--ring` (default 10px) of the cut is now replaced outright with its
nearest clean neighbour's colour, via `scipy.ndimage.distance_transform_edt`,
rather than partially corrected. Re-verified against both the original
synthetic test and this real delivery: zero backdrop colour remains in
either.

**`tools/cut-sheet.py` is built**, to the shape `ART.md` guessed at before a
real sheet existed: connected components of the keyed alpha channel, sorted
into reading order by vertical-span overlap (robust to whatever the actual
grid spacing turns out to be, rather than a fixed pixel bucket), each
cropped tight and numbered. Worked first run against this delivery: 8
components in, 8 modules out, in the right order.

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

**Attempt 1, rejected.** Palette measured clean, but the pose did not read
as a true side view: both shoulders and most of the chest were visible, and
the near leg overlapped the far leg the way it does in a three-quarter
stance. "Viewed straight on from the side" alone was not enough to beat the
generator's default toward a three-quarter fantasy-portrait stance, the same
compositional-prior problem the background hit, showing up on a character
instead of a scene. This one mattered more than the earlier misses:
`ANIMATION.md` is explicit that "a cutout rig cannot sell a full-body
rotation, flat parts seen edge-on are flat parts," so a foreshortened limb
in the source painting would have looked wrong the moment `Bone2D` rotated
it, not just in a still.

**Attempt 2, landed.** Same fix as the background: state the side view
positively and concretely, then rule out the three-quarter default by name.

> [preamble] A single full-body character painting of a lone warrior for a
> side-scrolling platformer, standing in a relaxed idle pose. This is a true
> side view, an orthogonal profile as if traced from directly beside him:
> his whole body faces right, shoulders stacked directly in line with his
> hips, one flank of his body fully hidden behind the other. It is NOT a
> three-quarter view: his chest, both shoulders and both legs must NOT be
> visible at once, only the near side of his body reads at all. He is a
> lean, broad-shouldered adult man in his early thirties, ordinary human
> proportions rather than an exaggerated musclebound giant or a lanky youth:
> a practical fighter's build, not a bodybuilder's. He wears simple,
> weathered leather and fur clothing in warm umber and dark hide tones, a
> plain rather than a heroic silhouette, dark shoulder-length hair, no
> helmet, no cape, no ornamentation beyond a leather belt. He holds a
> straight double-edged sword with a plain crossguard, gripped naturally in
> his near hand, blade pointing down and slightly back, exactly as someone
> actually holds a sword at rest, not presented to camera. A warm rim light
> catches his far side. Painted on a flat solid magenta (#FF00FF) backdrop,
> full body visible with a small even margin of backdrop on all four sides,
> nothing cropped by the frame. The image is 1536 by 2048 pixels, aspect
> ratio 3:4.

Landed a true profile: shoulders stacked, one leg mostly hidden behind the
other, the flat side view a cutout rig needs. `palette-check.py`: 0.00%
neutral-dark. Two small extras beyond the brief, a chest strap and a second
hilt or pouch at the hip, when the prompt said "no ornamentation beyond a
leather belt": not worth a third generation over. Saved as `assets/art_raw/
Lothar1.jpeg` (Matt's own filename, uploaded directly to the branch after
this session's file-attachment path failed twice, an environment issue
rather than anything about how it was sent) and `assets/art/hero/
lothar_idle.png` (keyed, decontamination verified clean at the cut edge
by hand).

**`tools/cut-rig.py` is built**, against this real painting, and it is a
different shape of tool from `cut-sheet.py`. A sheet has a backdrop between
every module for connected-components to find; a character painting is one
continuous shape with no seam between an arm and a torso, so a part is a
named rectangle read off the painting by eye, not detected. Five parts cut
clean: `head`, `torso`, `arm_near`, `leg_near`, `leg_far` (`assets/art/hero/
rig/`), matching `ANIMATION.md`'s own rig granularity for a run cycle,
"hips, two legs, two arms, head", minus the far arm, which this true
profile hides entirely.

**The sword is not one of the rig parts, on purpose.** `CLAUDE.md`: "the
sword is one scene and one script." The blade in this painting was there so
the hand would come back actually gripping something (`GEMINI_NOTES.md`:
"a hand gripping nothing will not come back gripping... give it the object,
then cut"), not to be a reusable sword asset. That mattered for the box
shapes too: the blade crosses diagonally in front of the legs, so any
rectangle wide enough to hold the grip *and* the tip also swept in both
boots, since a crop is axis-aligned and can't tell a blade pixel from a
boot pixel sitting in the same rectangle. Stopping `arm_near`'s box at the
fist sidesteps the worst of it. A small blade sliver still landed inside
`leg_far`'s box regardless, the same geometry problem at a smaller scale;
cleared by colour rather than chased with tighter geometry, since the blade
reads as a distinctly low-saturation, mid-to-high-value grey against warm
brown leather, easy to threshold and mask without touching the boot under
it. Checked by eye against a red-marked preview before applying, so the
mask wasn't trusted blind.

**`draw the thing you measured` caught a real bug here, not just the
sliver.** The first attempt at avoiding the blade problem pushed `leg_near`
and `leg_far`'s top edge down to clear it, and it worked, no more blade in
either crop. What it also did was leave a gap: the torso's box ends where
its own content does, and the legs' new top edge started below that, so a
band of hip and upper thigh that belongs to neither box was never cut at
all. Invisible in each part looked at alone; obvious the moment all five
parts were composited back onto one canvas at their recorded offsets, which
is exactly why that reassembly check is worth doing before trusting a set
of rig parts, not after. Fixed by moving the legs' top edge back up to meet
the torso's bottom edge exactly, and clearing the blade sliver by colour
instead of by geometry.

**Boxes are allowed to overlap where two parts meet**, deliberately: the
torso's box and the arm's box both contain some of the same shoulder
pixels, and that's fine, because a keyed crop's untouched area is
transparent, not blank. Draw the parts back to front in Godot in the order
they're layered in the source painting, torso, then legs, then the arm on
top, and the overlap is invisible: only the topmost part's pixels show
where two boxes cover the same spot.

**That manual step happened too: `scenes/hero_rig.tscn` is a real
`Skeleton2D`.** `Hip` is the root `Bone2D`, with `Torso` as its direct
`Sprite2D` child; `HipFar`, `HipNear`, `Shoulder` and `Neck` are child bones
each carrying one more part. Every bone's position and every sprite's
position (`centered = false` throughout) is set so the rest pose reproduces
the source painting exactly: a bone at absolute canvas point `P`, a sprite
whose crop offset is `Q`, gets local position `Q - P`. `scenes/
hero_rig_test.tscn` wraps it with a `Camera2D` for `tools/dev.sh shot` to
frame, since `capture.gd`'s `--zoom`/`--centre` only drive a camera it finds
under something in the "player" group, and this scene has no player.

**Caught a real bug before it reached Godot, not after.** The first
attempt at the leg boxes (see above) left a gap between the torso's bottom
edge and the legs' new top edge, invisible looking at any one part alone.
Compositing all five parts back onto one canvas at their recorded offsets
in plain PIL, before touching Godot at all, showed it immediately: a band
of missing hip and thigh. `CLAUDE.md`'s "draw the thing you measured" is
the reason this check happened before the scene was built rather than
after, and it is worth doing every time a set of rig parts is cut, not just
this once.

**A real Godot 4.7.2 engine quirk showed up too, confirmed harmless.**
Every leaf `Bone2D` (one with no `Bone2D` child of its own, `HipFar`,
`HipNear`, `Shoulder` and `Neck` here) logs "cannot calculate bone length or
angle reliably" followed by an `ERROR: Condition "det == 0" is true" from
`affine_invert`, on load, every time, regardless of `position`, `rest`,
`length`, `bone_angle` or `autocalculate_length_and_angle`. Reproduced in a
three-line scene with nothing but a `Skeleton2D`, one root bone and one leaf
bone, so it is not this rig's structure at fault: `Bone2D.rest` defaults to
`Transform2D(0, 0, 0, 0, 0, 0)`, a degenerate transform, and Godot's own
internal bone-length auto-calculation tries to invert it for any bone with
no child bone to infer a length from. The picture renders correctly despite
it (verified: `tools/dev.sh shot` output, byte-identical figure to the PIL
reassembly), and `capture.gd` still exits 0 and writes the PNG, so it is
log noise, not a functional break. Worth knowing before someone spends an
hour on it thinking it's a rig bug.

**This was run against a real Godot, not just written and hoped for.** No
Godot was installed in this session's environment; the official 4.7.2 Linux
binary (matching `README.md`'s pinned version) was downloaded to `/tmp` to
actually run `tools/dev.sh import`, `test`, and `shot`. That download does
not persist between sessions in this kind of environment, so a future
session here starts the same way: no `$GODOT`, fetch the binary before
trusting anything Godot-shaped it writes.

**4. The bat**, `assets/art_raw/enemy_bat.png`:

**Revised before sending, not after a miss.** The original wording said
"viewed straight on from the side" once and left it at that, the same
hedge that cost the background one reroll and the hero another: a subject
description without an explicit positive-plus-negation framing barely
moves the generator's default. "Mid-flight, both wings spread wide" is
exactly the kind of dynamic pose that invites a dramatic angle the way the
hero's idle stance did. Applying the fix that already worked twice, before
paying for a third rejection to relearn it:

> [preamble] A single creature painting of a large cave bat for a
> side-scrolling platformer, shown mid-flight with both wings spread wide.
> This is a true side view, an orthogonal profile: the bat's body faces
> right and both wings spread within the picture plane, seen edge-on and
> flat, not foreshortened by any tilt toward or away from the camera. It is
> NOT a three-quarter view and NOT seen from above or below. Larger than a
> real bat, roughly the size of a human torso, with a lean leathery body,
> clawed wingtips, and small sharp teeth bared. Because this creature kills
> on contact in the game, it is warm-toned and saturated rather than cold
> and matte: dark, matte, warm reddish-brown fur and a warm-brown wing
> membrane, not black, not grey. Painted on a flat solid magenta (#FF00FF)
> backdrop, full body and both wingtips visible with a small even margin of
> backdrop on all sides, nothing cropped by the frame. The image is 1536 by
> 1152 pixels, aspect ratio 4:3.

**Delivered, palette clean, and the pre-emptive fix didn't fully hold.**
`palette-check.py`: 0.00% neutral-dark. But the pose is still a dynamic
swoop, not the flat orthogonal profile asked for: the head shows both ears
and a near-frontal muzzle, the body's long axis is diagonal, and the two
wings are spread at different angles rather than symmetrically in-plane.
The explicit "NOT a three-quarter view" that landed the hero on its second
attempt didn't fully override the generator's default here; a creature
"mid-flight, wings spread" carries an even stronger prior toward a dynamic
action shot than a standing human idle pose did.

**Found and fixed a real bug in `key.py` cutting this one, more serious
than the tileset's.** The bat's wing membranes have thin gaps between the
finger-bones, and its bared teeth leave gaps in the mouth: backdrop colour
trapped in those enclosed pockets measured `(239, 36, 240)` against a
detected backdrop of `(243, 46, 248)`, indistinguishable from the real
thing, and `key.py`'s border-seeded flood fill never reached it, because
nothing connects an enclosed pocket to a border seed. The result was solid
magenta patches baked into every rig-part crop as fully opaque "subject"
pixels. Rewrote `key.py` to match the backdrop colour globally, anywhere in
the frame, rather than flooding from the border: this project's palette
(`ART_DIRECTION.md`) has nothing naturally near a saturated magenta, so a
global match has no real subject to false-positive on. Re-checked every
already-committed asset (the hero's rig parts, the tileset tiles, the
hero's full painting) against the new tool: all clean, the bug's actual
damage was confined to this one delivery. A last few sub-pixel specks
remain at extremities (claw tips, an ear notch, under 50px total across the
whole image) where the antialiasing never produces a pixel close enough to
either colour to classify cleanly; noted rather than chased, since no
reasonable tolerance fixes a gap smaller than a pixel's own blend.

**Not cut into final rig parts or committed as a finished asset yet.** The
pose question is a judgment call this file shouldn't make alone: whether
the dynamic swoop actually matters for a creature whose own behaviour is
erratic flight (`SPEC.md`'s bat row), given its rig is only a body and two
independently-rotating wings rather than the hero's limb chain, or whether
it's worth a third generation to get a calmer profile. Test-cut into
`body`/`wing_left`/`wing_right` in scratch to check the question is
answerable at all: individually, both wings read as reasonably flat,
usable shapes regardless of the dynamic overall pose.

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

**Status:** background, tileset and hero landed (attempts 3, 1 and 2
respectively), bat delivered but not yet accepted (7 generations total),
pose-sheet test not yet sent. The bat's pose is a genuine judgment call
flagged above for Matt rather than decided here. Reading `hook-line-and-sentence` (read access, not attached, cloned
locally to check against) confirmed the camera-framing fix and turned up no
other reusable technique this project's `GEMINI_NOTES.md` didn't already
carry, and that same fix, restated for a character rather than a scene, is
what landed the hero. `tools/key.py` and `tools/palette-check.py` are built
and proven against three real deliveries now, not just synthetic ones;
`key.py`'s decontamination got a real fix along the way (see the tileset
write-up above). `tools/cut-sheet.py` and `tools/cut-rig.py` are both built
and proven, against the real tileset sheet and the real hero painting
respectively. **The hero is rigged in Godot now too**: `scenes/
hero_rig.tscn`, a real `Skeleton2D`, verified by an actual screenshot
against a real build, not just written and assumed correct. M5's "one
rigged hero" is done. `tools/pose-sheet.py`
is still not built: the pose-sheet test delivery is what will tell us its
real shape. Porting from `hook-line-and-sentence` needs that repo attached
to this session with push access, which this session's own permissions
denied; Matt can grant it directly if porting is worth doing, though the
tools built fresh so far have
each worked first try against a real delivery.
