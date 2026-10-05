"""Every sound effect in the game, as a recipe.

`BUILD_PLAN.md` M15: "the throw, the catch, the embed and the recall need four
distinguishable sounds, because the sword's state is information the player
needs without looking." So those four are built to differ in every way an ear
sorts sounds: the throw is noise moving upward and away, the catch is a short
bright ring, the embed is a low knock with the blade humming after it, and the
recall is a rising shimmer. The fly loop is what says where a sword is while it
is in the air, panned by the engine as it moves.

Each recipe returns mono float samples. `render.py` writes them.
"""

import numpy as np

from dsp import (
    SR, adsr, bandpass, decay, delayed, fade, fm, highpass, inharmonic, lowpass,
    mix, noise, normalise, one_pole, osc, pad_to, samples, soft_clip, sweep, time,
    vibrato,
)


# The sword: the four that must never be mistaken for each other.

def throw():
    """A whoosh leaving the hand, with a short scrape of steel at the start."""
    dur = 0.24
    air = noise(dur, seed=1)
    centre = sweep(700.0, 2600.0, dur)
    whoosh = bandpass(air, centre, q=3.5) * adsr(dur, attack=0.05, decay=0.07, sustain=0.45, release=0.12)
    shing = inharmonic(2400.0, [1.0, 1.47, 2.09], 0.12, [0.03, 0.02, 0.012], seed=2) * 0.3
    return fade(mix(whoosh * 1.5, shing))


def catch():
    """The hilt landing in the palm: a thump and a short bright ring."""
    dur = 0.22
    thump = osc("sine", sweep(180.0, 90.0, 0.06), 0.06) * decay(0.06, 0.02)
    ring = inharmonic(1320.0, [1.0, 2.0, 2.76, 4.07], dur, [0.09, 0.06, 0.035, 0.02], seed=3)
    tick = highpass(noise(0.015, seed=4), 3000.0) * decay(0.015, 0.004)
    return fade(mix(thump * 0.9, ring * 1.1, tick * 0.4))


def embed():
    """The blade biting wood: a low knock, a crack of grain, then the blade
    humming in the wall."""
    dur = 0.42
    knock = osc("sine", sweep(210.0, 70.0, 0.09), 0.09) * decay(0.09, 0.03)
    crack = bandpass(noise(0.05, seed=5), 1800.0, q=1.2) * decay(0.05, 0.012)
    hum_f = vibrato(190.0, dur, rate=24.0, depth=0.02)
    hum = lowpass(osc("saw", hum_f, dur), 900.0) * decay(dur, 0.12) * 0.35
    return fade(mix(knock * 1.2, crack * 0.8, delayed(hum, 0.01)))


def recall():
    """Called home: a shimmer rising, and a pull under it."""
    dur = 0.42
    t = time(dur)
    rise = sweep(500.0, 1500.0, dur)
    shimmer = osc("sine", rise, dur) * (0.6 + 0.4 * np.sin(2 * np.pi * 28.0 * t))
    octave = osc("sine", rise * 2.0, dur) * 0.3
    pull = bandpass(noise(dur, seed=6), sweep(300.0, 1200.0, dur), q=3.0) * 0.6
    env = adsr(dur, attack=0.12, decay=0.1, sustain=0.8, release=0.16)
    return fade(mix(shimmer, octave, pull) * env)


def fly_loop():
    """A sword turning over in the air, seamless when looped: a soft
    whirr, rising and falling twice a revolution. The engine pans it."""
    revolutions = 6
    rate = 14.0 / (2 * np.pi) * 2.0
    dur = revolutions / rate
    t = time(dur)
    air = pad_to(bandpass(noise(dur, seed=7), 1500.0, q=1.0), dur)
    pulse = 0.55 + 0.45 * np.cos(2 * np.pi * rate * t)
    tone = osc("sine", 620.0, dur) * 0.08
    loop = (air * pulse + tone)
    # Crossfade the end into the start so the seam has nothing to click on.
    edge = samples(0.03)
    loop[:edge] = loop[:edge] * np.linspace(0, 1, edge) + loop[-edge:] * np.linspace(1, 0, edge)
    return loop[:-edge] * 0.8


