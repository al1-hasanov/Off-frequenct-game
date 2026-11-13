# v0.6.1 validation

Godot 4.6.3. Every run below passed.

| Run | Checks |
|---|---|
| `--autotest=answer` (opening to the end of Act 3) | 189 |
| `--autotest=cut` | 194 |
| `--autotest=answer_leave` | 192 |
| `--autotest=cut_take` | 191 |
| `--autotest=chapters` | 302 |
| `--autotest=layout` | 150 |
| `--autotest=continue` | 31 |
| `--autotest=eras --shots` | every Act 3 place in its year, rendered at 1280x720 (OpenGL under Xvfb) |
| `--check` | every room script compiles |

The playthroughs walk Mara through every rescaled place: out to the dish and back in each year, round the 2009 lot to the lamp line, the hut and the coal chute, and along Main Street in 1991 to his car or their van. (`cut` and `cut_take` were run one at a time: run four at once on this machine, the opening's "the film can be skipped" check sometimes fires before the Skip button has appeared. That check is about timing under load, not the game.)

Scale: people are 168 to 196 px tall (1.53 to 1.78 m), about 110 px to the metre. Vehicles are drawn at 100 px to the metre a metre back in the lot (scale 1.0), at 1.12 at the kerb in front of the sidewalk, and smaller further back (0.85, 0.8, 0.73). Doors are 230 to 246 px (2.1 to 2.25 m); desks 0.75 m; the workbench 0.9 m.
