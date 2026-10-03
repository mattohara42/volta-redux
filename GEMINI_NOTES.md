# GEMINI_NOTES.md: how the image generator actually behaves

> **Read this before writing any art prompt.**
>
> **Inherited, 2026-09-07.** This is the distilled carry-over from Hook, Line and
> Sentence, where every rule below was paid for with a real generation across
> roughly seventy deliveries. It has been re-scoped: the fishing-specific
> findings are dropped, the general ones are kept verbatim in substance. The
> original is at `mattohara42/hook-line-and-sentence`, `GEMINI_NOTES.md`, 705
> lines, and is worth reading in full before a hard prompt.
>
> **The generator changed on 2026-09-26**, to the Sprite Fusion API and to
> pixel art (`ART.md`). Everything below was learned on Gemini's painting
> model. Treat each rule as a hypothesis for Sprite Fusion until it has been
> tried there, and record what it does in a new section at the end.
>
> **Append to this file as this project learns things.** Its value is entirely in
> being the accumulated memory rather than the initial guess.

## Who owns what

| doc | owns |
|---|---|
| `ART_DIRECTION.md` | what the art should **look like** |
| `ART.md` | the **pipeline and the open requests** |
| **this file** | how the **generator behaves**, and how to prompt and salvage it |

## The short version

1. **Position by edges and corners, never by percentage.** Percentages are the
   least reliable thing you can ask for.
2. **Name a flat backdrop colour** rather than asking for transparency, and then
   **detect the colour you actually got**, because it will not be the one you
   asked for.
3. **State keep-outs as composition**, not as geometry.
4. **Output format and pixel dimensions are not prompt-controllable.** Ask
   anyway. Get the file from the download UI and expect a different size.
5. **A miss in featureless content is salvageable. A miss in drawn content is a
   reroll.**
6. **Check for backdrop colour bled into the subject first.** That one is never
   fixable downstream and it is the only reroll condition a noisy backdrop
   creates. A merely noisy backdrop is not.
7. **Ask for an edit when there is already a painting to edit.** Attach it, name
   the one thing that changes, and registration comes free.

## What it reliably gets right

**Aspect ratio, stated as a ratio.** Appending `Aspect ratio 16:9` is the single
most dependable instruction available. State the pixel dimensions in the body as
well ("The image is 2560 by 1440 pixels, aspect ratio 16:9"): the pixel count is
routinely ignored, the ratio holds, and it makes the prompt self-contained.

**When the ratio misses, suspect the whole frame.** The one time it failed in
seventy deliveries, the same generation had also ignored the backdrop, added
captions and changed medium. A miss on the most reliable instruction in the set
means a stronger idiom has rewritten your prompt, not that one instruction
slipped.

**Palette, described in words rather than hex.** Prose descriptions landed within
a few hex points of target repeatedly. Hex values in the prompt are not obviously
honoured and are not needed. Put `ART_DIRECTION.md`'s descriptive palette
language in the preamble of every prompt and let it do the work.

**Mood, treatment and outline weight**, from a preamble prefixed to everything.
Keep prefixing it.

**Subject exclusion, for separable objects.** "No lava, no torches" is obeyed.
It is **not** reliable for something the subject implies: a rod came back with
line threaded through it despite an explicit exclusion, because a rod has a line.
When excluding part of an object's own idiom, spend a whole flagged paragraph
naming every form it could take, and **design the downstream cut to tolerate the
violation anyway**, because the paragraph raises the odds without settling the
matter.

## Several subjects on one sheet

**The strongest result the last project had.** Eight sheets, nine generations,
thirty-three subjects, four layouts (2x2, a row of three, 3x2, and one alone).
Seven landed first attempt. Six subjects on one canvas worked as well as four and
the upper bound was never found.

**Put the two subjects hardest to tell apart on the SAME sheet.** Drawn against
each other they separate correctly; described separately in words they do not.
**A sheet is not merely a saving: it is the only way to ask for a difference
rather than describe one.**