def break_():
    """A sword spent on stone or chitin: a clang and the pieces going."""
    dur = 0.5
    clang = inharmonic(620.0, [1.0, 1.58, 2.37, 3.11, 4.4], dur, [0.18, 0.12, 0.08, 0.05, 0.03], seed=8)
    burst = highpass(noise(0.12, seed=9), 2000.0) * decay(0.12, 0.03)
    tinkle = mix(
        delayed(inharmonic(3100.0, [1.0, 1.31], 0.08, [0.03, 0.02], seed=10), 0.07),
        delayed(inharmonic(3700.0, [1.0, 1.27], 0.08, [0.025, 0.02], seed=11), 0.13),
    )
    return fade(mix(clang * 1.2, burst * 0.6, tinkle * 0.5))


def clatter():
    """A missed sword hitting the floor and lying still."""
    hits = []
    for i, (at, base) in enumerate([(0.0, 880.0), (0.07, 1040.0), (0.12, 760.0)]):
        hit = inharmonic(base, [1.0, 1.9, 2.7], 0.12, [0.04, 0.025, 0.015], seed=20 + i)
        hits.append(delayed(hit * (1.0 - 0.3 * i), at))
    thud = lowpass(noise(0.05, seed=30), 600.0) * decay(0.05, 0.015)
    return fade(mix(*hits, thud * 0.8))


def fry():
    """A sword crossing a live barrier and going up in it."""
    dur = 0.35
    buzz = osc("square", 110.0 + 40.0 * noise(dur, seed=31), dur, width=0.3)
    buzz = bandpass(buzz, 1400.0, q=0.9) * decay(dur, 0.1)
    crackle = highpass(noise(dur, seed=32), 2500.0) * (np.random.default_rng(33).random(samples(dur)) > 0.92) * decay(dur, 0.14)
    return fade(mix(buzz, crackle * 1.4, break_()[: samples(dur)] * 0.4))


# The hero.

def jump():
    """A grunt of effort, kept small: you hear it a thousand times."""
    dur = 0.1
    huff = bandpass(noise(dur, seed=40), sweep(500.0, 900.0, dur), q=1.5) * adsr(dur, 0.005, 0.03, 0.3, 0.05)
    blip = osc("sine", sweep(240.0, 330.0, 0.06), 0.06) * decay(0.06, 0.02)
    return fade(mix(huff * 0.6, blip * 0.4))


def land():
    """Boots on stone."""
    dur = 0.1
    thud = osc("sine", sweep(130.0, 60.0, dur), dur) * decay(dur, 0.025)
    grit = lowpass(noise(0.05, seed=41), 1800.0) * decay(0.05, 0.012)
    return fade(mix(thud, grit * 0.5))


def flip():
    """A somersault's whoosh, softer than a sword's."""
    dur = 0.28
    air = bandpass(noise(dur, seed=42), sweep(400.0, 1100.0, dur), q=1.2)
    return fade(air * adsr(dur, 0.06, 0.08, 0.5, 0.12) * 0.7)


def die():
    """Insta-death: a hit, and the world dropping out from under it. Short,
    because the whole loop is under a second."""
    dur = 0.55
    hit = lowpass(noise(0.18, seed=43), 900.0) * decay(0.18, 0.05)
    drop = osc("saw", sweep(330.0, 55.0, dur), dur)
    drop = lowpass(drop, sweep(2400.0, 200.0, dur)) * decay(dur, 0.2)
    sub = osc("sine", sweep(90.0, 40.0, dur), dur) * decay(dur, 0.18)
    return fade(soft_clip(mix(hit * 1.2, drop * 0.6, sub * 0.9), 1.3))


