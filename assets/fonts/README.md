# Fonts

`Jersey10-Regular.ttf` is the game's one typeface, for every word a player
reads (`ART_DIRECTION.md`, *Lettering*). It is Jersey 10 by Sarah Cadigan-Fried
(The Soft Type Project), from the Google Fonts repository, under the SIL Open
Font License 1.1 (`OFL.txt`, which travels with it).

It is drawn on a 10 px grid, so it is only ever set at 10, 20 or 40 px and
with smoothing off. `scripts/lettering.gd` does both, in code rather than in
the font's `.import` file, which is gitignored.