**When two subjects cannot share a sheet, invert the pattern rather than
forbidding it.** State the mark positively first and as an inversion, then add
the negation as backup: "DARK bars on a PALE flank, the opposite of X, which has
PALE spots on a DARK flank." Ordering matters, and the general rule under it is
that **a negation needs something positive to attach to.**

**And measurably distinct is not distinct at a glance.** Two hats came back with
genuinely different silhouettes in the same colour family and one was wrongly
rejected as a duplicate. When two items in a set share a palette, give the
inversion clause a colour to work with as well as a shape. **Rejecting a good
generation costs exactly as much as accepting a bad one and is much harder to
notice afterwards.**

## A scene has a compositional prior; a subject on a flat field does not

Paid for on M5's first background. Asked for a castle wall rising from a
moat "seen from outside at ground level," the wall's stonework "filling the
right two-thirds of the frame," what came back was a well-painted but
dramatic three-quarter view of a castle corner, two turrets receding into
depth, a second gatehouse behind them. Right palette, right mood, unusable
for a side scroller: nothing in it reads as a flat plane a camera can pan
along. This is `hook-line-and-sentence`'s finding again, sharper: **a scene
has a strong compositional prior, and hedged fractions of the frame barely
move it.** A subject alone on a flat backdrop has nothing for the prior to
push against; the moment there is a scene to compose, expect the prior to
win unless the camera angle is pinned down explicitly.