def respawn():
    """Back at the brazier: a short warm swell."""
    dur = 0.4
    notes = [392.0, 587.33, 783.99]
    parts = []
    for i, f in enumerate(notes):
        tone = osc("tri", f, dur - i * 0.05) * adsr(dur - i * 0.05, 0.02, 0.1, 0.4, 0.15)
        parts.append(delayed(tone, i * 0.05))
    return fade(lowpass(mix(*parts), 3000.0) * 0.6)


# The room.

def brazier():
    """A brazier catching: a whoomph of air, then the crackle of the fire."""
    dur = 0.7
    cutoff = np.concatenate([sweep(200.0, 2200.0, 0.25), np.full(samples(dur) - samples(0.25), 2200.0)])
    whoomph = lowpass(noise(dur, seed=50), cutoff) * adsr(dur, 0.04, 0.15, 0.3, 0.4)
    rng = np.random.default_rng(51)
    pops = (rng.random(samples(dur)) > 0.996).astype(float) * rng.uniform(0.3, 1.0, samples(dur))
    crackle = bandpass(pops, 2500.0, q=0.7) * 1.2 * np.clip(time(dur) / 0.2, 0, 1)
    return fade(mix(whoomph * 2.0, crackle))


def chest():
    """A lid lifting, and swords chiming as they come out."""
    dur = 0.6
    creak_f = 140.0 + 30.0 * np.sin(2 * np.pi * 7.0 * time(0.22))
    creak = bandpass(osc("saw", creak_f, 0.22), 900.0, q=4.0) * adsr(0.22, 0.02, 0.05, 0.6, 0.08)
    chimes = []
    for i, f in enumerate([1318.5, 1567.98, 1975.53]):
        chimes.append(delayed(inharmonic(f, [1.0, 2.76, 5.4], 0.3, [0.12, 0.05, 0.02], seed=52 + i), 0.18 + i * 0.07))
    return fade(mix(creak * 0.7, *chimes))


def kill():
    """An enemy and a sword both gone: a crunch of shell and a short squeal."""
    crunch = bandpass(noise(0.12, seed=60), 1200.0, q=0.8) * decay(0.12, 0.035)
    squeal = osc("saw", sweep(900.0, 260.0, 0.22), 0.22)
    squeal = bandpass(squeal, 1400.0, q=2.0) * decay(0.22, 0.08)
    thump = osc("sine", sweep(160.0, 70.0, 0.1), 0.1) * decay(0.1, 0.03)
    return fade(mix(crunch * 1.1, delayed(squeal * 0.6, 0.02), thump))


def gem():
    """A gem picked up: a rising run of glass."""
    parts = []
    for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
        bell = fm(f, 3.5, 2.0, 0.5, index_env=decay(0.5, 0.08)) * decay(0.5, 0.18)
        parts.append(delayed(bell * (0.9 - 0.12 * i), i * 0.055))
    return fade(mix(*parts) * 0.7)


def gem_set():
    """A gem dropped into its holder: a deep bell, and current starting."""
    dur = 1.0
    bell = fm(392.0, 1.4, 3.0, dur, index_env=decay(dur, 0.2)) * decay(dur, 0.4)
    hum = osc("saw", 120.0, dur) * adsr(dur, 0.25, 0.2, 0.5, 0.4)
    hum = lowpass(hum, 700.0) * 0.3
    return fade(mix(bell, hum))


def switch():
    """A mechanism taking a sword: a solid clack."""
    dur = 0.18
    clack = inharmonic(780.0, [1.0, 1.7, 2.9], dur, [0.03, 0.02, 0.01], seed=70)
    knock = osc("sine", sweep(150.0, 80.0, 0.08), 0.08) * decay(0.08, 0.025)
    return fade(mix(clack * 0.8, knock))


def gate():
    """A portcullis grinding: chain rattle over a stone rumble."""
    dur = 0.9
    rumble = lowpass(noise(dur, seed=71), 260.0) * adsr(dur, 0.08, 0.2, 0.8, 0.3) * 2.0
    rng = np.random.default_rng(72)
    links = (rng.random(samples(dur)) > 0.997).astype(float)
    rattle = bandpass(links, 3200.0, q=3.0) * 14.0 * adsr(dur, 0.05, 0.2, 0.7, 0.3)
    clunk = delayed(osc("sine", sweep(110.0, 55.0, 0.2), 0.2) * decay(0.2, 0.06), dur - 0.2)
    return fade(mix(rumble, rattle, clunk))


