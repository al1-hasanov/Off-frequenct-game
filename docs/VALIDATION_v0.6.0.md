# v0.6.0 validation

Godot 4.6.3, headless unless noted. Every run below passed.

## Playthroughs (opening to the end of Act 3)

| Run | What it chooses | Checks |
|---|---|---|
| `--autotest=answer` | answer the voice, take Tomas; in 1991 bless his life; Choice 3: pull the cable | 189 |
| `--autotest=cut` | cut the power, leave Tomas; ask him to come; refuse and show Eighty-One the notebook; one trip into the feed cabin with nothing on the needle (+2 FRACTURE) | 194 |
| `--autotest=answer_leave` | answer, leave Tomas; bless; refuse and grab the revolver | 192 |
| `--autotest=cut_take` | cut, take Tomas; ask; grab the revolver | 191 |
| `--autotest=act3_cut_take` | Act 3 alone, from chapter 3.1's recorded state | 45 |

Act 3 checks include: the batteries warmed on the boiler; Dad's diagram from Sollen's log; a wrong jack, then the 2.14 chain; each trip through the feed cabin is a crossing and never FRACTURE; Cal's tape and the copy; the four exhibits (in a different order in each half); the Silence at 2:14 PM and the cassette fading on the way back; the notebook connections *not_hers* and *dad_whistle*; the desk leg waiting for the chalkboard; 2009 appearing on the board; the count at the lamp line; Tomas at forty; following his lamp to the tin; the fire axe and the wet plaster; the experiment (two required crossings there and back with the dish parked, no FRACTURE), both strips and the *listening* theory; Tomas's call and 1991 on the board; the right Tomas in 1991 for each Choice 2 (21 with June, 24 with Lise); the street and the car; holding the light; the roll call and LETGO; Red's red tape and empty pockets; a wrong sound walking her back round; the whistle; a spark, then fat to fat; Red's call and Blue's pockets back; TONIGHT, station twenty-three and Choice 3 with its consequences (the revolver handed over; the forward bank burst and no more futures).

## Other runs

| Run | Result |
|---|---|
| `--autotest=chapters` | 302 checks: every chapter (now 25, with 3.1 to 3.8) opens in the right room, on the right frequency, with the right choices, settles, and has a hint |
| `--autotest=continue` | 31 checks |
| `--autotest=atmosphere` | 30 checks |
| `--autotest=layout` | 150 checks: no wall decoration on anything tappable (the new fire-axe case and the control room's patch bay, chart recorder and drive panel included) |
| `--autotest=eras --shots` | every Act 3 place in its year, rendered (1280x720, OpenGL under Xvfb) |
| `--autotest=act3_answer --shots`, `act3_cut --shots` | 122 and 129 screenshots of Act 3, every key line and moment (the Silence, the coupling, the wrist close-ups, the white in the window, the end card) |
| `--check` | every room script compiles |

## Frame cost of the new places

`--autotest=perf`, CPU side (headless): average script and drawing time per frame. The new rooms cost the same as the old ones because their pictures are drawn once and kept.

| Room | avg ms | slowest ms |
|---|---|---|
| dish (1983) | 0.10 | 2.02 (first frame) |
| visitor_center | 0.02 | 0.02 |
| basement_2009 | 0.02 | 0.05 |
| main_street_1991 | 0.15 | 0.20 |
| shop_1991 | 0.04 | 0.10 |

Draw calls (OpenGL under Xvfb): on frames where nobody is redrawn the new rooms need 20 to 40 (the HUD is 18); a frame that redraws a standing character adds about 220 for that character, a dozen times a second for Mara and six for everyone else, as in v0.5.2. The dish room peaks at 246, the shop at 25, Main Street 1991 at 282.

## Not tested here

On a physical phone. Install over v0.5.2 and use Chapters (debug) → Act 3 to jump straight to any part.
