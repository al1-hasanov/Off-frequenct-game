# v0.6.2 validation

Godot 4.6.3. The whole suite was run again on 13 November 2026, in a fresh workspace, after the last changes (the ? button's pointers to the optional clues, and the parallel-universes wording). Every run below passed.

| Run | Result |
|---|---|
| `--check` | every room script compiles |
| `--autotest=answer` (opening to the end of Act 3) | PASS, 215 checks |
| `--autotest=cut` | PASS, 220 checks |
| `--autotest=answer_leave` | PASS, 218 checks |
| `--autotest=cut_take` | PASS, 217 checks |
| `--autotest=act3_answer`, `act3_cut`, `act3_answer_leave`, `act3_cut_take` (Act 3 from chapter 3.1) | PASS, 71 checks each |
| `--autotest=chapters` | PASS, 302 checks |
| `--autotest=layout` | PASS, 152 checks |
| `--autotest=continue` | PASS, 31 checks |
| `--autotest=atmosphere` | PASS, 30 checks |
| `--autotest=act3_answer --shots` | every new clue on screen at 1280x720 (OpenGL under Xvfb); the art hasn't changed since these were taken |

Every Act 3 playthrough now also:

- taps the old chalk on the control-room board (the Λ), Dad's *Gravitation* on Sollen's shelf (his LAMBDA notes), the lettering on the 2031 museum wall (the 1917–2025 panel), the papers on Tomas's hut door in 2009, and the photocopy on Tomas's pegboard in 1991, and checks each one's notebook note;
- checks that the ? button names each optional clue while it's unread (the old chalk, the textbook, the papers on Tomas's door, the photocopy) and drops it once it's read;
- connects the four new theories as soon as both halves are known (dark energy, other us, the small Big Rip, the way through), checks they last to the end, and that there are twelve to find;
- checks that the Tuner's description has the lid's LIGHT = BALLAST after Tomas's notebook;
- asks the ? button at every step of Red's dark: Listen in the basement, then turning 1 (ahead), turning 2 (on the left) and turning 3 (on the right, June's voice);
- checks that looking at the museum wall doesn't bring 2:14 PM early: only the four exhibits Mara needs do that.

The engine prints "Lambda capture at index 0 was freed" during Act 3 room changes. It did so the same number of times in v0.6.0 (51 per Act 3 run), so it isn't new, and it doesn't affect play.

Science on the new pages was checked against sources: NASA (1998 discovery, about 68% of the universe), the DESI release of March 2025 (nearly 15 million galaxies and quasars; hints that dark energy is weakening), González-Díaz 2003 and Faraoni and Israel 2005 (phantom energy and wormholes), Caldwell, Kamionkowski and Weinberg 2003 (the Big Rip), Morris, Thorne and Yurtsever, *Physical Review Letters* 61, 1446 (26 September 1988), Einstein's 1949 reply to Gödel, and Okun on Zel'dovich's 1967 vacuum energy.