def zap():
    """Current arriving somewhere: a short hard buzz."""
    dur = 0.2
    buzz = osc("pulse", 95.0, dur, width=0.15)
    buzz = highpass(buzz, 500.0) * decay(dur, 0.06)
    hiss = highpass(noise(dur, seed=73), 4000.0) * decay(dur, 0.04)
    return fade(soft_clip(mix(buzz, hiss * 0.6), 2.0))


def short():
    """The generator shorting out: a bang, a whine collapsing, sparks."""
    dur = 1.6
    bang = lowpass(noise(0.4, seed=74), 1200.0) * decay(0.4, 0.09) * 1.6
    whine = osc("saw", sweep(1600.0, 40.0, dur), dur)
    whine = lowpass(whine, sweep(5000.0, 300.0, dur)) * decay(dur, 0.5) * 0.5
    rng = np.random.default_rng(75)
    sparks = highpass(noise(dur, seed=76), 3000.0) * (rng.random(samples(dur)) > 0.97) * decay(dur, 0.6) * 1.5
    sub = osc("sine", sweep(70.0, 30.0, dur), dur) * decay(dur, 0.4)
    return fade(soft_clip(mix(bang, whine, sparks, sub), 1.4))


def geyser():
    """A jet going up: a hiss that swells and holds."""
    dur = 0.9
    steam = highpass(noise(dur, seed=77), sweep(600.0, 1800.0, dur))
    steam = lowpass(steam, 6000.0) * adsr(dur, 0.12, 0.2, 0.6, 0.4)
    gurgle = lowpass(noise(0.3, seed=78), 300.0) * decay(0.3, 0.1)
    return fade(mix(steam * 0.9, gurgle * 1.2))


def crumble():
    """A slab letting go: grit and a crack."""
    dur = 0.5
    crack = bandpass(noise(0.06, seed=79), 900.0, q=1.0) * decay(0.06, 0.015)
    grit = bandpass(noise(dur, seed=80), 1500.0, q=0.6) * adsr(dur, 0.01, 0.1, 0.4, 0.3)
    rng = np.random.default_rng(81)
    bits = lowpass((rng.random(samples(dur)) > 0.996).astype(float), 1500.0) * 10.0
    return fade(mix(crack * 1.2, grit * 0.5, bits))


def roar():
    """The dragon drawing breath and letting it go."""
    dur = 1.1
    growl_f = vibrato(sweep(70.0, 95.0, dur), dur, rate=11.0, depth=0.06)
    growl = osc("saw", growl_f, dur) + osc("saw", growl_f * 1.5, dur) * 0.5
    growl = lowpass(growl, sweep(400.0, 1400.0, dur)) * adsr(dur, 0.25, 0.2, 0.8, 0.3)
    fire = bandpass(noise(dur, seed=82), sweep(500.0, 1600.0, dur), q=0.7) * adsr(dur, 0.4, 0.2, 0.9, 0.3)
    return fade(soft_clip(mix(growl * 0.8, fire * 0.9), 1.5))


def bolt():
    """Volta casting: a rising charge and a crack."""
    dur = 0.45
    charge = osc("sine", sweep(300.0, 1800.0, 0.3), 0.3) * adsr(0.3, 0.2, 0.05, 0.8, 0.05) * 0.4
    crack = delayed(zap() * 1.2, 0.28)
    return fade(mix(charge, crack))


def pull():
    """Volta dragging every sword out of the walls: a deep suck of air."""
    dur = 0.9
    suck = bandpass(noise(dur, seed=83), sweep(2000.0, 200.0, dur), q=2.5)
    suck *= adsr(dur, 0.5, 0.1, 0.8, 0.25)
    groan = osc("saw", sweep(90.0, 60.0, dur), dur)
    groan = lowpass(groan, 500.0) * adsr(dur, 0.3, 0.2, 0.7, 0.3) * 0.5
    return fade(mix(suck * 1.2, groan))


