# Volta Redux

A 2D puzzle platformer in Godot 4, reimagining Datasoft's *Conan: Hall of Volta*
(1984). **M3: lava kills, and dying costs under half a second.**

## What it is

The 1984 original is not a good game. Seven one-screen levels solved by
memorising a fixed sequence, jumps you cannot steer, and hazards that kill on
contact with no cheap retry. This is not a remake of it, and an earlier attempt
at one is in this repo's history.

**One mechanic in it is worth a whole game.** The boomerang sword flies out,
turns, and comes back. Catch it and you keep it. Hit a wall or an enemy and it is
gone. That is a risk and reward economy inside a single button, and this game
makes it the core verb: throw it, catch it, embed it in wood as a ledge you stand
on, recall it, and run current through it.

Volta is a unit of electric potential, and the original's boss hazard was already
an electrical generator gone haywire, so the third act is wiring.

Faithful and hard. Lava kills, spikes kill, no health bar, three swords. The
modernisation is in the cost of dying rather than the chance of it: under a
second from death to moving again.

## Where to start

**`SPEC.md`** is the source of truth, and its section *The sword is the game* is
what everything else hangs off. **`HANDOFF.md`** is the state snapshot and the
first thing to read at the start of a session.

| file | owns |
|---|---|
| `SPEC.md` | what the game is: the verb, the rooms, the enemies |
| `BUILD_PLAN.md` | M0 to M16 in four phases, each with a done-when |
| `HANDOFF.md` | where the project is right now, and what is blocked |
| `CLAUDE.md` | how to work in this repo |
| `ART_DIRECTION.md` | palette, light, treatment |
| `ANIMATION.md` | what is rigged, what is painted, and why |
| `ART.md` | how a picture gets from a prompt into the game |
| `GEMINI_NOTES.md` | how the image generator behaves |
| `BACKLOG.md` | what is deliberately not in v1 |

## Running it

Godot 4.7.2, no addons and no build step. Open the project and press play, or
drive it through one script that finds Godot on macOS and Linux for you:

```
tools/dev.sh import                              # once, after a fresh clone
tools/dev.sh play                                # the benches, F2 cycles
tools/dev.sh test                                # headless assertions
```

Set `GODOT` if it is somewhere unusual. The script wraps `godot --path .`,
`godot --path . --import` and `godot --headless --path . --script
res://tests/run_tests.gd`, so any of those still work typed out in full.

The tests are a plain script, not a framework. They find `tests/test_*.gd`, run
every method named `test_*`, and exit non-zero on a failure.

To take a screenshot from a real running build, which is the only way to check
anything visual (see `CLAUDE.md`):

```
tools/dev.sh shot res://scenes/rooms/room_m0.tscn room.png --zoom=0.38 --centre=800,180
```

`--overwrite` is required to replace an existing file. On Linux this goes
through `xvfb-run`, on macOS it does not, and `tools/capture.gd` documents
`--input` and `--until-apex` for capturing a pose mid-motion.

`--filmstrip=N` captures a transition as N frames side by side in one image,
instead of the usual single frame at the end of `--input`:

```
tools/dev.sh shot res://scenes/rooms/room_m5_wall.tscn run_to_jump.png \
  --input="move_right:40;move_right,jump:6;move_right:34" --filmstrip=8 \
  --zoom=1.2 --centre=220,290
```

This is how a crossfade or a pose transition gets reviewed without a Godot
editor session: a single screenshot cannot show a blend in progress, which is
exactly how PR #51's floating hero and PR #55's indistinct jump/fall/land got
past every earlier screenshot and were only caught by Matt playing.

## Working on it with Claude

`.claude/` carries the local workflow: `/milestone`, `/shot` and `/handoff`, a
permission allowlist so the build commands do not prompt, and two hooks that
exist because **docs go stale silently and it has cost real work**.

`session-start.sh` reads the active milestone out of `HANDOFF.md`, and warns
when the checkout is behind `origin/main` so those lines are not believed after
main has moved past them. `docs-check.sh` fires at the end of a turn and says so
when a branch has committed code without touching `HANDOFF.md`. Neither can
write a doc: they notice and they point at `/handoff`.

Personal overrides go in `.claude/settings.local.json`, which is ignored.

**Feel criteria need a human playing the game**, so Phase 1 belongs on a real
machine rather than in a cloud session. Doc passes, `scripts/logic/` work and
test writing are headless-verifiable and travel fine.

## Where the numbers live

Every value that decides how the game feels is in `config/`, and nothing in a
script sets one.

`config/movement.tres` is the settled jump: 56 px against a 96 px tier, so a
storey is climbed rather than jumped. `config/movement_strong.tres` keeps the
alternative it beat, and Tab still swaps them live because M14 retunes
everything. `config/world.tres` holds hero size and tier height,
`config/sword.tres` every number the sword obeys, and `config/death.tres` what
dying costs.

## The first attempt

A Phaser 3 remake, through 2026-08-01. It got Level 1 pixel-traced from the Sharp
X1 release, ladder climbing, coyote time, a walk cycle and a working sword throw,
then stopped one board into seven. It is deleted from `main` and kept in history:

```
git log --all -- src/
git show <sha>:src/scenes/GameScene.js
```

## Credits and references

Original game: *Conan: Hall of Volta*, Datasoft, 1984, designed by Eric Robinson
and Eric Parker.

`assets/reference/` holds 53 screenshots of the original across four platforms,
downloaded from [MobyGames](https://www.mobygames.com/game/9293/conan/) as
research. They are not traced, not ripped from, and not shipped. All rights
belong to the respective holders.
