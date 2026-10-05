## Every sound the game makes that is not the sword's own, and how loud the
## two halves of the mix sit. The sword's sounds are `SwordConfig`'s, beside
## the numbers they describe.
##
## Every stream here is rendered from code by `tools/synth/render.py`
## (`assets/audio/README.md`), so a sound changes by changing its recipe and
## re-rendering, and this file only says which file plays when.
class_name AudioConfig
extends Resource

@export_group("Mix")
## The music and the effects buses, in decibels. 0 is the rendered level.
@export_range(-60.0, 6.0) var music_volume_db: float = -9.0
@export_range(-60.0, 6.0) var sfx_volume_db: float = -3.0
## How long one act's music takes to give way to the next, seconds.
@export var music_fade_seconds: float = 1.5
## A death muffles the music under the hold and the respawn, this many seconds.
@export var death_muffle_seconds: float = 0.6
## How far each play of a frequent sound may wander in pitch, as a fraction,
## so twenty jumps in a row are not one sample twenty times.
@export_range(0.0, 0.2) var pitch_jitter: float = 0.05

@export_group("The hero")
@export var jump: AudioStream
@export var land: AudioStream
@export var flip: AudioStream
@export var die: AudioStream
@export var respawn: AudioStream

@export_group("The room")
@export var brazier: AudioStream
@export var chest: AudioStream
@export var kill: AudioStream
@export var gem: AudioStream
@export var gem_set: AudioStream
@export var switch: AudioStream
@export var gate: AudioStream
@export var zap: AudioStream
@export var geyser: AudioStream
@export var crumble: AudioStream

@export_group("The bosses")
@export var roar: AudioStream
@export var short: AudioStream
@export var bolt: AudioStream
@export var pull: AudioStream

@export_group("Between acts")
@export var card: AudioStream