def card():
    """An act ending: three low notes, the last held."""
    parts = []
    for i, (f, length) in enumerate([(146.83, 0.35), (174.61, 0.35), (220.0, 1.4)]):
        voice = osc("saw", f, length) + osc("saw", f * 1.005, length)
        voice = lowpass(voice, 1400.0) * adsr(length, 0.02, 0.1, 0.7, length * 0.4)
        parts.append(delayed(voice * 0.4, i * 0.3))
    return fade(mix(*parts))


RECIPES = {
    "sword_throw": throw,
    "sword_catch": catch,
    "sword_embed": embed,
    "sword_recall": recall,
    "sword_fly": fly_loop,
    "sword_break": break_,
    "sword_clatter": clatter,
    "sword_fry": fry,
    "hero_jump": jump,
    "hero_land": land,
    "hero_flip": flip,
    "hero_die": die,
    "hero_respawn": respawn,
    "brazier": brazier,
    "chest": chest,
    "kill": kill,
    "gem": gem,
    "gem_set": gem_set,
    "switch": switch,
    "gate": gate,
    "zap": zap,
    "short": short,
    "geyser": geyser,
    "crumble": crumble,
    "roar": roar,
    "bolt": bolt,
    "pull": pull,
    "card": card,
}
## The ones the engine loops rather than plays once.
LOOPS = {"sword_fly"}
## How loud each one peaks, so the mix is set where the sound is made: the
## ones heard a thousand times (a jump, a landing, the fly loop) sit low, the
## ones that end something (a death, a short) sit high.
LEVELS = {
    "sword_throw": 0.7, "sword_catch": 0.75, "sword_embed": 0.8, "sword_recall": 0.7,
    "sword_fly": 0.35, "sword_break": 0.8, "sword_clatter": 0.6, "sword_fry": 0.8,
    "hero_jump": 0.3, "hero_land": 0.4, "hero_flip": 0.3, "hero_die": 0.9,
    "hero_respawn": 0.45, "brazier": 0.7, "chest": 0.6, "kill": 0.8, "gem": 0.6,
    "gem_set": 0.75, "switch": 0.6, "gate": 0.65, "zap": 0.55, "short": 0.95,
    "geyser": 0.5, "crumble": 0.55, "roar": 0.85, "bolt": 0.7, "pull": 0.75, "card": 0.7,
}


# Ambience: beds that play under each act, and loops that sit on a thing in
# the room and are heard only near it. Every one loops without a seam: it is
# rendered long, and its tail is crossfaded into its head.

def _seamless(x, fade=0.5):
    """`x` with its last `fade` seconds folded over its first, equal power, so
    the end runs into the start without a step."""
    f = samples(fade)
    body = x[:-f].copy()
    t = np.linspace(0.0, 1.0, f)
    body[:f] = body[:f] * np.sin(t * np.pi / 2) + x[-f:] * np.cos(t * np.pi / 2)
    return body


def amb_wind():
    """Act 1: wind along the outer wall at night, gusting."""
    dur = 14.0
    t = time(dur)
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * t / 7.0) * np.sin(2 * np.pi * t / 3.1 + 1.0)
    air = noise(dur, seed=100)
    body = bandpass(air, 300.0 + 500.0 * gust, q=0.9) * (0.4 + 0.6 * gust)
    whistle = bandpass(noise(dur, seed=101), 1400.0 + 400.0 * gust, q=6.0) * gust * 0.25
    return _seamless(mix(body, whistle))


def amb_cavern():
    """Act 2: the mountain breathing, far off; the odd drip."""
    dur = 14.0
    t = time(dur)
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * t / 7.0)
    rumble = lowpass(noise(dur, seed=102), 90.0) * 4.0 * swell
    roar = lowpass(noise(dur, seed=103), 400.0) * 0.4 * swell
    drips = []
    rng = np.random.default_rng(104)
    for at in np.sort(rng.uniform(0.5, dur - 1.0, 6)):
        f = rng.uniform(900.0, 1500.0)
        drip = osc("sine", sweep(f, f * 1.6, 0.05), 0.05) * decay(0.05, 0.015)
        drips.append(delayed(drip * 0.3, float(at)))
    return _seamless(pad_to(mix(rumble, roar, *drips), dur))