**What fixed it:** state the framing positively as a concrete, seeable
thing, then name what it is not. "A flat side view like a stage backdrop,
camera perpendicular to the wall, with no vanishing point. NOT a
three-quarter view, NOT a corner where two faces meet at an angle." Anchor
the horizon or waterline to the canvas edges ("the water's edge is a
straight horizontal line running the full width of the canvas, not a
diagonal band"), not to a fraction of the frame. `ART.md`'s background
prompt, attempt 2, is the worked example.

## Editing an attached painting

Attach the painting, name the one thing that changes, and the return is a
faithful edit: no redraw, no reframe, no pose change, nine times out of nine.
Agreement below the changed region measured 0.945 to 0.991.

Three cautions that come with it:

- **The canvas comes back its own size and the aspect drifts too.** Asked
  1344x1391, got 1008x1056. A single uniform scale will not register the return.
  **Fit per axis**, on a part of the figure the edit cannot touch.
- **The drift is repeatable per reference, not random per generation.** The same
  attachment produced the same drift three and four times running. So the fit is
  correcting a stable property, and **there is no trend to read into one tighter
  or looser return.** Do not tune a prompt on a single aspect reading.
- **A faithful edit is never pixel-identical.** The generator repaints the whole
  canvas rather than compositing onto yours, so untouched linework comes back
  within a few px, visually identical, and leaves a 1 to 3 px trace of "changed"
  in any difference-based cut. **Anything reading the diff has to expect that.**
  It cost a real bug last time: a morphological close bridged the trace into a
  ring and the hole-fill painted its inside solid.

## Things it does when you do not ask

- **It fakes transparency.** Asked for a transparent background, it paints the
  editor's checkerboard as opaque pixels. Tells: a corner pixel reads alpha 255,
  and the file is much bigger than a tight sprite. Every generation picks a
  different grey pair. This is why the flat-backdrop convention exists.
- **It flattens gradients you did not insist on.** A water layer came back
  essentially one tone. Rewriting the prompt to say the gradient **is the point
  of this layer** and "do not paint it as one flat tone" took the luminance drop
  from 12 to 83. **Emphatic, named-as-the-goal phrasing works where plain
  description does not.** Relevant here for every lava surface.
- **It obeys your own preamble against you.** A `#FF00FF` backdrop came back
  `#c642b0` because the same prompt's style preamble forbade saturated colours.
  That is a prompt conflict rather than a generator failure, and it does not
  matter as long as nothing downstream assumes the exact value.
- **A shared frame can contradict the item it wraps.** Boilerplate written for
  one item in a set reads as permission when applied to another. When a template
  is filled per item, re-read the boilerplate against each item, not only the
  block that changed.

## Characters

Unlike composition, **subject description does move.** Know which kind of problem
you have before deciding what a reroll is worth.

- **A hand gripping nothing will not come back gripping.** Two rerolls went into
  describing a grip. What worked was **drawing the object in the hand** and then
  cutting the pieces apart locally. **Give it the object, then cut.** Directly
  relevant: the hero is generated holding the sword.
- **Vague age and build default to a stereotype.** "A young child" reliably came
  back as a toddler. What fixed it was all three of an age in years, the
  proportions spelled out, and the negative. Expect the same for "a barbarian",
  which has a very strong default.
- **Don't spend a reroll on placement inside the canvas.** For a rig every piece
  shares one canvas, so they can only be wrong together and a shared offset is
  absorbed once when the box is measured. Spend rerolls on the pose and the
  character.
- **A held object cropped by the frame should be extended, not tapered in.** Read
  a rod exiting the corner as a defect once and tapered it, which cost 51% of its
  length. Decide the length the object should be, then walk it out along its own
  axis, resampling the real cross-section, and **seed the taper from the measured
  width at the seam, never from a nominal constant.**
- **Scale comes from a body part, never from the figure.** The generator draws
  every pose to fill its frame, so figure height carries no world scale between
  generations: a standing figure arrived 2% taller than a seated one. Match the
  **head**.
- **Measure a complaint before you spend a reroll on it.** Of three faults called
  on one delivery, two did not survive testing: "gone flat vector" measured
  *more* tonal variation than the accepted piece. A generation costs a round
  trip, and eyes are worse than a five-line script at judging flatness, evenness
  and saturation.

## What this project will have to learn on its own

Everything above came from a game with no animation and no sheets of the same
subject. One of the two open questions this project needed to answer for
itself is settled now; the other is still open.

1. **Does the pose-sheet trick hold? Yes, tested in M5.** A throwaway sheet
   asked for one wooden practice mannequin in six rotated poses, 3x2 on a
   magenta backdrop, no scenery. `cut-sheet.py` found six clean connected
   components, and their measured stats, mean RGB and luminance per cut
   frame, landed within a few points of each other across all six: mean RGB
   channels within `(189-194, 146-151, 112-118)`, luminance mean 155-160,
   comparable to the fishing game's own four-fish-sheet finding
   (tonal stdev 26-36 across a set that measurably held). **The sheet
   finding generalises**: consistency comes free even when the six subjects
   are meant to be the same figure, not six different ones. What did not
   fully hold: "rotating through a full tumble" as a single monotonic
   sequence in reading order, two of the six poses landed as similarly deep
   inversions rather than one clean peak and a symmetric recovery either
   side of it. Doesn't matter in practice: a human curator picks the poses
   that read as the right key frames and orders them for the animation,
   the sheet's own left-to-right order was never load-bearing.
2. **How well does it hold a character across separate generations?** The last
   project never needed this: each angler was one painting. Here the hero appears
   on a rig sheet, three pose sheets and possibly a portrait. If attach-and-edit
   is the answer, every sheet after the first is an edit of the first. Still
   open: M5's rig sheet was the hero's only painting so far.

## Sprite Fusion, measured (2026-09-28)

Fourteen requests building M5's room in pixel art. Each finding below was
measured on a delivery in `assets/art_raw/`, and the request is in its
`sprite-fusion-log.jsonl`.

**Only `generate` honours `size`.** The docs say every operation returns a
16, 32 or 64 square. Measured:

| operation | asked | got |
|---|---|---|
| `generate` | 32 | 32 to 40, square |
| `generate` | 16 | 16 to 18, square |
| `edit`, two 64-73 px inputs | 32 | 44x73, 56x94 |
| `edit`, one 64 px input | 32 | 41x63, 49x91 |
| `edit`, one 32 px input | 32 | 54x64, 42x62 |
| `style-reference`, one 36 px input | 32 | 50 to 58, square |
| `direction-set`, 39 px input | 32 | 35 to 41, square |
| `direction-set`, 56x94 input | 32 | 48 to 58, square |
| `animate` | none | the input's own size |

So `edit` and `style-reference` cannot be trusted for size at all, and
`direction-set` and `animate` keep roughly what they are given.

**Re-tested 2026-09-30, after Sprite Fusion said a release had improved it**
(the support ticket on this, answered with 150 credits). Nothing had changed
yet. The same `style-reference` request as the bat, asked 32, returned 45 to
58. An `edit` of the 36 px hero, asked 32, returned one 26x36 (the input's own
crop) and one 97x143, the input scaled up four times in blocks. A `generate`
at 64 returned 64 to 77, the dragon's spread exactly. `retest_*` in
`assets/art_raw/` is that comparison set.

**Re-tested again 2026-10-03, the same three prompts, 45 credits.** The fix
has shipped for two of the three operations (`retest2_*`, contact sheet
`_experiments/retest2_contact.png`):

| operation | asked | 2026-09-30 | 2026-10-03 |
|---|---|---|---|
| `generate` | 64 | 64 to 77 | 64 on 11 of 12, one 66 |
| `edit`, 36 px hero | 32 | 26x36 and 97x143 | `size` now refused (HTTP 400, no charge); without it, 26x36 and 24x34 |
| `style-reference`, 36 px input | 32 | 45 to 58 | 58 to 71, worse |

So `generate` can now be trusted for size. `edit` keeps the input's size by
design ("Edits keep the input sprite's size; remove the size field"), which
is the behaviour M6 needed for a pose step, and both edits did the asked
change (hair tied back) on the same figure. `style-reference` still ignores
`size`, and came back bigger than before: do not use it where size matters.
`direction-set` and `animate` were not re-tested.

**`generate` still defaults to three-quarter.** 11 of 12 came back
three-quarter at size 32 even with the positive-plus-negation framing that
fixed it on Gemini. Rule 1 above holds here: a subject has a prior.

**`edit` does change a pose.** Unlike Gemini's pose-faithful edits, a
two-input `edit` ("take the pose from the first image, the look from the
second") returned a true profile both times. It is the size that fails.

**`direction-set` is the way to a side view at the right size.** Feed it a
size-correct `generate` delivery and one of its eight facings is a true
profile at that size. Index 3 faced right and index 4 faced left, on the
one run measured.

**`animate` holds identity and palette.** Four idle frames from a clean
still came back with 0 neutral-dark pixels and the same silhouette, with
the feet's outline fixed across frames. What moves inside the boots is a
little shading, 5 to 14 of about 64 pixels per frame: small boiling, to be
judged by eye at game size rather than argued.

**Tiles repeat about half the time.** `generate` makes single sprites, not
tilesets, but tiling each of 12 variations 4x4 showed several seamless ones
per request. Choosing among them was enough; no hand fix was needed.

**Outlines land just inside the neutral-dark band.** A few percent of
pixels, on a few deliveries, all fixable by `tools/recolour-darks.py`.

**`media.spritefusion.com` answers 403 to urllib's default User-Agent**,
and animated previews come back as WebP, which Godot 4.7 cannot decode.
The spritesheet PNG next to it is what the game uses.

**`animate` straight from the idle still covers most actions**, with no pose
step first (M6, 2026-09-28). Run, jump, land, throw, catch and die all came
back as the named motion at the still's size, in the same character. Three
things to know:

- **Frame 0 is always the still.** Every clip starts from the input pose, so
  a loop or a pose hold uses frames 1 onward.
- **A held pose does not animate.** "Falling, holding the pose" came back as
  four copies of the still. The fall uses the jump's last, tucked frame.
- **A death may flash pure white** for two frames. Dropped: pure white is
  forbidden, and the Player's lava tint already marks the hit.

**A side-view ladder climb reads as walking.** The back view from the same
`direction-set` run, animated, reads as climbing, and it is the same
character because both came from one request.

**`animate` will rotate a body if the prompt says so and asks for enough
frames.** An 8-frame "forward somersault, rotating further in every frame"
came back as a full flip: spring, tuck, inverted, tumble, open. Frame 0 is still
the input pose, and the tucked frames stay inside the 36 px canvas because the
still was compact.