def amb_works():
    """Act 3: the generator's works, humming; a machine knocking far away."""
    dur = 12.0
    hum = sum(osc("sine", 60.0 * k, dur) * (0.5 / k) for k in (1, 2, 3, 5))
    beat = 1.0 + 0.15 * np.sin(2 * np.pi * time(dur) * 0.5)
    hum = hum * beat * 0.5
    buzz = bandpass(osc("saw", 120.0, dur), 2000.0, q=2.0) * 0.06
    knocks = []
    for i in range(int(dur / 1.5)):
        knock = inharmonic(180.0, [1.0, 2.3, 3.9], 0.4, [0.12, 0.06, 0.03], seed=110 + i)
        knocks.append(delayed(lowpass(knock, 900.0) * 0.25, i * 1.5))
    return _seamless(pad_to(mix(hum, buzz, *knocks), dur))


def amb_hall():
    """Act 4: rain on the high windows, and thunder once, a long way off."""
    dur = 16.0
    rain = highpass(noise(dur, seed=120), 1800.0)
    rain = lowpass(rain, 7000.0) * 0.35
    rng = np.random.default_rng(121)
    drops = (rng.random(samples(dur)) > 0.9985).astype(float) * rng.uniform(0.2, 1.0, samples(dur))
    drops = bandpass(drops, 3500.0, q=1.5) * 0.8
    thunder = lowpass(noise(5.0, seed=122), sweep(500.0, 80.0, 5.0)) * adsr(5.0, 0.4, 1.0, 0.5, 3.0) * 2.2
    return _seamless(pad_to(mix(rain, drops, delayed(thunder, 6.0)), dur))


def loop_lava():
    """On a lava pit: a low roar and bubbles breaking."""
    dur = 7.0
    roar = lowpass(noise(dur, seed=130), 160.0) * 2.5
    bloops = []
    rng = np.random.default_rng(131)
    for at in np.sort(rng.uniform(0.0, dur - 0.5, 14)):
        f = rng.uniform(70.0, 160.0)
        bloop = osc("sine", sweep(f, f * 2.2, 0.12), 0.12) * decay(0.12, 0.04)
        bloops.append(delayed(lowpass(bloop, 800.0) * rng.uniform(0.4, 0.9), float(at)))
    return _seamless(pad_to(mix(roar, *bloops), dur), fade=0.3)


def loop_arc():
    """On an arc or live copper: a hard buzz, crackling."""
    dur = 3.0
    buzz = osc("pulse", 120.0, dur, width=0.2)
    buzz = bandpass(buzz, 1600.0, q=1.2) * 0.35
    rng = np.random.default_rng(132)
    crackle = highpass(noise(dur, seed=133), 3000.0) * (rng.random(samples(dur)) > 0.985) * 1.4
    return _seamless(mix(buzz, crackle), fade=0.2)


RECIPES.update({
    "amb_wind": amb_wind,
    "amb_cavern": amb_cavern,
    "amb_works": amb_works,
    "amb_hall": amb_hall,
    "loop_lava": loop_lava,
    "loop_arc": loop_arc,
})
LOOPS.update({"amb_wind", "amb_cavern", "amb_works", "amb_hall", "loop_lava", "loop_arc"})
LEVELS.update({
    "amb_wind": 0.5, "amb_cavern": 0.6, "amb_works": 0.5, "amb_hall": 0.55,
    "loop_lava": 0.6, "loop_arc": 0.45,
})
## The beds are long, so they are written as Ogg rather than WAV; the code
## that plays them sets them looping (`Audio.looping`).
BEDS = {"amb_wind", "amb_cavern", "amb_works", "amb_hall"}
